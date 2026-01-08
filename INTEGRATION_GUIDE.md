# Quick Integration Guide - Final Features

## 🎯 3 Files Need Updates

### 1. **Exchanges Screen** - Add Review Button
**File:** `lib/screens/exchange/exchanges_screen.dart`

**Find:** The `_buildCompletedTab()` method where completed exchanges are displayed

**Add:** After the completion status badge, add this review button:

```dart
import '../widgets/review_dialog.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

// Inside the completed exchange card widget
if (exchange.status == ExchangeStatus.completed) {
  const SizedBox(height: 12),
  FutureBuilder<bool>(
    future: ReviewService().canReview(
      revieweeId: currentUserId == exchange.requesterId 
          ? exchange.teacherId 
          : exchange.requesterId,
      relatedId: exchange.id,
    ),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!) {
        return const SizedBox.shrink();
      }
      
      final isRequester = currentUserId == exchange.requesterId;
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ReviewDialog(
              revieweeId: isRequester ? exchange.teacherId : exchange.requesterId,
              revieweeName: isRequester ? exchange.teacherName : exchange.requesterName,
              type: ReviewType.skillExchange,
              relatedId: exchange.id,
            ),
          ),
          icon: const Icon(Icons.star_rate),
          label: const Text('Rate Partner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      );
    },
  ),
}
```

---

### 2. **Batch Details Screen** - Add Review Button
**File:** `lib/screens/batch/batch_details_screen.dart`

**Find:** Where batch status is displayed for enrolled students

**Add:** For completed batches:

```dart
import '../widgets/review_dialog.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

// After batch completion info, for enrolled students
if (batch.status == BatchStatus.completed && isEnrolled) {
  const SizedBox(height: 16),
  FutureBuilder<bool>(
    future: ReviewService().canReview(
      revieweeId: batch.tutorId,
      relatedId: batch.id,
    ),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'You have already reviewed this batch',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        );
      }
      
      return ElevatedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => ReviewDialog(
            revieweeId: batch.tutorId,
            revieweeName: batch.tutorName,
            type: ReviewType.groupBatch,
            relatedId: batch.id,
          ),
        ),
        icon: const Icon(Icons.star_rate),
        label: const Text('Rate Tutor'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    },
  ),
}
```

---

### 3. **Freelance Service** - Add Payment on Deliverable Submission
**File:** `lib/services/freelance_service.dart`

**Find:** The `submitDeliverables` or similar method

**Add Payment Processing:**

```dart
import 'payment_service.dart';

Future<void> submitDeliverables({
  required String projectId,
  required String deliverableUrl,
  String? notes,
}) async {
  try {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    // Get project details
    final projectDoc = await _firestore
        .collection('freelance_projects')
        .doc(projectId)
        .get();
    
    if (!projectDoc.exists) {
      throw Exception('Project not found');
    }

    final project = FreelanceProjectModel.fromMap(projectDoc.data()!);

    // Verify user is the freelancer
    if (project.freelancerId != uid) {
      throw Exception('Only assigned freelancer can submit deliverables');
    }

    // Update project with deliverables
    await _firestore.collection('freelance_projects').doc(projectId).update({
      'deliverableUrl': deliverableUrl,
      'deliveryNotes': notes,
      'deliveredAt': DateTime.now().toIso8601String(),
      'status': 'delivered',
    });

    // ⭐ PROCESS PAYMENT (MOCK) ⭐
    final paymentService = PaymentService();
    await paymentService.processPayment(
      toUserId: project.freelancerId,
      amount: project.budget,
      relatedId: projectId,
      relatedType: 'freelance_project',
    );

    // Notify client
    await _notificationService.createNotification(
      userId: project.clientId,
      type: NotificationType.other,
      title: 'Project Deliverables Submitted!',
      message: 'The freelancer has submitted the final work. Payment of ₹${project.budget} has been processed.',
      data: {
        'projectId': projectId,
        'freelancerId': project.freelancerId,
        'amount': project.budget.toString(),
      },
    );

  } catch (e) {
    throw Exception('Failed to submit deliverables: $e');
  }
}
```

---

## 🚀 Quick Test Steps

After adding the above code:

1. **Test Reviews:**
   - Complete an exchange
   - Go to Exchanges → Completed tab
   - Click "Rate Partner"
   - Give 5 stars + comment
   - Verify notification sent
   - Check profile shows updated rating

2. **Test Batch Reviews:**
   - Complete a batch session
   - Students see "Rate Tutor"
   - Multiple students can review
   - All reviews counted in stats

3. **Test Payments:**
   - Create a freelance project
   - Freelancer submits deliverables
   - Verify payment notification
   - Check payment in history
   - Verify amount is correct

---

## 📋 Import Checklist

Make sure these imports are at the top of each modified file:

**Exchanges Screen:**
```dart
import '../widgets/review_dialog.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
```

**Batch Details Screen:**
```dart
import '../widgets/review_dialog.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
```

**Freelance Service:**
```dart
import 'payment_service.dart';
```

---

## ✅ Deploy Firestore Rules

```bash
cd /home/tejasbargujepatil/Desktop/XchangeHUb
firebase deploy --only firestore:rules
```

---

**That's it! All features are now integrated.** 🎉
