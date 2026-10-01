// Seeds one real match + a short conversation between a real account and a
// seed persona, purely so the demo video can open an existing chat instead
// of faking a live mutual match. Safe to run once; re-running would create
// duplicate match/conversation docs, so this checks for an existing match
// between the two users first.

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const ME = process.argv[2];
const OTHER = process.argv[3] || 'seed_david';

async function run() {
  const [meSnap, otherSnap] = await Promise.all([
    db.collection('users').doc(ME).get(),
    db.collection('users').doc(OTHER).get(),
  ]);
  if (!meSnap.exists) throw new Error(`users/${ME} not found`);
  if (!otherSnap.exists) throw new Error(`users/${OTHER} not found`);

  const myInterests = meSnap.data().interests || [];
  const otherInterests = otherSnap.data().interests || [];
  const shared = myInterests.filter((i) => otherInterests.includes(i));

  const existing = await db
    .collection('matches')
    .where('users', 'array-contains', ME)
    .get();
  const already = existing.docs.find((d) => d.data().users.includes(OTHER));

  let matchId;
  if (already) {
    matchId = already.id;
    console.log('match already exists:', matchId);
  } else {
    const matchRef = db.collection('matches').doc();
    await matchRef.set({
      users: [ME, OTHER],
      userA: ME,
      userB: OTHER,
      sharedInterestIds: shared,
      createdAt: FieldValue.serverTimestamp(),
    });
    matchId = matchRef.id;
    console.log('created match:', matchId, 'shared interests:', shared);
  }

  const existingConvo = await db
    .collection('conversations')
    .where('matchId', '==', matchId)
    .limit(1)
    .get();

  let convoRef;
  if (!existingConvo.empty) {
    convoRef = existingConvo.docs[0].ref;
    console.log('conversation already exists:', convoRef.id);
  } else {
    convoRef = db.collection('conversations').doc();
    const now = Date.now();
    const messages = [
      { senderId: OTHER, text: "Hi! I saw we're both into cycling and the outdoors 🚴 Would you like to join a ride sometime?", minutesAgo: 60 },
      { senderId: ME, text: `Hi ${otherSnap.data().firstName}! That sounds great, I'd love to.`, minutesAgo: 55 },
      { senderId: OTHER, text: "Awesome, I'm organizing a coastal ride this weekend if you're free.", minutesAgo: 40 },
      { senderId: ME, text: 'Count me in!', minutesAgo: 35 },
    ];

    await convoRef.set({
      matchId,
      participantIds: [ME, OTHER],
      lastMessage: messages[messages.length - 1].text,
      updatedAt: Timestamp.fromMillis(now - messages[messages.length - 1].minutesAgo * 60000),
      unread: { [ME]: 0, [OTHER]: 0 },
    });

    for (const m of messages) {
      const msgRef = convoRef.collection('messages').doc();
      await msgRef.set({
        senderId: m.senderId,
        text: m.text,
        createdAt: Timestamp.fromMillis(now - m.minutesAgo * 60000),
        readBy: [ME, OTHER],
      });
    }
    console.log('created conversation with', messages.length, 'messages:', convoRef.id);
  }

  console.log('DONE.');
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
