import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to create Google Meet links via Cloud Function
/// Uses hackersdaddy826@gmail.com as the central meeting host
class GoogleMeetService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Creates a Google Calendar event with Google Meet link
  /// 
  /// Returns the Google Meet link on success
  /// Throws exception on failure
  Future<GoogleMeetResult> createMeetingEvent({
    required String title,
    required DateTime startTime,
    required int durationMinutes,
    String? description,
    List<String>? attendeeEmails,
  }) async {
    try {
      // Calculate end time
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      // Prepare data for Cloud Function
      final data = {
        'title': title,
        'description': description ?? '',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'attendeeEmails': attendeeEmails ?? [],
      };

      // Call Cloud Function
      final callable = _functions.httpsCallable('createGoogleMeetEvent');
      final response = await callable.call(data);

      // Parse response
      final result = response.data as Map<String, dynamic>;

      if (result['success'] == true) {
        return GoogleMeetResult(
          meetLink: result['meetLink'] as String,
          eventId: result['eventId'] as String,
          eventLink: result['eventLink'] as String?,
        );
      } else {
        throw Exception('Failed to create Google Meet: ${result['message']}');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function error: ${e.code} - ${e.message}');
    } catch (e) {
      throw Exception('Failed to create Google Meet: $e');
    }
  }

  /// Deletes a Google Calendar event (optional - for cancellations)
  Future<bool> deleteMeetingEvent(String eventId) async {
    try {
      final callable = _functions.httpsCallable('deleteGoogleMeetEvent');
      final response = await callable.call({'eventId': eventId});

      final result = response.data as Map<String, dynamic>;
      return result['success'] == true;
    } catch (e) {
      print('Error deleting Google Meet event: $e');
      return false;
    }
  }

  /// Gets current user's email for attendee list
  String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }
}

/// Result from creating a Google Meet event
class GoogleMeetResult {
  final String meetLink;    // The Google Meet join link
  final String eventId;     // Calendar event ID (for deletion)
  final String? eventLink;  // Link to view event in Google Calendar

  GoogleMeetResult({
    required this.meetLink,
    required this.eventId,
    this.eventLink,
  });

  Map<String, dynamic> toJson() => {
    'meetLink': meetLink,
    'eventId': eventId,
    'eventLink': eventLink,
  };

  factory GoogleMeetResult.fromJson(Map<String, dynamic> json) => GoogleMeetResult(
    meetLink: json['meetLink'] as String,
    eventId: json['eventId'] as String,
    eventLink: json['eventLink'] as String?,
  );
}
