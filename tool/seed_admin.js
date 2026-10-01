// Reliable server-side seeder using the Firebase Admin SDK — runs on your Mac,
// no device/emulator needed, and bypasses client security rules.
//
// Setup (one time):
//   1. Firebase console -> Project settings -> Service accounts ->
//      "Generate new private key" -> save as tool/service-account.json
//   2. cd tool && npm init -y && npm install firebase-admin
//   3. node seed_admin.js
//
// Safe to run repeatedly (uses fixed seed_* document ids).

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

function nextWeekday(weekday, hour, minute) {
  const now = new Date();
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute);
  // JS: 0=Sun..6=Sat. weekday passed in same convention.
  while (d.getDay() !== weekday || d < now) d.setDate(d.getDate() + 1);
  return d;
}

const people = [
  { id: 'seed_maria', firstName: 'Maria', ageRange: 'a65to69', country: 'Spain', city: 'Málaga', approximateArea: 'Torre del Mar',
    profilePhotoUrl: 'asset://assets/images/maria.png',
    bio: "I enjoy long walks, classical music and discovering new places. I'd love to meet people nearby for coffee or a walk.",
    interests: ['walking', 'travel', 'music', 'coffee'], lookingFor: ['friendship', 'activities'], hideExactLocation: true },
  { id: 'seed_john', firstName: 'John', ageRange: 'a70to74', country: 'Spain', city: 'Málaga', approximateArea: 'Nerja',
    profilePhotoUrl: 'asset://assets/images/john.png',
    bio: 'Retired teacher, keen on history, books and a good game of cards. Always up for a friendly chat over coffee.',
    interests: ['history', 'books', 'games', 'coffee'], lookingFor: ['conversation', 'hobbyPartners'], hideExactLocation: true },
  { id: 'seed_carmen', firstName: 'Carmen', ageRange: 'a60to64', country: 'Spain', city: 'Vélez-Málaga', approximateArea: 'Vélez-Málaga',
    profilePhotoUrl: 'asset://assets/images/carmen.png',
    bio: 'Love gardening, painting and swimming. Looking for friendly people to share hobbies and sunny mornings with.',
    interests: ['gardening', 'painting', 'swimming', 'walking'], lookingFor: ['hobbyPartners', 'localCommunity'], hideExactLocation: true },
  { id: 'seed_peter', firstName: 'Peter', ageRange: 'a75to79', country: 'Spain', city: 'Málaga', approximateArea: 'Málaga centre',
    profilePhotoUrl: 'asset://assets/images/peter.png',
    bio: 'Photography enthusiast and slow traveller. Would enjoy company for museum visits and seaside strolls.',
    interests: ['photography', 'travel', 'walking', 'history'], lookingFor: ['travelCompanions', 'friendship'], hideExactLocation: true },
  { id: 'seed_anne', firstName: 'Anne', ageRange: 'a65to69', country: 'Spain', city: 'Málaga', approximateArea: 'Torre del Mar',
    profilePhotoUrl: 'asset://assets/images/anne.png',
    bio: 'Yoga most mornings, cooking most evenings. Happy to meet people for a walk, a coffee or a shared meal.',
    interests: ['yoga', 'cooking', 'coffee', 'walking'], lookingFor: ['friendship', 'localCommunity'], hideExactLocation: true },
  { id: 'seed_david', firstName: 'David', ageRange: 'a70to74', country: 'Spain', city: 'Nerja', approximateArea: 'Nerja',
    profilePhotoUrl: 'asset://assets/images/david.png',
    bio: 'Cyclist and amateur guitarist. Looking for hobby partners and people who enjoy the outdoors.',
    interests: ['cycling', 'music', 'hiking', 'beach'], lookingFor: ['hobbyPartners', 'activities'], hideExactLocation: true },
];

const activities = [
  { id: 'seed_act_walk', creatorId: 'seed_maria', title: 'Sunday Morning Walk',
    description: "I'm going for a relaxed walk along the promenade and would be happy to have some company.",
    category: 'Walking · Outdoors', dateTime: nextWeekday(0, 10, 30), approximateLocation: 'Torre del Mar',
    maxParticipants: 8, interestIds: ['walking', 'beach'], participantIds: ['seed_maria', 'seed_anne', 'seed_peter', 'seed_carmen'],
    photoUrl: 'asset://assets/images/activity_walk.png' },
  { id: 'seed_act_coffee', creatorId: 'seed_john', title: 'Coffee and conversation',
    description: 'A friendly get-together over coffee. All welcome, come and say hello.',
    category: 'Conversation · Coffee', dateTime: nextWeekday(4, 16, 0), approximateLocation: 'Torre del Mar',
    maxParticipants: 6, interestIds: ['coffee', 'conversation'], participantIds: ['seed_john', 'seed_anne'],
    photoUrl: 'asset://assets/images/activity_coffee.png' },
  { id: 'seed_act_cards', creatorId: 'seed_carmen', title: 'Afternoon card games',
    description: 'Casual card games and good conversation. Beginners very welcome.',
    category: 'Games · Social', dateTime: nextWeekday(2, 17, 30), approximateLocation: 'Vélez-Málaga',
    maxParticipants: 4, interestIds: ['games', 'conversation'], participantIds: ['seed_carmen'],
    photoUrl: 'asset://assets/images/activity_cards.png' },
  { id: 'seed_act_photo', creatorId: 'seed_peter', title: 'Old town photo stroll',
    description: 'A gentle walk through the old town taking photos. Any camera or phone is fine.',
    category: 'Photography · Walking', dateTime: nextWeekday(6, 11, 0), approximateLocation: 'Málaga centre',
    maxParticipants: 6, interestIds: ['photography', 'walking', 'history'], participantIds: ['seed_peter', 'seed_david'],
    photoUrl: 'asset://assets/images/activity_photo.png' },
];

async function run() {
  for (const p of people) {
    const { id, ...data } = p;
    data.createdAt = new Date().toISOString();
    await db.collection('users').doc(id).set(data);
    console.log('seeded user', id);
  }
  for (const a of activities) {
    const { id, ...data } = a;
    data.dateTime = Timestamp.fromDate(data.dateTime);
    data.createdAt = FieldValue.serverTimestamp();
    await db.collection('activities').doc(id).set(data);
    console.log('seeded activity', id);
  }
  console.log('DONE seeding Firestore.');
  process.exit(0);
}

run().catch((e) => { console.error(e); process.exit(1); });
