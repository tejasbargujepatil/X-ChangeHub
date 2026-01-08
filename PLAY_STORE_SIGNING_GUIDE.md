# XChangeHub - Play Store Signing Configuration

## ✅ Completed Steps

### 🔐 Step 1: Upload Key Generated
- **Keystore File**: `/home/tejasbargujepatil/Desktop/XchangeHUb/android/xchangehub_upload.jks`
- **Alias**: `upload`
- **Password**: `XchangeHub2026`
- **Validity**: 10,000 days (until May 25, 2053)

**⚠️ CRITICAL**: Keep this file safe! Do NOT rename it or lose it. You'll need it for all future updates.

### 🔑 Key Fingerprints
```
SHA-1: 40:95:C2:DE:5D:0C:F7:8B:13:EC:B3:DE:F1:CA:6F:F8:21:BE:35:6E
SHA-256: 2B:30:DA:08:C9:ED:FC:31:BF:65:4F:02:C5:E2:99:F2:7C:55:46:59:91:16:5F:7E:FE:2A:66:36:FF:4C:93:B3
```

**📌 Use these SHA fingerprints for**:
- Firebase Authentication (SHA-1)
- Google Sign-In configuration
- Google Maps API key restrictions
- Play Console app signing verification

### 🛠️ Step 2: Flutter Signing Configured
- **Configuration File**: `android/key.properties`
- **Build Configuration**: `android/app/build.gradle.kts` ✅ Updated

The signing configuration has been properly set up in your build files. All release builds will now be automatically signed with your upload key.

### 🚀 Step 3: First AAB Built Successfully
- **AAB Location**: `build/app/outputs/bundle/release/app-release.aab`
- **File Size**: 47 MB
- **Build Time**: ~5 minutes
- **Status**: ✅ Ready for Play Store upload

---

## 📤 Next Steps for Play Store Submission

### 1. Upload to Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (or create a new app)
3. Navigate to **Release** → **Production** (or Internal testing first)
4. Click **Create new release**
5. Upload `app-release.aab`

### 2. App Signing by Google Play
When you upload your first AAB, Google Play will:
- Generate a separate app signing key
- Use your upload key to verify future updates
- Display the app signing certificate SHA-1 (different from upload key)

**Important**: You'll need to update Firebase with BOTH certificates:
- Upload key SHA-1 (already have this)
- App signing key SHA-1 (get from Play Console after first upload)

### 3. Update Firebase
After first upload to Play Console:
1. Go to Play Console → **Release** → **Setup** → **App signing**
2. Copy the **App signing certificate** SHA-1
3. Add it to Firebase Console → Project Settings → Your Android app
4. Download new `google-services.json`
5. Replace `android/app/google-services.json`
6. Rebuild and upload new version

---

## 🔄 Future Builds

For all future releases, simply run:
```bash
# Clean build
flutter clean

# Build release AAB
flutter build appbundle --release
```

The AAB will be automatically signed with your upload key.

---

## 🔒 Security Checklist

- [x] Upload keystore (`xchangehub_upload.jks`) is backed up safely
- [x] Keystore password is stored securely
- [x] `key.properties` is in `.gitignore` (credentials not committed)
- [ ] Backup keystore to secure cloud storage (Google Drive, Dropbox, etc.)
- [ ] Store password in password manager
- [ ] Add app signing SHA-1 to Firebase after first Play Store upload

---

## 🆘 Troubleshooting

### If you get "Key mismatch" error during upload:
- Verify you're using the same `xchangehub_upload.jks` file
- Check that `key.properties` points to the correct file path
- Ensure password in `key.properties` matches the keystore password

### To verify your current signing configuration:
```bash
cd android
keytool -list -v -keystore xchangehub_upload.jks -alias upload
# Password: XchangeHub2026
```

### To check what key signed your APK/AAB:
```bash
cd build/app/outputs/bundle/release
jarsigner -verify -verbose -certs app-release.aab
```

---

## 📋 Key Information Summary

| Item | Value |
|------|-------|
| Keystore Path | `/home/tejasbargujepatil/Desktop/XchangeHUb/android/xchangehub_upload.jks` |
| Keystore Password | `XchangeHub2026` |
| Key Alias | `upload` |
| Key Password | `XchangeHub2026` |
| Upload SHA-1 | `40:95:C2:DE:5D:0C:F7:8B:13:EC:B3:DE:F1:CA:6F:F8:21:BE:35:6E` |
| AAB Location | `build/app/outputs/bundle/release/app-release.aab` |
| App ID | `com.xchangehub.xchangehub` |

---

**🎉 Congratulations!** Your XChangeHub app is now ready for Play Store submission!
