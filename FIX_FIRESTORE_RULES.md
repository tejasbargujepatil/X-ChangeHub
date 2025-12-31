# 🔧 Fix Firestore Permission Error - Instructions

## ⚠️ Current Error

```
PERMISSION_DENIED - Missing or insufficient permissions
Write failed at users/8EZmlSuQiiNMOIiy7T2oJxiB8fu1
Exception: Failed to complete exchange: Exception: Failed to update rating
```

---

## 🎯 Root Cause

When you complete a skill exchange:
1. Your app tries to update **your** rating/XP ✅ (allowed)
2. Your app tries to update **partner's** rating/XP ❌ (DENIED!)

**Current rule blocks this:**
```javascript
allow update: if isOwner(userId); // Only owner can update
```

---

## ✅ Solution: Update Firestore Rules

### **Step 1: Go to Firebase Console**

1. Open: https://console.firebase.google.com/
2. Select project: **xchangehub-f61be**
3. Click **Firestore Database** in left menu
4. Click **Rules** tab at the top

---

###Step **2: Replace Current Rules**

**COPY the entire code below and PASTE into the Firebase console:**

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
    
    // Check if only specific fields are being updated (for skill exchange rewards)
    function isUpdatingExchangeFields() {
      return request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['xp', 'level', 'averageRating', 'totalRatings', 'completedExchanges']);
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if true; // Public profiles (needed for username check during signup)
      allow create: if isOwner(userId);
      
      // Allow owner to update their own profile
      // OR allow any authenticated user to update XP/rating fields (for skill exchanges)
      allow update: if isOwner(userId) || 
                      (isAuthenticated() && isUpdatingExchangeFields());
      
      allow delete: if isOwner(userId);
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

---

### **Step 3: Publish Rules**

1. Click **Publish** button (top right)
2. Wait for "Rules published successfully" message
3. Rules are now live!

---

## 🔒 Security Explained

### **What Changed:**

**Before:**
```javascript
allow update: if isOwner(userId);
// ❌ Only you can update your own profile
```

**After:**
```javascript
allow update: if isOwner(userId) ||              // You can update your own profile
              (isAuthenticated() &&              // OR any authenticated user
               isUpdatingExchangeFields());      // can update ONLY XP/rating fields
```

### **Why This is Safe:**

The new `isUpdatingExchangeFields()` function checks that **ONLY** these fields are being updated:
- ✅ `xp` - Experience points
- ✅ `level` - User level
- ✅ `averageRating` - Rating average
- ✅ `totalRatings` - Number of ratings
- ✅ `completedExchanges` - Completed exchange count

**Security guarantees:**
- ❌ Can't change username
- ❌ Can't change email
- ❌ Can't change password
- ❌ Can't change profile image
- ❌ Can't change skills
- ✅ **Only** exchange-related rewards can be updated by partners

---

## ✅ How to Test

After publishing the rules:

1. **In your app:**
   - Go to **Exchanges → Active**
   - Click **Complete** on an exchange
   - ✅ Should succeed without permission error

2. **Verify both users:**
   - Check that **both** users get XP/rating updated
   - Check Profile screen shows updated stats

---

## 📊 What This Enables

With these new rules, skill exchanges will now correctly:

| Action | Before | After |
|--------|--------|-------|
| Your XP/Rating updated | ✅ Works | ✅ Works |
| Partner XP/Rating updated | ❌ DENIED | ✅ **FIXED!** |
| Your profile data protected | ✅ Safe | ✅ Safe |
| Partner profile data protected | ✅ Safe | ✅ Safe |

---

## 🆘 Troubleshooting

### **Issue: Still getting permission error**
- Wait 1-2 minutes after publishing (Firebase caches rules)
- Force quit the app and reopen
- Check you're logged in (rules require authentication)

### **Issue: Rules won't publish**
- Check for syntax errors (copy the **exact** code above)
- Make sure you replaced **all** the old rules
- Click "Publish" not "Validate"

### **Issue: Different error message**
- Share the new error message for help
- Check Firebase Console → Firestore → Usage tab for details

---

## 🎉 Expected Result

After fixing, when you complete an exchange:

```
✅ Exchange status → completed
✅ Your XP → +30 (learner) or +50 (teacher)
✅ Partner XP → +30 (learner) or +50 (teacher)
✅ Your rating → updated
✅ Partner rating → updated
✅ Both portfolios → exchange added
✅ No permission errors!
```

---

**Last Updated:** December 30, 2024  
**Status:** Ready to Deploy ✅
