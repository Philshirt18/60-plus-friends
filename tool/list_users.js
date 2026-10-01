const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });
const auth = getAuth();
const db = getFirestore();

async function run() {
  const list = await auth.listUsers(1000);
  console.log(`\n${list.users.length} Auth users:\n`);
  for (const u of list.users) {
    const doc = await db.collection('users').doc(u.uid).get();
    const firstName = doc.exists ? doc.data().firstName : '(no Firestore profile)';
    console.log(`${u.uid}  ${u.email || '(no email)'}  createdAt=${u.metadata.creationTime}  name=${firstName}`);
  }
  process.exit(0);
}

run().catch((e) => { console.error(e); process.exit(1); });
