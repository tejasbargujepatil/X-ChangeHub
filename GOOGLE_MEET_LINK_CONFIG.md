# 🎥 Google Meet Configuration

## Default Meeting Link

All skill exchanges now use a **single, shared Google Meet room**:

```
https://meet.google.com/mqd-mrrv-afq
```

---

## Why a Shared Link?

✅ **Simplicity**: No need for users to create/paste meeting links  
✅ **Consistency**: Same familiar room for everyone  
✅ **Reliability**: Link is always valid and tested  
✅ **No Typos**: Eliminates user input errors  

---

## How It Works

### 1. **Scheduling an Exchange**
- When a teacher accepts a skill exchange request
- They select date, time, and duration
- The Google Meet link is **automatically pre-filled** ✅
- Field is **read-only** - no manual editing needed

### 2. **Joining the Meeting**
- Both users see the same meeting link in their Active Exchanges
- Tap **"Join Google Meet"** button
- Opens `https://meet.google.com/mqd-mrrv-afq` in browser/app
- Join at your scheduled time!

---

## User Experience

### Schedule Dialog
```
┌─────────────────────────────────┐
│   Schedule Exchange             │
├─────────────────────────────────┤
│ Select Date: [Choose a date]    │
│ Select Time: [Choose a time]    │
│ Duration: [30, 60, 90, 120 min] │
│                                 │
│ Google Meet Link:               │
│ ┌─────────────────────────────┐ │
│ │ 🎥 meet.google.com/mqd-mrr │ │ (read-only)
│ │    v-afq                   │ │
│ └─────────────────────────────┘ │
│                                 │
│ ℹ️ All skill exchanges use this│
│   shared Google Meet room.     │
│   Join at your scheduled time! │
└─────────────────────────────────┘
```

### Active Exchange Card
```
┌─────────────────────────────────┐
│ 👤 John Doe                     │
│ Teaching: React.js              │
│ 📅 Scheduled: Jan 7, 2:00 PM    │
│                                 │
│ [Join Google Meet] [Complete]   │
└─────────────────────────────────┘
```

---

## Technical Implementation

### File: `lib/widgets/exchange_dialogs.dart`

```dart
class _ScheduleExchangeDialogState extends State<ScheduleExchangeDialog> {
  // Default Google Meet link for all exchanges
  static const String _defaultMeetLink = 'https://meet.google.com/mqd-mrrv-afq';
  
  final TextEditingController _meetLinkController = TextEditingController(
    text: _defaultMeetLink, // Pre-filled
  );
  
  // TextField is set to readOnly: true
  TextField(
    controller: _meetLinkController,
    readOnly: true, // Cannot be edited
    decoration: InputDecoration(
      hintText: 'Google Meet link',
      // ...
    ),
  )
}
```

### File: `lib/screens/exchange/exchanges_screen.dart`

The meeting link is automatically fixed for typos:
```dart
// Fix common typo: meet.googl.com -> meet.google.com
url = url.replaceAll('meet.googl.com', 'meet.google.com');
```

---

## Changing the Meeting Link

If you need to change the default meeting link in the future:

1. Open `lib/widgets/exchange_dialogs.dart`
2. Find line ~305: `static const String _defaultMeetLink = '...'`
3. Update the URL to your new Google Meet link
4. Save and hot reload the app

**Example:**
```dart
// Old
static const String _defaultMeetLink = 'https://meet.google.com/mqd-mrrv-afq';

// New
static const String _defaultMeetLink = 'https://meet.google.com/your-new-code';
```

---

## Meeting Room Management

### Current Link: `meet.google.com/mqd-mrrv-afq`

**Who created it?** This should be created by the app owner/admin  
**Account:** Should be linked to a stable Google account (e.g., your main account)

### Best Practices:
1. ✅ Use a Google Workspace account if possible (more reliable)
2. ✅ Keep the meeting room permanent (don't delete it)
3. ✅ Test the link regularly to ensure it works
4. ✅ Consider enabling waiting room for security
5. ✅ Set up meeting recording if needed for reviews

---

## Fallback & Error Handling

The app handles various scenarios:

### URL Typos
```dart
// Automatically fixes: meet.googl.com -> meet.google.com
url = url.replaceAll('meet.googl.com', 'meet.google.com');
```

### Missing http/https
```dart
if (!url.startsWith('http')) {
  url = 'https://meet.google.com/$url';
}
```

### Launch Errors
```dart
if (await canLaunchUrl(uri)) {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
} else {
  throw Exception('Could not launch meeting link');
}
```

---

## Testing Checklist

- [ ] Schedule a test exchange
- [ ] Verify default link appears automatically
- [ ] Try to edit the link (should be read-only)
- [ ] Accept the schedule
- [ ] Check Active Exchanges tab
- [ ] Tap "Join Google Meet"
- [ ] Verify it opens `meet.google.com/mqd-mrrv-afq`
- [ ] Confirm meeting room loads successfully

---

## User Benefits

✨ **Zero Configuration** - Link is automatically set  
✨ **No Mistakes** - Can't enter wrong link  
✨ **Faster Scheduling** - One less field to worry about  
✨ **Consistent Experience** - Same room every time  
✨ **Mobile Friendly** - Works on all devices  

---

## Support

If the meeting link stops working:

1. **Check the link manually** in a browser
2. **Verify the Google account** that created it is still active
3. **Create a new meeting** at `meet.google.com/new`
4. **Update the constant** in `exchange_dialogs.dart`
5. **Redeploy the app**

---

**Last Updated:** 2026-01-06  
**Default Link:** `https://meet.google.com/mqd-mrrv-afq`
