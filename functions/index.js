const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a role request document is updated.
 * Enforces Separation of Duties and assigns Firebase Auth Custom Claims.
 */
exports.handleRoleRequestApproval = functions.firestore
  .document("role_requests/{requestId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Only process when status transitions to 'approved'
    if (beforeData.status !== "approved" && afterData.status === "approved") {
      const { requesterUid, requestedRole, reviewedBy } = afterData;

      // 1. Server-side Separation of Duties check
      if (requesterUid === reviewedBy) {
        console.error(`Security Violation: User ${reviewedBy} attempted to approve their own role request!`);
        return change.after.ref.update({
          status: "rejected",
          rejectionReason: "Separation of Duties violation: Self-approval not permitted.",
        });
      }

      try {
        // 2. Set Custom User Claims on Firebase Auth
        await admin.auth().setCustomUserClaims(requesterUid, {
          role: requestedRole,
        });

        // 3. Update the user document in Firestore
        await admin.firestore().collection("users").doc(requesterUid).update({
          role: requestedRole,
        });

        // 4. Create an immutable Audit Log entry
        await admin.firestore().collection("audit_logs").add({
          eventType: "ROLE_CHANGE_APPROVED",
          targetUid: requesterUid,
          assignedRole: requestedRole,
          approvedBy: reviewedBy,
          requestId: context.params.requestId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Successfully granted ${requestedRole} claim to user ${requesterUid} by admin ${reviewedBy}`);
      } catch (error) {
        console.error(`Failed to assign role ${requestedRole} to ${requesterUid}:`, error);
      }
    }
  });

  /**
 * Automated quarterly review to flag inactive privileged accounts.
 * Privileged roles: SubcityModerator, SecurityAuditor, SystemAdmin.
 * Runs on the 1st of every 3rd month at midnight.
 */
exports.quarterlyStaleAccessReview = functions.pubsub
  .schedule("0 0 1 */3 *")
  .timeZone("UTC")
  .onRun(async (context) => {
    const ninetyDaysAgo = Date.now() - 90 * 24 * 60 * 60 * 1000;
    const privilegedRoles = ["SubcityModerator", "SecurityAuditor", "SystemAdmin"];

    const usersSnapshot = await admin
      .firestore()
      .collection("users")
      .where("role", "in", privilegedRoles)
      .get();

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userRecord = await admin.auth().getUser(doc.id).catch(() => null);

      if (!userRecord) continue;

      const lastSignInTime = userRecord.metadata.lastSignInTime
        ? new Date(userRecord.metadata.lastSignInTime).getTime()
        : 0;

      // Check if user has been inactive for > 90 days
      if (lastSignInTime < ninetyDaysAgo) {
        // Flag account for admin review
        await doc.ref.update({
          staleAccessFlag: true,
          staleAccessFlaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Log to audit trail
        await admin.firestore().collection("audit_logs").add({
          eventType: "STALE_ACCESS_FLAGGED",
          targetUid: doc.id,
          role: userData.role,
          lastSignInTime: userRecord.metadata.lastSignInTime || "Never",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.warn(`Privileged user ${doc.id} (${userData.role}) flagged for stale access.`);
      }
    }
  });