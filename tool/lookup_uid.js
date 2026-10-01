const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const serviceAccount = require('./service-account.json');

initializeApp({ credential: cert(serviceAccount) });

const email = process.argv[2];

getAuth()
  .getUserByEmail(email)
  .then((user) => {
    console.log('UID:', user.uid);
    process.exit(0);
  })
  .catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
