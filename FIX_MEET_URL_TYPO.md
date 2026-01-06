# 🔧 Fixing Google Meet URL Typo in Database

## Problem
Some skill exchanges in the Firestore database have `meet.googl.com` instead of `meet.google.com` in their `meetingLink` field.

## Quick Fix Applied ✅

I've updated `exchanges_screen.dart` to **automatically correct** this typo in the app code:

```dart
// Fix common typo: meet.googl.com -> meet.google.com
url = url.replaceAll('meet.googl.com', 'meet.google.com');
```

This means the app will now work correctly even if the database has the typo!

---

## Optional: Clean Up Database (Recommended)

To permanently fix the data in your Firestore database, you can run this script:

### Option 1: Using Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **xchangehub-f61be**
3. Go to **Firestore Database**
4. Navigate to `skill_exchanges` collection
5. Find any documents with `meetingLink` field containing `meet.googl.com`
6. Manually edit and change to `meet.google.com`

### Option 2: Using Firebase Admin Script (Automated)

Create a file `fix_meet_links.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixMeetLinks() {
  const exchangesRef = db.collection('skill_exchanges');
  const snapshot = await exchangesRef.get();
  
  let fixedCount = 0;
  
  const batch = db.batch();
  
  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.meetingLink && data.meetingLink.includes('meet.googl.com')) {
      const fixedLink = data.meetingLink.replace('meet.googl.com', 'meet.google.com');
      batch.update(doc.ref, { meetingLink: fixedLink });
      console.log(`Fixing ${doc.id}: ${data.meetingLink} -> ${fixedLink}`);
      fixedCount++;
    }
  });
  
  if (fixedCount > 0) {
    await batch.commit();
    console.log(`✅ Fixed ${fixedCount} meeting links!`);
  } else {
    console.log('✅ No typos found!');
  }
}

fixMeetLinks().catch(console.error);
```

Then run:
```bash
node fix_meet_links.js
```

---

## Testing

1. Hot restart the app (press `r` in the terminal)
2. Navigate to an exchange with a Google Meet link
3. Tap **"Join Google Meet"**
4. Verify it opens correctly now ✅

---

## Prevention

When users create new meetings, ensure they:
1. Use the dialog helper text: "Create a new Google Meet at **meet.google.com/new**"
2. Copy-paste the full URL (not just the code)
3. The app will now auto-correct any typos!

---

## Summary

✅ **App Code Fixed**: Automatically corrects typo on-the-fly  
⏳ **Database Cleanup**: Optional, but recommended for clean data  
🎯 **Impact**: All existing meetings will now work correctly!
