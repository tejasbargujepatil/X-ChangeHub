# Group Batch Teaching Feature - Documentation

## 🎯 Overview

The **Group Batch Teaching** feature allows tutors to create scheduled group learning sessions where multiple students can enroll and learn together. This is perfect for structured courses, bootcamps, or regular skill-building sessions.

---

## ✨ Key Features

### For Tutors:
- **Create Group Batches**: Set up structured learning sessions with:
  - Skill to teach
  - Custom title and description
  - Maximum student capacity (default: 20)
  - Start and end dates
  - Daily time slots
  - Schedule type (Daily, Weekdays, Weekends, Custom)
  - Google Meet link (auto-populated with default)

- **Manage Batches**: Update batch details, monitor enrollments, and close batches

- **Track Enrollment**: See real-time enrollment numbers and available seats

###For Students:
- **Browse Active Batches**: Discover all open group learning opportunities
- **Filter by Skill**: Find batches for specific skills you want to learn
- **Enroll/Unenroll**: Join or leave batches with one click
- **Access Meeting Links**: Get Google Meet links after enrollment
- **View Schedule**: See detailed schedule and duration information

---

## 📁 Files Created

### Models
- **`lib/models/batch_model.dart`**
  - Data structure for group batches
  - Enums: `BatchStatus`, `ScheduleType`
  - Fields: tutor info, schedule, enrollment tracking, meeting link

### Services
- **`lib/services/batch_service.dart`**
  - CRUD operations for batches
  - Enrollment management
  - Notification integration
  - Status updates

### Screens
- **`lib/screens/batch/create_batch_screen.dart`**
  - Form to create new batches
  - Date/time pickers
  - Schedule type selection
  - Validation

- **`lib/screens/batch/browse_batches_screen.dart`**
  - List of active batches
  - Enrollment progress bars
  - Status badges
  - Quick view of batch details

- **`lib/screens/batch/batch_details_screen.dart`**
  - Detailed batch information
  - Enrollment button
  - Meeting link access (for enrolled students)
  - Schedule and tutor information

### Updated Files
- **`lib/screens/home/explore_screen.dart`**
  - Added "Group Batches" action card
  - Navigation to browse batches

- **`firestore.rules`**
  - Security rules for batches collection
  - Enrollment/unenrollment validation
  - Tutor permissions

---

## 🎨 User Experience Flow

### Creating a Batch (Tutor)
1. Navigate to **Explore** → **Group Batches**
2. Click **"+"** icon in app bar or **"Create Batch"** button
3. Fill in batch details:
   - Select skill from your teaching skills
   - Enter title (e.g., "Web Development Bootcamp")
   - Write description
   - Set max students (default: 20)
   - Choose start/end dates
   - Set time slot (start time - end time)
   - Select schedule type
   - Meeting link is auto-filled
4. Click **"Create Batch"**
5. Batch appears in browse list immediately

### Enrolling in a Batch (Student)
1. Navigate to **Explore** → **Group Batches**
2. Browse available batches
3. Click on a batch card to view details
4. Review:
   - Tutor information
   - Schedule and duration
   - Enrollment status (seats available)
   - Batch description
5. Click **"Enroll Now"**
6. Get instant access to:
   - Meeting link
   - Schedule confirmation
   - Tutor contact

### Attending Sessions
1. Go to **Group Batches** → **Your enrolled batches**
2. Open batch details
3. Click **"Join Meeting"** at scheduled time
4. Launches Google Meet in external app

---

## 🗄️ Database Schema

### `batches` Collection
```javascript
{
  id: string,
  tutorId: string,
  tutorName: string,
  tutorImageUrl: string | null,
  skillToTeach: string,
  title: string,
  description: string,
  maxStudents: number (default: 20),
  currentEnrollments: number,
  enrolledStudentIds: string[],
  startDate: timestamp,
  endDate: timestamp,
  timeSlot: string, // e.g., "9:00 PM - 10:00 PM"
  scheduleType: 'daily' | 'weekdays' | 'weekends' | 'custom',
  customDays: number[] | null, // [1-7] for Mon-Sun
  meetingLink: string,
  status: 'open' | 'ongoing' | 'closed' | 'completed',
  createdAt: timestamp,
  metadata: object | null
}
```

---

## 🔒 Security Rules

### Batches Collection (`batches/{batchId}`)

**Read**: Any authenticated user can browse batches

**Create**: Authenticated users can create batches for themselves
- Must set `tutorId` to their own UID

**Update**: Two scenarios allowed:
1. **Tutor updates their batch** (any field)
2. **Student enrolls/unenrolls**:
   - Can only modify `enrolledStudentIds` and `currentEnrollments`
   - Enrollment: Add self to array, increment count by 1
   - Unenrollment: Remove self from array, decrement count by 1

**Delete**: Only tutors can delete their own batches
- Must have 0 current enrollments

---

## 🧪 Testing Guide

### Test Batch Creation
1. Log in as a tutor
2. Go to Explore → Group Batches → Create Batch
3. Fill all fields with valid data
4. **Verify**: Batch appears in browse list
5. **Verify**: Tutor name matches logged-in user

### Test Enrollment
1. Log in as a student (different from tutor)
2. Browse batches and select one
3. Click "Enroll Now"
4. **Verify**: Enrollment count increases
5. **Verify**: "Enroll Now" changes to "Leave Batch"
6. **Verify**: Meeting link becomes visible
7. **Verify**: Tutor receives notification (if implemented)

### Test Batch Full Scenario
1. Create batch with maxStudents: 2
2. Enroll 2 students
3. Try to enroll 3rd student
4. **Verify**: Error message "Batch is full"

### Test Unenrollment
1. Enroll in a batch
2. Click "Leave Batch"
3. Confirm in dialog
4. **Verify**: Enrollment count decreases
5. **Verify**: Meeting link hidden
6. **Verify**: Can enroll again

### Test Firestore Rules
1. Try to create batch with different tutorId
   - **Expected**: Permission denied
2. Try to modify another tutor's batch
   - **Expected**: Permission denied
3. Try to delete batch with enrollments
   - **Expected**: Permission denied

---

## 📊 Batch Status Flow

```
open → ongoing → closed → completed
  ↓        ↓        ↓         ↓
(Accepting) (Accepting) (No new) (Finished)
```

- **Open**: Newly created, accepting enrollments
- **Ongoing**: Started but still accepting new students
- **Closed**: No longer accepting enrollments
- **Completed**: Finished, archived

---

## 🔔 Notifications

When a student enrolls:
- **Title**: "New Batch Enrollment"
- **Message**: "{Student Name} has enrolled in your batch "{Batch Title}""
- **Recipient**: Tutor

---

## 🚀 Future Enhancements

- [ ] **Attendance Tracking**: Mark student attendance for each session
- [ ] **Progress Reports**: Track and share student progress
- [ ] **Recordings**: Upload session recordings
- [ ] **Assignments**: Create and manage assignments
- [ ] **Chat**: Batch-specific group chat
- [ ] **Calendar Integration**: Add to Google Calendar
- [ ] **Certificates**: Generate completion certificates
- [ ] **Payment Integration**: Paid batches
- [ ] **Ratings**: Students rate batches
- [ ] **Reminders**: Automated session reminders

---

## 💡 Best Practices

### For Tutors:
- Set realistic max students (10-20 for interactive sessions)
- Provide detailed descriptions
- Start dates should be at least 2-3 days away
- Include prerequisites in description
- Keep consistent schedule

### For Students:
- Enroll only if you can commit to the schedule
- Unenroll early if plans change
- Test meeting link before first session
- Check batch details for prerequisites

---

## 🎯 Key Metrics to Track

- Total batches created
- Average enrollment per batch
- Completion rate
- Popular skills for group learning
- Peak learning times
- Tutor engagement

---

## 📝 Example Batch

**Title**: "React.js Fundamentals - 2 Week Intensive"

**Skill**: React

**Description**: 
"Learn React.js from scratch! We'll cover components, hooks, state management, and build 3 real projects. Perfect for beginners with basic JavaScript knowledge."

**Schedule**: 
- Start: Feb 1, 2026
- End: Feb 14, 2026
- Time: 9:00 PM - 10:00 PM
- Type: Weekdays (Mon-Fri)

**Capacity**: 15 students

**Meeting Link**: https://meet.google.com/xyz-abc-def

---

**Built with ❤️ for XChangeHub - Making group learning accessible to everyone!**
