const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const UID = process.argv[2];

async function run() {
  const doc = await db.collection('users').doc(UID).get();
  if (!doc.exists) {
    console.log('NO PROFILE DOCUMENT EXISTS for', UID);
  } else {
    console.log('Profile exists:');
    console.log(JSON.stringify(doc.data(), null, 2));
  }
  process.exit(0);
}

run().catch((e) => { console.error(e); process.exit(1); });
