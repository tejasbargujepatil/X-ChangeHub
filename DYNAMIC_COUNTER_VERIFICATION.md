# Dynamic Free Exchange Counter - Verification Guide

## 🔍 How the Dynamic Counter Works

The free exchange counter is **100% dynamic** and updates based on the user's `completedExchanges` field from their profile.

### Formula Used:
```dart
remainingFree = 3 - completedExchanges
```

### Examples:
- `completedExchanges = 0` → Shows: "You have **3** free exchanges available"
- `completedExchanges = 1` → Shows: "You have **2** free exchanges available"  
- `completedExchanges = 2` → Shows: "You have **1** free exchange available"
- `completedExchanges = 3` → Shows: "You must offer a skill" (no free exchanges)

---

## 📍 Where the Counter Appears

### 1. **Request Dialog** (`RequestExchangeDialog`)
**Location**: Info banner at bottom of dialog

**Code**:
```dart
final remainingFree = 3 - widget.completedExchanges;
'Free Exchange! You have $remainingFree free ${remainingFree == 1 ? "exchange" : "exchanges"} available.'
```

**Dynamic Variables**:
- `widget.completedExchanges` - Passed from parent, sourced from `currentUser.completedExchanges`
- `remainingFree` - Calculated in real-time

---

### 2. **Success Message** (After Sending Request)
**Location**: SnackBar after clicking "Send Request"

**Code**:
```dart
final remainingAfter = 3 - currentUser.completedExchanges - 1;
'Free exchange request sent! You have $remainingAfter free ${remainingAfter == 1 ? "exchange" : "exchanges"} left after this.'
```

**Dynamic Variables**:
- `currentUser.completedExchanges` - From AuthProvider
- `remainingAfter` - Calculated: shows count AFTER current exchange completes

---

### 3. **Error Message** (When All Used)
**Location**: SnackBar when trying to send without skills after 3 exchanges

**Code**:
```dart
'Please add skills you can teach in your profile. All free exchanges used (${currentUser.completedExchanges}/3)!'
```

**Dynamic Variables**:
- `currentUser.completedExchanges` - Should be 3 or more

---

## ✅ Testing the Dynamic Counter

### Test Scenario 1: Brand New User (0 Completed)
1. **Check**: User profile `completedExchanges = 0`
2. **Open Dialog**: Should show "You have **3** free exchanges available"
3. **Send Request**: Should show "You have **2** free exchanges left after this"
4. **After Completion**: `completedExchanges` should increment to 1

### Test Scenario 2: User with 1 Completed Exchange
1. **Check**: User profile `completedExchanges = 1`
2. **Open Dialog**: Should show "You have **2** free exchanges available"
3. **Send Request**: Should show "You have **1** free exchange left after this"
4. **After Completion**: `completedExchanges` should increment to 2

### Test Scenario 3: User with 2 Completed Exchanges (Last Free)
1. **Check**: User profile `completedExchanges = 2`
2. **Open Dialog**: Should show "You have **1** free exchange available"
3. **Send Request**: Should show "You have **0** free exchanges left after this"
4. **After Completion**: `completedExchanges` should increment to 3

### Test Scenario 4: User with 3 Completed Exchanges (No Free)
1. **Check**: User profile `completedExchanges = 3`
2. **Try to Send**: Should show error "All free exchanges used (**3**/3)!"
3. **Dialog**: Should show "You must offer a skill to learn"

---

## 🐛 Troubleshooting

### Issue: Counter always shows "3" 

**Possible Causes**:
1. `completedExchanges` not incrementing in database
2. AuthProvider not refreshing user data
3. User using cached data

**Check**:
```dart
// Add debug print in find_matches_screen.dart
print('DEBUG: Current user completedExchanges = ${currentUser.completedExchanges}');
```

**Firebase Console Check**:
1. Open Firebase Console
2. Go to Firestore
3. Find users → [userId]
4. Check `completedExchanges` field value

---

### Issue: Counter doesn't update after completion

**Cause**: `completedExchanges` only increments when exchange is marked as **COMPLETED**, not when request is sent.

**Flow**:
1. Send Request → `completedExchanges` stays same ✓
2. Tutor Accepts → `completedExchanges` stays same ✓
3. Complete Exchange → `completedExchanges` increments by 1 ✓

**To Test**:
1. Send free exchange request
2. Accept as tutor
3. Mark as complete (both parties)
4. Check if `completedExchanges` incremented in Firestore

---

## 🔧 Where Increments Happen

**File**: `lib/services/skill_exchange_service.dart`
**Method**: `completeExchange()`
**Line**: ~201-202

```dart
// Increment completed exchanges for both parties
await _userService.incrementCompletedExchanges(exchange.requesterId);
await _userService.incrementCompletedExchanges(exchange.teacherId);
```

**File**: `lib/services/user_service.dart`
**Method**: `incrementCompletedExchanges()`
**Line**: ~122-130

```dart
Future<void> incrementCompletedExchanges(String uid) async {
  try {
    await _firestore.collection('users').doc(uid).update({
      'completedExchanges': FieldValue.increment(1),
    });
  } catch (e) {
    throw Exception('Failed to update exchanges: $e');
  }
}
```

---

## 📊 Expected Results Table

| User's `completedExchanges` | Dialog Message | After Send Message | Can Send Free? |
|------------------------------|----------------|-------------------|----------------|
| 0 | "You have **3** free exchanges available" | "You have **2** free exchanges left" | ✅ Yes |
| 1 | "You have **2** free exchanges available" | "You have **1** free exchange left" | ✅ Yes |
| 2 | "You have **1** free exchange available" | "You have **0** free exchanges left" | ✅ Yes |
| 3 | "You must offer a skill" | Error: "All used (3/3)!" | ❌ No |
| 4+ | "You must offer a skill" | Error: "All used (X/3)!" | ❌ No |

---

## 🎯 Singular vs Plural

The messages now handle singular/plural correctly:

- **1 exchange**: "You have 1 free **exchange** available" (singular)
- **2+ exchanges**: "You have 2 free **exchanges** available" (plural)

**Code**:
```dart
${remainingFree == 1 ? "exchange" : "exchanges"}
```

---

## ✨ Summary

The counter IS dynamic and uses:
1. ✅ Real-time calculation: `3 - completedExchanges`
2. ✅ User's actual profile data
3. ✅ Proper singular/plural grammar
4. ✅ Clear, explicit variable names (`remainingFree`, `remainingAfter`)

If you see "3" when it should show a different number, check the user's `completedExchanges` value in Firestore! 🔍
