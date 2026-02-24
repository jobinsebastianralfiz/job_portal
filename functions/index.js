const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Trigger when a new user is created in Firestore
 * Sends push notification to all admins when a job provider registers
 */
exports.onProviderRegistered = functions.firestore
    .document("users/{userId}")
    .onCreate(async (snapshot, context) => {
      const userData = snapshot.data();
      const userId = context.params.userId;

      // Only process job providers
      if (userData.role !== "job_provider") {
        console.log("User is not a job provider, skipping notification");
        return null;
      }

      console.log(`New job provider registered: ${userData.firstName} ${userData.lastName}`);

      try {
        // Get all admin users
        const adminsSnapshot = await db
            .collection("users")
            .where("role", "==", "admin")
            .get();

        if (adminsSnapshot.empty) {
          console.log("No admin users found");
          return null;
        }

        // Collect admin FCM tokens
        const tokens = [];
        const adminIds = [];

        adminsSnapshot.forEach((doc) => {
          const adminData = doc.data();
          if (adminData.fcmToken) {
            tokens.push(adminData.fcmToken);
            adminIds.push(doc.id);
          }
        });

        if (tokens.length === 0) {
          console.log("No admin FCM tokens found");
          return null;
        }

        // Create notification payload
        const providerName = `${userData.firstName} ${userData.lastName}`.trim();
        const companyName = userData.companyName || "Unknown Company";

        const message = {
          notification: {
            title: "New Job Provider Registration",
            body: `${providerName} has registered as a job provider and is pending approval.`,
          },
          data: {
            type: "new_provider",
            userId: userId,
            providerName: providerName,
            email: userData.email || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          tokens: tokens,
        };

        // Send push notifications
        const response = await messaging.sendEachForMulticast(message);
        console.log(`Sent ${response.successCount} notifications, ${response.failureCount} failed`);

        // Create in-app notifications for each admin
        const batch = db.batch();
        const now = admin.firestore.FieldValue.serverTimestamp();

        for (const adminId of adminIds) {
          const notificationRef = db.collection("notifications").doc();
          batch.set(notificationRef, {
            notificationId: notificationRef.id,
            userId: adminId,
            type: "system",
            title: "New Job Provider Registration",
            body: `${providerName} has registered as a job provider and is pending approval.`,
            data: {
              type: "new_provider",
              providerId: userId,
              providerName: providerName,
              email: userData.email || "",
            },
            actionUrl: `/admin/users/${userId}`,
            isRead: false,
            createdAt: now,
          });
        }

        await batch.commit();
        console.log(`Created in-app notifications for ${adminIds.length} admins`);

        // Handle failed tokens (remove invalid ones)
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              failedTokens.push(tokens[idx]);
              console.log(`Token failed: ${resp.error?.message}`);
            }
          });
          // Optionally: Remove failed tokens from user documents
        }

        return {success: true, sent: response.successCount};
      } catch (error) {
        console.error("Error sending notification:", error);
        return {success: false, error: error.message};
      }
    });

/**
 * Trigger when a provider status is updated (approved/rejected)
 * Sends notification to the provider
 */
exports.onProviderStatusChanged = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;

      // Only process job providers
      if (afterData.role !== "job_provider") {
        return null;
      }

      // Check if status changed
      const oldStatus = beforeData.providerStatus;
      const newStatus = afterData.providerStatus;

      if (oldStatus === newStatus) {
        return null;
      }

      console.log(`Provider ${userId} status changed: ${oldStatus} -> ${newStatus}`);

      let title;
      let body;

      switch (newStatus) {
        case "approved":
          title = "Account Approved!";
          body = "Your job provider account has been approved. You can now select a subscription plan.";
          break;
        case "rejected":
          title = "Account Not Approved";
          body = afterData.rejectionReason ||
            "Your job provider application was not approved. Please contact support for more information.";
          break;
        case "active":
          title = "Account Activated";
          body = "Your account is now active. You can start posting jobs!";
          break;
        case "suspended":
          title = "Account Suspended";
          body = "Your account has been suspended. Please contact support.";
          break;
        default:
          return null;
      }

      try {
        // Send push notification if user has FCM token
        if (afterData.fcmToken) {
          const message = {
            notification: {
              title: title,
              body: body,
            },
            data: {
              type: "status_update",
              newStatus: newStatus,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            token: afterData.fcmToken,
          };

          await messaging.send(message);
          console.log(`Push notification sent to provider ${userId}`);
        }

        // Create in-app notification
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          notificationId: notificationRef.id,
          userId: userId,
          type: "status_update",
          title: title,
          body: body,
          data: {
            type: "status_update",
            newStatus: newStatus,
          },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`In-app notification created for provider ${userId}`);
        return {success: true};
      } catch (error) {
        console.error("Error sending status notification:", error);
        return {success: false, error: error.message};
      }
    });

/**
 * Trigger when a new application is submitted
 * Sends notification to the job provider
 */
exports.onApplicationSubmitted = functions.firestore
    .document("applications/{applicationId}")
    .onCreate(async (snapshot, context) => {
      const applicationData = snapshot.data();
      const applicationId = context.params.applicationId;

      try {
        // Get the job to find the provider
        const jobDoc = await db.collection("jobs").doc(applicationData.jobId).get();
        if (!jobDoc.exists) {
          console.log("Job not found");
          return null;
        }

        const jobData = jobDoc.data();
        const providerId = jobData.providerId;

        // Get provider data
        const providerDoc = await db.collection("users").doc(providerId).get();
        if (!providerDoc.exists) {
          console.log("Provider not found");
          return null;
        }

        const providerData = providerDoc.data();
        const applicantName = applicationData.applicantName ||
          `${applicationData.firstName} ${applicationData.lastName}`.trim();

        // Send push notification if provider has FCM token
        if (providerData.fcmToken) {
          const message = {
            notification: {
              title: "New Application Received",
              body: `${applicantName} applied for ${jobData.title}`,
            },
            data: {
              type: "new_application",
              applicationId: applicationId,
              jobId: applicationData.jobId,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            token: providerData.fcmToken,
          };

          await messaging.send(message);
          console.log(`Push notification sent to provider ${providerId}`);
        }

        // Create in-app notification
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          notificationId: notificationRef.id,
          userId: providerId,
          type: "application",
          title: "New Application",
          body: `${applicantName} applied for ${jobData.title}`,
          data: {
            applicationId: applicationId,
            jobId: applicationData.jobId,
            applicantId: applicationData.seekerId,
          },
          actionUrl: `/applications/${applicationId}`,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {success: true};
      } catch (error) {
        console.error("Error sending application notification:", error);
        return {success: false, error: error.message};
      }
    });