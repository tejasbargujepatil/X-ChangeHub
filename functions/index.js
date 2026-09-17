const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { google } = require("googleapis");

admin.initializeApp();

/**
 * Cloud Function to create Google Calendar events with Meet links
 * Uses hackersdaddy826@gmail.com as the central meeting host
 */
exports.createGoogleMeetEvent = functions.https.onCall(
    async (data, context) => {
        try {
            // Verify user is authenticated
            if (!context.auth) {
                throw new functions.https.HttpsError(
                    "unauthenticated",
                    "User must be authenticated to create meetings",
                );
            }

            // Extract data
            const {
                title,
                description,
                startTime, // ISO 8601 format
                endTime, // ISO 8601 format
                attendeeEmails, // Array of email addresses
            } = data;

            // Validate required fields
            if (!title || !startTime || !endTime) {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Missing required fields: title, startTime, endTime",
                );
            }

            // OAuth2 credentials for hackersdaddy826@gmail.com
            // These will be set in Firebase Functions config
            const oauth2Client = new google.auth.OAuth2(
                functions.config().google.client_id,
                functions.config().google.client_secret,
                functions.config().google.redirect_uri,
            );

            // Set refresh token (from config)
            oauth2Client.setCredentials({
                refresh_token: functions.config().google.refresh_token,
            });

            // Create Calendar API client
            const calendar = google.calendar({ version: "v3", auth: oauth2Client });

            // Create event with Google Meet
            const event = {
                summary: title,
                description: description || "",
                start: {
                    dateTime: startTime,
                    timeZone: "Asia/Kolkata", // IST
                },
                end: {
                    dateTime: endTime,
                    timeZone: "Asia/Kolkata", // IST
                },
                attendees: attendeeEmails ? attendeeEmails.map((email) => ({ email })) : [],
                conferenceData: {
                    createRequest: {
                        requestId: `xchangehub-${Date.now()}`,
                        conferenceSolutionKey: {
                            type: "hangoutsMeet",
                        },
                    },
                },
                reminders: {
                    useDefault: false,
                    overrides: [
                        { method: "email", minutes: 60 }, // 1 hour before
                        { method: "popup", minutes: 30 }, // 30 min before
                    ],
                },
            };

            // Insert event
            const response = await calendar.events.insert({
                calendarId: "primary",
                conferenceDataVersion: 1,
                sendUpdates: "all", // Send email invites to attendees
                resource: event,
            });

            // Extract Meet link
            const meetLink = response.data.conferenceData &&
                response.data.conferenceData.entryPoints &&
                response.data.conferenceData.entryPoints.find(
                    (ep) => ep.entryPointType === "video",
                ) ?
                response.data.conferenceData.entryPoints.find(
                    (ep) => ep.entryPointType === "video",
                ).uri : null;

            if (!meetLink) {
                throw new functions.https.HttpsError(
                    "internal",
                    "Failed to generate Google Meet link",
                );
            }

            console.log(`Created Google Meet: ${meetLink} for event: ${title}`);

            // Return the Meet link and event details
            return {
                success: true,
                meetLink,
                eventId: response.data.id,
                eventLink: response.data.htmlLink,
                message: "Google Meet event created successfully",
            };
        } catch (error) {
            console.error("Error creating Google Meet event:", error);

            if (error instanceof functions.https.HttpsError) {
                throw error;
            }

            throw new functions.https.HttpsError(
                "internal",
                `Failed to create Google Meet: ${error.message}`,
            );
        }
    });

/**
 * Optional: Delete Google Calendar event
 */
exports.deleteGoogleMeetEvent = functions.https.onCall(
    async (data, context) => {
        try {
            if (!context.auth) {
                throw new functions.https.HttpsError(
                    "unauthenticated",
                    "User must be authenticated",
                );
            }

            const { eventId } = data;

            if (!eventId) {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Missing eventId",
                );
            }

            const oauth2Client = new google.auth.OAuth2(
                functions.config().google.client_id,
                functions.config().google.client_secret,
                functions.config().google.redirect_uri,
            );

            oauth2Client.setCredentials({
                refresh_token: functions.config().google.refresh_token,
            });

            const calendar = google.calendar({ version: "v3", auth: oauth2Client });

            await calendar.events.delete({
                calendarId: "primary",
                eventId: eventId,
                sendUpdates: "all", // Notify attendees
            });

            return {
                success: true,
                message: "Google Meet event deleted successfully",
            };
        } catch (error) {
            console.error("Error deleting Google Meet event:", error);
            throw new functions.https.HttpsError(
                "internal",
                `Failed to delete event: ${error.message}`,
            );
        }
    });

/**
 * Trusted server-side Cloud Function to assign reviewer or admin custom claims.
 * Client self-escalation is prevented. Only an authenticated Admin or a system bootstrap secret can invoke this.
 */
exports.setUserRole = functions.https.onCall(
    async (data, context) => {
        try {
            if (!context.auth) {
                throw new functions.https.HttpsError(
                    "unauthenticated",
                    "User must be authenticated to invoke role management",
                );
            }

            const { targetUid, role, bootstrapSecret } = data;

            if (!targetUid || !role || !["standard", "reviewer", "admin"].includes(role)) {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Missing or invalid parameters: targetUid and role ('standard', 'reviewer', 'admin') are required",
                );
            }

            const callerIsAdmin = context.auth.token && context.auth.token.admin === true;
            const configBootstrapSecret = functions.config().admin ? functions.config().admin.bootstrap_secret : null;

            const isAuthorizedBootstrap = bootstrapSecret && configBootstrapSecret && bootstrapSecret === configBootstrapSecret;

            if (!callerIsAdmin && !isAuthorizedBootstrap) {
                throw new functions.https.HttpsError(
                    "permission-denied",
                    "Unauthorized: Only administrators can modify user roles",
                );
            }

            const claims = {
                admin: role === "admin",
                reviewer: role === "reviewer" || role === "admin",
            };

            await admin.auth().setCustomUserClaims(targetUid, claims);

            console.log(`Successfully assigned custom claims ${JSON.stringify(claims)} to user ${targetUid}`);

            return {
                success: true,
                targetUid,
                role,
                claims,
                message: `User ${targetUid} has been granted the role: ${role}`,
            };
        } catch (error) {
            console.error("Error in setUserRole function:", error);
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError(
                "internal",
                `Failed to set user role: ${error.message}`,
            );
        }
    });

/**
 * Trusted server-side Cloud Function to recalculate evidence-based Mentor Quality metrics.
 * Clients cannot write to `mentor_metrics/{mentorUserId}` directly.
 */
exports.recalculateMentorMetrics = functions.https.onCall(
    async (data, context) => {
        try {
            if (!context.auth) {
                throw new functions.https.HttpsError(
                    "unauthenticated",
                    "User must be authenticated to recalculate metrics",
                );
            }

            const { mentorUserId } = data;
            if (!mentorUserId) {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Missing parameter: mentorUserId",
                );
            }

            const db = admin.firestore();

            // 0. Rate-limiting cooldown check (60-second minimum between recalculations per mentor)
            const metricsRef = db.collection("mentor_metrics").doc(mentorUserId);
            const existingMetricsDoc = await metricsRef.get();

            if (existingMetricsDoc.exists && existingMetricsDoc.data().updatedAt) {
                const updatedAt = existingMetricsDoc.data().updatedAt;
                let lastUpdatedMs = 0;
                if (typeof updatedAt.toMillis === "function") {
                    lastUpdatedMs = updatedAt.toMillis();
                } else if (typeof updatedAt === "number") {
                    lastUpdatedMs = updatedAt;
                } else if (typeof updatedAt === "string") {
                    lastUpdatedMs = new Date(updatedAt).getTime() || 0;
                } else if (updatedAt.seconds) {
                    lastUpdatedMs = updatedAt.seconds * 1000;
                }

                const COOLDOWN_MS = 60 * 1000; // 60 seconds
                if (Date.now() - lastUpdatedMs < COOLDOWN_MS) {
                    console.log(`Rate-limit cooldown active for mentor ${mentorUserId}. Returning cached metrics.`);
                    return {
                        success: true,
                        mentorUserId,
                        metrics: existingMetricsDoc.data(),
                        rateLimited: true,
                        message: "Metrics were calculated within the last 60 seconds. Returning cached metrics.",
                    };
                }
            }

            // 1. Fetch Learning Plans where user is mentor
            const plansSnap = await db
                .collection("learning_plans")
                .where("mentorId", "==", mentorUserId)
                .get();

            let completedPlans = 0;
            let topicsAssigned = 0;
            let topicsTaught = 0;
            let topicsConfirmed = 0;
            let topicsPartially = 0;
            let topicsNeedHelp = 0;

            plansSnap.forEach((doc) => {
                const plan = doc.data();
                if (plan.status === "completed") completedPlans++;

                if (Array.isArray(plan.modules)) {
                    plan.modules.forEach((module) => {
                        if (Array.isArray(module.topics)) {
                            module.topics.forEach((topic) => {
                                topicsAssigned++;
                                if (topic.taughtByMentor) topicsTaught++;
                                if (topic.learnerConfirmed) {
                                    if (topic.learnerStatus === "completed") topicsConfirmed++;
                                    else if (topic.learnerStatus === "partiallyUnderstood") topicsPartially++;
                                    else if (topic.learnerStatus === "needHelp") topicsNeedHelp++;
                                }
                            });
                        }
                    });
                }
            });

            // 2. Fetch Learning Issues where reportedUserId == mentorUserId
            const issuesSnap = await db
                .collection("learning_issues")
                .where("reportedUserId", "==", mentorUserId)
                .get();

            let validatedIssues = 0;
            let dismissedIssues = 0;

            issuesSnap.forEach((doc) => {
                const issue = doc.data();
                if (issue.status === "dismissed" || issue.resolution === "dismissed") {
                    dismissedIssues++;
                } else if (issue.status === "resolved") {
                    validatedIssues++;
                }
            });

            // 3. Fetch Learning Interventions for mentorUserId
            const intvSnap = await db
                .collection("learning_interventions")
                .where("targetUserId", "==", mentorUserId)
                .get();

            let correctiveInts = 0;
            let additionalTeachingInts = 0;
            let rematchInts = 0;

            intvSnap.forEach((doc) => {
                const intv = doc.data();
                if (intv.action === "correctiveSession") correctiveInts++;
                else if (intv.action === "additionalTeaching") additionalTeachingInts++;
                else if (intv.action === "rematch") rematchInts++;
            });

            // 4. Fetch User profile for ratings & verified skills
            const userDoc = await db.collection("users").doc(mentorUserId).get();
            const userData = userDoc.exists ? userDoc.data() : {};

            const ratingAverage = userData.averageRating || 0.0;
            const ratingCount = userData.totalRatings || 0;
            const verifiedSkills = Array.isArray(userData.verifiedSkills) ? userData.verifiedSkills : [];

            const totalExchanges = plansSnap.size;
            const successfulExchanges = Math.max(0, totalExchanges - validatedIssues);
            const hasMinHistory = totalExchanges >= 3 || topicsTaught >= 5;

            // Calculate score
            let qualityScore = null;
            if (hasMinHistory) {
                const deliveryRate = topicsTaught > 0
                    ? Math.min(100.0, Math.max(0.0, ((topicsConfirmed + (0.5 * topicsPartially)) / topicsTaught) * 100.0))
                    : 80.0;
                const penalty = (validatedIssues * 15.0) + (rematchInts * 20.0);
                const accountabilityScore = Math.min(100.0, Math.max(0.0, 100.0 - penalty));
                const ratingScore = ratingCount > 0 ? Math.min(100.0, Math.max(0.0, (ratingAverage / 5.0) * 100.0)) : 80.0;

                qualityScore = Number(((0.40 * deliveryRate) + (0.30 * accountabilityScore) + (0.30 * ratingScore)).toFixed(1));
            }

            const now = admin.firestore.FieldValue.serverTimestamp();

            const metricsData = {
                mentorUserId,
                completedExchanges: totalExchanges,
                successfulExchanges,
                learningPlansCompleted: completedPlans,
                topicsAssigned,
                topicsTaught,
                topicsLearnerConfirmed: topicsConfirmed,
                topicsPartiallyUnderstood: topicsPartially,
                topicsNeedHelp,
                validatedLearningIssues: validatedIssues,
                dismissedLearningIssues: dismissedIssues,
                correctiveInterventions: correctiveInts,
                additionalTeachingInterventions: additionalTeachingInts,
                rematchInterventions: rematchInts,
                learnerRatingAverage: ratingAverage,
                learnerRatingCount: ratingCount,
                verifiedSkillCount: verifiedSkills.length,
                qualityScore,
                sufficientHistory: hasMinHistory,
                updatedAt: now,
            };

            await db.collection("mentor_metrics").doc(mentorUserId).set(metricsData, { merge: true });

            return {
                success: true,
                mentorUserId,
                metrics: metricsData,
            };
        } catch (error) {
            console.error("Error in recalculateMentorMetrics:", error);
            throw new functions.https.HttpsError(
                "internal",
                `Failed to recalculate mentor metrics: ${error.message}`,
            );
        }
    });


