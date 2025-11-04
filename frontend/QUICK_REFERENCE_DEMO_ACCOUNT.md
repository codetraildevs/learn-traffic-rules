# Quick Reference: Demo Account for Google Play Review

## Primary Demo Account

**Phone Number:** `0780494005`

**Authentication Method:** Phone number + Device ID (automatic)

**Password:** Not required (phone number authentication only)

---

## How to Use This Account in Play Console

1. Go to **Play Console** → Your App → **Policy** → **App content** → **App access**
2. Select **"No"** for "Is all functionality available without login?"
3. Select **"Test/demo account"** for Account Type
4. Enter phone number: **0780494005**
5. Password: **N/A - Phone number authentication only**

---

## Instructions to Copy/Paste for Reviewers

```
HOW TO LOGIN:
1. Open the app
2. Tap "Sign In" button  
3. Enter phone number: 0780494005
4. The app will automatically detect the device ID
5. Tap "Sign In" to complete login

IMPORTANT NOTES:
- This app uses phone number + device ID authentication
- No password is required
- Each device gets a unique device ID automatically
- If login fails, please try registering as a new user first using "Create Account"

ALTERNATIVE ACCOUNTS (if primary doesn't work):
- Phone: 0780494000 (Admin account - bypasses device validation)

CONTACT SUPPORT:
If you experience any issues, contact: +250 780 494 000
```

---

## Important Notes

⚠️ **Before submitting:**
- Ensure the demo account `0780494005` exists in your backend database
- Test login with this account on a test device first
- Make sure your backend API is accessible: `https://traffic.cyangugudims.com`

📱 **If account doesn't exist:**
- Register it first using the "Create Account" feature in the app
- Or create it directly in your backend database

---

For detailed setup instructions, see: `GOOGLE_PLAY_DEMO_ACCOUNT_SETUP.md`

