const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifyUsersOnNewIssue = onDocumentCreated("issues/{issueId}", async (event) => {
  const newIssue = event.data.data();
  const title = newIssue.title || "New Bus Issue";
  const message = newIssue.description || "Check the app for details.";

  const db = getFirestore();
  const usersSnapshot = await db.collection("users").get();

  const tokens = [];
  usersSnapshot.forEach(doc => {
    const data = doc.data();
    if (data.fcmToken) {
      tokens.push(data.fcmToken);
    }
  });

  if (tokens.length === 0) {
    console.log("No FCM tokens found.");
    return;
  }

  const payload = {
    notification: {
      title: `⚠️ ${title}`,
      body: message,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      screen: "ReportIssueScreen",
    }
  };

  await getMessaging().sendToDevice(tokens, payload);
});
