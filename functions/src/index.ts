import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

interface GroupData {
  id: string;
  memberIds: string[];
  [key: string]: any;
}

// [FIXED] Handles matching logic with transaction safety to prevent "alone" groups
export const handleGroupUpdate = functions.firestore
  .document("groups/{groupId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const groupId = context.params.groupId;

    // Trigger only when status changes to "matching"
    if (beforeData.status !== "matching" && afterData.status === "matching") {
      console.log(`Group ${groupId} started matching. Looking for a pair.`);

      // Find other groups that are also matching
      const matchingGroupsQuery = db.collection("groups")
        .where("status", "==", "matching")
        .where(admin.firestore.FieldPath.documentId(), "!=", groupId);

      const querySnapshot = await matchingGroupsQuery.get();

      if (querySnapshot.empty) {
        console.log("No other groups are currently matching.");
        return;
      }

      // Logic to find a candidate with the same member count
      let matchedCandidate: GroupData | null = null;
      for (const doc of querySnapshot.docs) {
          const groupData = doc.data();
          if (groupData.memberIds.length === afterData.memberIds.length) {
            matchedCandidate = { id: doc.id, ...groupData } as GroupData;
            break;
          }
      }

      if (matchedCandidate) {
        console.log(`Attempting to match: ${groupId} and ${matchedCandidate.id}`);
        const group1Ref = db.collection("groups").doc(groupId);
        const group2Ref = db.collection("groups").doc(matchedCandidate.id);

        try {
          await db.runTransaction(async (transaction) => {
            // [CRITICAL FIX] Read both documents INSIDE the transaction
            const group1Doc = await transaction.get(group1Ref);
            const group2Doc = await transaction.get(group2Ref);

            if (!group1Doc.exists || !group2Doc.exists) {
              throw new Error("One of the groups does not exist.");
            }

            const g1Data = group1Doc.data();
            const g2Data = group2Doc.data();

            // Check if BOTH are still strictly in 'matching' status
            if (g1Data?.status !== "matching") {
              throw new Error(`Self group ${groupId} is no longer matching.`);
            }
            if (g2Data?.status !== "matching") {
              throw new Error(`Target group ${matchedCandidate!.id} is no longer available.`);
            }

            // Perform the update only if validation passes
            transaction.update(group1Ref, {
                status: "matched",
                matchedGroupId: matchedCandidate!.id
            });
            transaction.update(group2Ref, {
               status: "matched",
               matchedGroupId: groupId
            });
          });
          console.log(`Successfully matched ${groupId} with ${matchedCandidate.id}`);
        } catch (e) {
          console.log(`Transaction failed (race condition handled): ${e}`);
          // If transaction fails, this execution stops safely.
          // The 3rd group will remain in 'matching' status and wait for a 4th group.
        }
      } else {
        console.log("Found other matching groups, but none were compatible.");
      }
    }
  });

// [PRESERVED] Handles chatroom creation after a match is confirmed
export const handleMatchingCompletion = functions.firestore
  .document("groups/{groupId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const groupId = context.params.groupId;

    if (beforeData.status !== "matched" && afterData.status === "matched") {
      const matchedGroupId = afterData.matchedGroupId;
      if (!matchedGroupId) {
        console.log("Matched group ID is missing.");
        return;
      }

      // To prevent double execution (once for each group), only the group with the "higher" ID runs this
      if (groupId > matchedGroupId) {
          console.log(`Group ${groupId} deferring to ${matchedGroupId} to handle completion.`);
          return;
      }

      console.log(`Handling matching completion for ${groupId} and ${matchedGroupId}`);
      const newChatRoomId = `${groupId}_${matchedGroupId}`;

      await db.runTransaction(async (transaction) => {
        const newChatRoomRef = db.collection("chatrooms").doc(newChatRoomId);
        const chatRoomDoc = await transaction.get(newChatRoomRef);

        if (chatRoomDoc.exists) {
          console.log(`Chatroom ${newChatRoomId} already exists. Skipping creation.`);
          return;
        }

        const group1Ref = db.collection("groups").doc(groupId);
        const group2Ref = db.collection("groups").doc(matchedGroupId);
        const group1Doc = await transaction.get(group1Ref);
        const group2Doc = await transaction.get(group2Ref);

        if (!group1Doc.exists || !group2Doc.exists) {
          throw new Error("One or both groups in the match do not exist.");
        }

        const group1Data = group1Doc.data();
        const group2Data = group2Doc.data();

        if (!group1Data || !group2Data) {
            throw new Error("Group data is undefined.");
        }

        const allMemberIds = [...new Set([...group1Data.memberIds, ...group2Data.memberIds])];

        transaction.set(newChatRoomRef, {
          groupId: newChatRoomId,
          participants: allMemberIds,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        for (const memberId of allMemberIds) {
          const userRef = db.collection("users").doc(memberId);
          transaction.update(userRef, { currentGroupId: newChatRoomId });
        }

        // Clean up the old group documents
        transaction.delete(group1Ref);
        transaction.delete(group2Ref);
      });
    }
  });