const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.syncFriends = onDocumentCreated(
    "friendRequests/{userId}/received/{fromUserId}",
    async (event) => {
        try {
            const {userId, fromUserId} = event.params;

            const requestRef = admin
                .firestore()
                .collection("friendRequests")
                .doc(userId)
                .collection("received")
                .doc(fromUserId);

            const requestSnap = await requestRef.get();
            if (!requestSnap.exists) {
                return;
            }

            const requestData = requestSnap.data();
            if (!requestData || !requestData.confirmed) {
                return;
            }

            const friendsRef = admin.firestore().collection("friends");

            await friendsRef
                .doc(userId)
                .set({[fromUserId]: true}, {merge: true});
            await friendsRef
                .doc(fromUserId)
                .set({[userId]: true}, {merge: true});

            console.log(`Synced friends: ${userId} ↔ ${fromUserId}`);
        } catch (err) {
            console.error("Error syncing friends:", err);
        }
    }
);
