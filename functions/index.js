const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.healthCheck = onRequest((req, res) => {
  res.json({ status: "ok" });
});
