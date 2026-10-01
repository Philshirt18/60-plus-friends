// Fully deletes a real test account: Auth user, Firestore profile, blocks
// subcollection, interest expressions / passes either direction, matches
// (+ their conversations + messages), and removes them from any activity's
// participantIds (or deletes activities they created).

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });
const auth = getAuth();
const db = getFirestore();

const UID = process.argv[2];
if (!UID) {
  console.error('usage: node delete_account.js <uid>');
  process.exit(1);
}

async function deleteCollection(query) {
  const snap = await query.get();
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  if (!snap.empty) await batch.commit();
  return snap.docs.length;
}

async function run() {
  console.log(`Deleting account ${UID}...`);

  // Blocks subcollection under the user's own profile.
  const blocksDeleted = await deleteCollection(
    db.collection('users').doc(UID).collection('blocks')
  );
  console.log('  blocks removed:', blocksDeleted);

  // Interest expressions and passes, either direction.
  const expFrom = await deleteCollection(
    db.collection('interestExpressions').where('from', '==', UID)
  );
  const expTo = await deleteCollection(
    db.collection('interestExpressions').where('to', '==', UID)
  );
  const passFrom = await deleteCollection(
    db.collection('passes').where('from', '==', UID)
  );
  const passTo = await deleteCollection(
    db.collection('passes').where('to', '==', UID)
  );
  console.log('  expressions removed:', expFrom + expTo, ' passes removed:', passFrom + passTo);

  // Matches involving this user, plus their conversations + messages.
  const matchSnap = await db.collection('matches').where('users', 'array-contains', UID).get();
  for (const m of matchSnap.docs) {
    const convoSnap = await db.collection('conversations').where('matchId', '==', m.id).get();
    for (const c of convoSnap.docs) {
      const msgSnap = await c.ref.collection('messages').get();
      const batch = db.batch();
      msgSnap.docs.forEach((msg) => batch.delete(msg.ref));
      batch.delete(c.ref);
      if (!msgSnap.empty || true) await batch.commit();
    }
    await m.ref.delete();
  }
  console.log('  matches removed:', matchSnap.docs.length);

  // Activities: delete ones they created, remove them from others' participantIds.
  const createdSnap = await db.collection('activities').where('creatorId', '==', UID).get();
  for (const a of createdSnap.docs) await a.ref.delete();
  console.log('  activities deleted (as creator):', createdSnap.docs.length);

  const participantSnap = await db.collection('activities').where('participantIds', 'array-contains', UID).get();
  for (const a of participantSnap.docs) {
    await a.ref.update({ participantIds: FieldValue.arrayRemove(UID) });
  }
  console.log('  removed from activities as participant:', participantSnap.docs.length);

  // The user's own profile document.
  await db.collection('users').doc(UID).delete();
  console.log('  Firestore profile deleted.');

  // The Auth account itself.
  await auth.deleteUser(UID);
  console.log('  Auth user deleted.');

  console.log('DONE.');
  process.exit(0);
}

run().catch((e) => { console.error(e); process.exit(1); });
