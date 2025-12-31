# Firebase Setup Instructions for XChangeHUb

## Quick Setup Using FlutterFire CLI (Recommended)

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Configure Firebase for Your Project
Run this command in the project root directory:
```bash
flutterfire configure
```

This will:
- Create a Firebase project (or select existing)
- Register your Flutter app
- Generate `firebase_options.dart` with your configuration
- Set up for Android, iOS, Web, macOS

### 4. Update main.dart
Replace the Firebase initialization in `lib/main.dart`:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

## Manual Setup (Alternative)

If you prefer manual setup or FlutterFire CLI doesn't work:

### For Android

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add Android app
4. Register with package name: `com.xchangehub.xchangehub`
5. Download `google-services.json`
6. Place it in `android/app/`
7. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```
8. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### For iOS

1. Add iOS app in Firebase Console
2. Register with bundle ID: `com.xchangehub.xchangehub`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` in Xcode
5. Update `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```

## Firebase Services Configuration

### 1. Enable Authentication

```bash
# In Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable Email/Password
3. (Optional) Enable Google Sign-in
```

### 2. Create Firestore Database

```bash
# In Firebase Console:
1. Go to Firestore Database
2. Click "Create database"
3. Start in production mode
4. Choose your region (e.g., us-central)
```

**Firestore Security Rules:**

Copy and paste these rules in Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if true; // Public profiles
      allow create: if isOwner(userId);
      allow update, delete: if isOwner(userId);
    }
    
    // Skill exchanges
    match /skill_exchanges/{exchangeId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        resource.data.requesterId == request.auth.uid || 
        resource.data.teacherId == request.auth.uid
      );
      allow delete: if isAuthenticated() && (
        resource.data.requesterId == request.auth.uid || 
        resource.data.teacherId == request.auth.uid
      );
    }
    
    // Freelance projects
    match /freelance_projects/{projectId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        resource.data.clientId == request.auth.uid || 
        resource.data.assignedToId == request.auth.uid
      );
      allow delete: if isAuthenticated() && 
        resource.data.clientId == request.auth.uid;
    }
    
    // Portfolio items
    match /portfolio/{itemId} {
      allow read: if true; // Public portfolios
      allow create, update, delete: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### 3. Enable Firebase Storage

```bash
# In Firebase Console:
1. Go to Storage
2. Click "Get started"
3. Start in production mode
```

**Storage Security Rules:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // User profile images
    match /users/{userId}/profile/{fileName} {
      allow read: if true;
      allow write: if isOwner(userId) && 
        request.resource.size < 5 * 1024 * 1024 && // 5MB limit
        request.resource.contentType.matches('image/.*');
    }
    
    // Project deliverables
    match /projects/{projectId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && 
        request.resource.size < 10 * 1024 * 1024; // 10MB limit
    }
    
    // Portfolio files
    match /portfolio/{userId}/{fileName} {
      allow read: if true;
      allow write: if isOwner(userId) && 
        request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

### 4. Enable Cloud Messaging (Push Notifications)

```bash
# In Firebase Console:
1. Go to Cloud Messaging
2. Note your Server key
3. (For iOS) Upload APNs certificate
```

## Firestore Indexes

Create these composite indexes for better query performance:

### In Firebase Console → Firestore → Indexes:

1. **Users by XP (Leaderboard)**
   - Collection: `users`
   - Fields: `xpPoints` (Descending)

2. **Skill Exchanges by User**
   - Collection: `skill_exchanges`
   - Fields: `teacherId` (Ascending), `createdAt` (Descending)

3. **Skill Exchanges by Status**
   - Collection: `skill_exchanges`
   - Fields: `teacherId` (Ascending), `status` (Ascending), `createdAt` (Descending)

4. **Open Projects**
   - Collection: `freelance_projects`
   - Fields: `status` (Ascending), `createdAt` (Descending)

5. **My Projects**
   - Collection: `freelance_projects`
   - Fields: `clientId` (Ascending), `createdAt` (Descending)

6. **Portfolio Items**
   - Collection: `portfolio`
   - Fields: `userId` (Ascending), `completedAt` (Descending)

## Testing Firebase Connection

After setup, test the connection:

```dart
// Add this to your main.dart temporarily
void testFirebaseConnection() async {
  try {
    // Test Firestore
    await FirebaseFirestore.instance
        .collection('test')
        .doc('test')
        .set({'timestamp': FieldValue.serverTimestamp()});
    
    print('✅ Firebase connected successfully!');
  } catch (e) {
    print('❌ Firebase connection failed: $e');
  }
}
```

## Common Issues & Solutions

### Issue 1: "Firebase not initialized"
**Solution:** Make sure `Firebase.initializeApp()` is called before `runApp()`

### Issue 2: "Platform not found"
**Solution:** Run `flutterfire configure` again

### Issue 3: "Permission denied" in Firestore
**Solution:** Check your security rules match the ones above

### Issue 4: Build fails on Android
**Solution:** 
1. Update `android/gradle.properties`:
   ```
   android.useAndroidX=true
   android.enableJetifier=true
   ```
2. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Issue 5: iOS build fails
**Solution:**
1. Update CocoaPods:
   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

## Environment Variables (Optional)

For better security, you can use environment variables:

1. Create `.env` file in project root
2. Add Firebase credentials
3. Use `flutter_dotenv` package
4. Add `.env` to `.gitignore`

## Next Steps

After Firebase is configured:

1. ✅ Test authentication (sign up/login)
2. ✅ Create a test user
3. ✅ Test Firestore reads/writes
4. ✅ Upload a test image to Storage
5. ✅ Set up push notifications

## Support

If you encounter issues:
1. Check Firebase Console for errors
2. Review security rules
3. Check Flutter console logs
4. Refer to [FlutterFire documentation](https://firebase.flutter.dev/)

---

**Ready to build!** 🚀
