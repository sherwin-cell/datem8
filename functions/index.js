const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

// 🔁 Automatically sync friends when a request is accepted
exports.syncFriends = onDocumentCreated(
    "friendRequests/{userId}/received/{fromUserId}",
    async (event) => {
        const { userId, fromUserId } = event.params;
        const db = admin.firestore();

        await Promise.all([
            db
                .collection("friends")
                .doc(userId)
                .set({ [fromUserId]: true }, { merge: true }),
            db
                .collection("friends")
                .doc(fromUserId)
                .set({ [userId]: true }, { merge: true }),
        ]);

        console.log(`Synced friendship between ${userId} and ${fromUserId}`);
    },
);
