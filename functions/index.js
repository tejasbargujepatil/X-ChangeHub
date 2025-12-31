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
