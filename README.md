# XChangeHUb - Peer-to-Peer Learning Platform

![XChangeHUb Logo](assets/images/logo.png)

**XChangeHUb** is a comprehensive peer-to-peer learning platform built with Flutter and Firebase that enables students to learn new skills by teaching what they know—without paying money.

## 🌟 Core Features

### 1️⃣ Skill Exchange (Core Feature)
- **Peer-to-Peer Learning**: Users can teach and learn skills without any monetary exchange
- **Smart Matching**: Algorithm matches users based on complementary skills
- **Session Management**: Schedule, conduct, and complete learning sessions
- **Ratings & Reviews**: Mutual feedback system to maintain quality

### 2️⃣ Freelancing Marketplace
- **Entry-Level Projects**: Beginner-friendly gig marketplace
- **No Bidding Fees**: Direct application to projects
- **Skill-Based Filtering**: Find projects matching your expertise
- **Payment Integration**: Secure payment release after approval
- **10% Platform Commission**: Sustainable revenue model

### 3️⃣ Auto-Generated Portfolio
- **Automatic Updates**: Every completed exchange and project is added
- **Professional PDF Export**: Generate and share portfolio as PDF
- **Skill Tracking**: Comprehensive record of learned and taught skills
- **Reviews Display**: Showcase ratings and testimonials

### 4️⃣ Community & Trust System
- **XP Points & Levels**: Gamified progression system
- **Badges & Achievements**: Earn badges for milestones
- **Leaderboard**: See top performers in the community
- **Rating System**: Build reputation through quality interactions

## 🛠 Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Provider** - State management
- **Google Fonts** - Beautiful typography
- **Material Design 3** - Modern UI components

### Backend
- **Firebase Authentication** - User management
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - File storage
- **Firebase Messaging** - Push notifications

### Additional Libraries
- PDF generation for portfolios
- Image picker & cropper
- Chat UI components
- Rating bar widgets
- Lottie animations

## 📱 App Structure

```
lib/
├── config/
│   ├── app_config.dart      # App constants & configs
│   └── theme.dart            # App theme & styling
├── models/
│   ├── user_model.dart
│   ├── skill_exchange_model.dart
│   ├── freelance_project_model.dart
│   ├── portfolio_item_model.dart
│   └── badge_model.dart
├── services/
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── skill_exchange_service.dart
│   ├── freelance_service.dart
│   └── portfolio_service.dart
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── explore_screen.dart
│   ├── exchange/
│   │   ├── exchanges_screen.dart
│   │   └── find_matches_screen.dart
│   ├── freelance/
│   │   └── marketplace_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   └── edit_profile_screen.dart
│   └── portfolio/
│       ├── portfolio_view_screen.dart
│       └── leaderboard_screen.dart
└── main.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.38.4 or later)
- Dart SDK (3.10.3 or later)
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   cd XchangeHUb
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (See detailed setup below)
   - Create a Firebase project
   - Add Android/iOS apps
   - Download and add configuration files
   - Enable services (Auth, Firestore, Storage, Messaging)

4. **Update Firebase Configuration**
   
   Edit `lib/main.dart` and replace the Firebase options with your project credentials:
   ```dart
   await Firebase.initializeApp(
     options: const FirebaseOptions(
       apiKey: 'YOUR_API_KEY',
       appId: 'YOUR_APP_ID',
       messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
       projectId: 'YOUR_PROJECT_ID',
       storageBucket: 'YOUR_STORAGE_BUCKET',
     ),
   );
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔥 Firebase Setup Guide

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `XChangeHUb`
4. Follow the setup wizard

### Step 2: Add Flutter App
1. In Project Overview, click "Add app" → Flutter
2. Follow FlutterFire CLI instructions:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### Step 3: Enable Authentication
1. Go to **Authentication** → Get Started
2. Enable **Email/Password** sign-in method
3. (Optional) Enable Google, Facebook sign-in

### Step 4: Set Up Firestore
1. Go to **Firestore Database** → Create database
2. Start in **production mode**
3. Choose a location
4. Update security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Skill exchanges
    match /skill_exchanges/{exchangeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.requesterId == request.auth.uid || 
         resource.data.teacherId == request.auth.uid);
    }
    
    // Freelance projects
    match /freelance_projects/{projectId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.assignedToId == request.auth.uid);
    }
    
    // Portfolio items
    match /portfolio/{itemId} {
      allow read: if true;
      allow write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Step 5: Enable Storage
1. Go to **Storage** → Get Started
2. Start in **production mode**
3. Update storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /projects/{projectId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 6: Enable Cloud Messaging
1. Go to **Cloud Messaging**
2. Generate server key for notifications

## 🎨 Features Breakdown

### XP & Level System
- **Teaching a skill**: 50 XP
- **Learning a skill**: 30 XP
- **Beginner project**: 100 XP
- **Intermediate project**: 250 XP
- **Advanced project**: 500 XP
- **Level formula**: `Level = sqrt(XP / 100) + 1`

### Badge System
- First Exchange
- Exchange Master (50 exchanges)
- Freelance Starter
- Top Rated (4.5+ rating, 20+ reviews)
- Mentor (100+ teachings)

## 📄 License

This project is licensed under the MIT License.

## 👥 Team

Developed with ❤️ by the XChangeHUb Team

---

**Made with Flutter & Firebase** 🚀
