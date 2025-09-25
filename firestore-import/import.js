const admin = require("firebase-admin");
const fs = require("fs");

// โหลด service account key
const serviceAccount = require("./serviceAccountKey.json");

// เริ่มต้น Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importData() {
  const places = JSON.parse(fs.readFileSync("places_seed.json", "utf8"));
  const batch = db.batch();

  places.forEach(place => {
    const ref = db.collection("places").doc(place.id);
    batch.set(ref, place);
  });

  await batch.commit();
  console.log("✅ Import data สำเร็จ!");
}

importData().catch(console.error);
