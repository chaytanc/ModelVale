// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
//

const functions = require("firebase-functions");
// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

exports.decreaseHealth = functions.pubsub.schedule('every 2 hours').timeZone('America/Ensenada').onRun(async(context) => {
  console.log('This will be run every two hours!');
	// get every document under models
	const models = await admin.firestore().collection('Model').get();
	const batch = admin.firestore().batch();
	// decrease health by one for each one
	// write the result back to the model document
	models.forEach(doc => {
		let health = doc.data().health;
		health -= 1;
		console.log('Data: ', doc.data());
		console.log('Health: ', doc.data().health);
		batch.update(doc.ref, 'health', health);
	});
	await batch.commit();
	return null;
});
