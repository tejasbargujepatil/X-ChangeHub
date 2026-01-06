# 🎯 Google Meet Integration - Complete Setup Guide

> **⚠️ NOTICE: Simplified Approach Now Used**  
> **As of January 2026**, we're using a **default shared Google Meet link** instead of Cloud Functions.  
> **Current link:** `https://meet.google.com/mqd-mrrv-afq`  
> **See:** `GOOGLE_MEET_LINK_CONFIG.md` for the current implementation.  
> **This guide (below)** documents the Cloud Function approach for reference only.

---

## Overview

This guide will help you set up Google Meet integration for XchangeHUb using **hackersdaddy826@gmail.com** as the central meeting host account.

---

## 📋 What We've Built

### **Components Created:**

1. ✅ **Cloud Function** (`functions/index.js`)
   - Creates Google Calendar events with Meet links
   - Uses hackersdaddy826@gmail.com credentials
   - Returns Meet link to the app

2. ✅ **Flutter Service** (`lib/services/google_meet_service.dart`)
   - Calls Cloud Function from the app
   - Handles Meet link creation

3. ✅ **Updated Schedule Dialog** (`lib/widgets/exchange_dialogs.dart`)
   - Auto-creates Google Meet on scheduling
   - Shows Meet link with Google branding
   - Handles loading states and errors

---

## 🚀 Setup Steps

### **Step 1: Google Cloud Console Setup**

#### **1.1 Create/Select Project**

1. Go to: https://console.cloud.google.com
2. Select your Firebase project: **xchangehub-f61be**
   - (Or create new project if needed)

#### **1.2 Enable Google Calendar API**

1. In Cloud Console, go to: **APIs & Services** → **Library**
2. Search for: `Google Calendar API`
3. Click **Enable**

#### **1.3 Create OAuth Credentials**

1. Go to: **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. If prompted, configure OAuth consent screen:
   - User Type: **Internal** (for testing) or **External**
   - App name: **XchangeHUb**
   - User support email: **hackersdaddy826@gmail.com**
   - Developer contact: **hackersdaddy826@gmail.com**
   - Add scopes:
     - `https://www.googleapis.com/auth/calendar`
     - `https://www.googleapis.com/auth/calendar.events`
   - Save and continue

4. Create OAuth Client:
   - Application type: **Web application**
   - Name: **XchangeHUb Google Meet Integration**
   - Authorized redirect URIs: Add:
     ```
     https://developers.google.com/oauthplayground
     ```
   - Click **CREATE**

5. **Save these values:**
   ```
   Client ID: [COPY THIS]
   Client Secret: [COPY THIS]
   ```

---

### **Step 2: Get Refresh Token**

#### **2.1 Use OAuth 2.0 Playground**

1. Go to: https://developers.google.com/oauthplayground

2. Click the **Settings** (gear icon) in top right

3. Check: **Use your own OAuth credentials**

4. Enter:
   - OAuth Client ID: [Your Client ID from Step 1.3]
   - OAuth Client secret: [Your Client Secret from Step 1.3]

5. In left sidebar, under "Step 1 Select & authorize APIs":
   - Find: **Calendar API v3**
   - Check:
     - `https://www.googleapis.com/auth/calendar`
     - `https://www.googleapis.com/auth/calendar.events`

6. Click **Authorize APIs**

7. Sign in with: **hackersdaddy826@gmail.com**

8. Grant all permissions

9. After authorization, click **Exchange authorization code for tokens**

10. **Copy the Refresh Token** - You'll need this!

```
Refresh Token: [SAVE THIS - YOU'LL NEED IT!]
```

---

### **Step 3: Configure Firebase Functions**

#### **3.1 Install Firebase CLI** (if not already installed)

```bash
npm install -g firebase-tools
```

#### **3.2 Login to Firebase**

```bash
firebase login
```

#### **3.3 Initialize Functions** (if not already done)

From your project directory:

```bash
cd /home/tejasbargujepatil/Desktop/XchangeHUb
firebase init functions
```

- Select: **Use an existing project**
- Choose: **xchangehub-f61be**
- Language: **JavaScript**
- ESLint: **No** (or Yes, your choice)
- Install dependencies: **Yes**

#### **3.4 Install Dependencies**

```bash
cd functions
npm install
```

This will install:
- firebase-admin
- firebase-functions
- googleapis

#### **3.5 Set Function Configuration**

Set the Google OAuth credentials as environment variables:

```bash
# From the XchangeHUb directory
firebase functions:config:set \
  google.client_id="YOUR_CLIENT_ID" \
  google.client_secret="YOUR_CLIENT_SECRET" \
  google.refresh_token="YOUR_REFRESH_TOKEN" \
  google.redirect_uri="https://developers.google.com/oauthplayground"
```

**Replace with your actual values from Steps 1.3 and 2!**

To verify:
```bash
firebase functions:config:get
```

---

### **Step 4: Deploy Cloud Functions**

```bash
# From XchangeHUb directory
firebase deploy --only functions
```

This will deploy:
- `createGoogleMeetEvent`
- `deleteGoogleMeetEvent`

**Wait for deployment to complete!**

---

### **Step 5: Update Flutter App**

#### **5.1 Install Dependencies**

```bash
cd /home/tejasbargujepatil/Desktop/XchangeHUb
flutter pub get
```

This installs the new `cloud_functions` package.

#### **5.2 Build and Test**

```bash
flutter run
```

---

## 🧪 Testing

### **Test the Integration:**

1. **Launch app**
   ```bash
   flutter run
   ```

2. **Go to Exchanges → Pending**

3. **Accept an exchange request**

4. **Schedule dialog opens:**
   - Select date/time
   - Click "Schedule with Google Meet"
   - Should show loading indicator
   - Should create Meet link
   - Should show Google-branded success card

5. **Check Email:**
   - Both participants should receive calendar invite
   - Email contains Google Meet link

6. **Join Meeting:**
   - Click "Join Meeting" in app
   - Should open Google Meet in browser
   - NO LOBBY - direct join! ✅

---

## 📧 Email Requirements

For this to work, users MUST have email addresses in their Firebase profiles!

**Make sure your SkillExchangeModel includes:**
- `requesterEmail`
- `teacherEmail`

If not, update the model and Firestore documents.

---

## 🔧 Troubleshooting

### **Error: "Missing or insufficient permissions"**

- Check that Calendar API is enabled
- Verify refresh token is valid
- Make sure hackersdaddy826@gmail.com has granted permissions

### **Error: "Failed to create Google Meet"**

- Check Firebase Functions logs:
  ```bash
  firebase functions:log
  ```
- Verify OAuth credentials are set correctly:
  ```bash
  firebase functions:config:get
  ```

### **No email received**

- Check that user emails are correctly stored
- Verify calendar event was created (check hackersdaddy826@gmail.com calendar)
- Check spam folder

### **Meet link doesn't work**

- Verify the URL starts with `https://meet.google.com/`
- Check that event was created successfully
- Try opening in incognito/private browser

---

## 💰 Costs

### **Google Calendar API:**
- ✅ **FREE** - No cost for calendar API
- ✅ **FREE** - Google Meet included with Gmail

### **Firebase Functions:**
- ✅ **FREE TIER AVAILABLE**
- 125K invocations/month free
- Your usage: ~2 calls per exchange = ~60K/month max
- Well within free tier!

---

## 🎯 Environment Variables Summary

You need to set these in Firebase Functions config:

```javascript
{
  "google": {
    "client_id": "YOUR_GOOGLE_CLIENT_ID",
    "client_secret": "YOUR_GOOGLE_CLIENT_SECRET",
    "refresh_token": "YOUR_REFRESH_TOKEN",
    "redirect_uri": "https://developers.google.com/oauthplayground"
  }
}
```

**Command to set:**
```bash
firebase functions:config:set \
  google.client_id="..." \
  google.client_secret="..." \
  google.refresh_token="..." \
  google.redirect_uri="https://developers.google.com/oauthplayground"
```

---

## 📱 User Experience Flow

```
1. User accepts exchange
   ↓
2. Schedule dialog opens
   ↓
3. Select date/time/duration
   ↓
4. Click "Schedule with Google Meet"
   ↓
5. Loading... (calling Cloud Function)
   ↓
6. Success! Google Meet link created
   ↓
7. Both users receive calendar invite via email
   ↓
8. Exchange saved with Meet link
   ↓
9. Click "Join Meeting" → Opens Google Meet
   ↓
10. Direct join - NO LOBBY! ✅
```

---

## ✅ Verification Checklist

Before going live, verify:

- [ ] Google Calendar API enabled
- [ ] OAuth credentials created
- [ ] Refresh token obtained
- [ ] Firebase Functions config set
- [ ] Cloud Functions deployed successfully
- [ ] Flutter dependencies installed
- [ ] Test exchange scheduled
- [ ] Calendar invite received
- [ ] Meet link works
- [ ] Both users can join without lobby

---

## 🎉 Result

**Once set up:**
- ✅ Professional Google Meet links
- ✅ Automatic calendar invites
- ✅ Email notifications
- ✅ NO lobby mode
- ✅ Brand trust (Google Meet)
- ✅ Free (within limits)
- ✅ Reliable infrastructure

---

## 📞 Support

If you encounter issues:

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only createGoogleMeetEvent
   ```

2. Check Flutter console for errors

3. Verify OAuth playground has valid refresh token

4. Test calendar API directly in Cloud Console

---

**Last Updated:** December 30, 2024  
**Status:** Ready for deployment ✅  
**Central Account:** hackersdaddy826@gmail.com
