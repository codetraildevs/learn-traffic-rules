# Google Play Console - Demo Account Setup Guide

## Issue Summary

Google Play has rejected the app because **demo/guest account credentials** are missing from the App Access Declaration section in Play Console.

## Solution: Add Demo Account Credentials

Follow these steps to provide Google Play reviewers with the necessary login credentials:

### Step 1: Create a Demo Account (If Not Already Created)

#### Option A: Use Existing Demo Account (Recommended)
If you already have a demo account in your backend, skip to Step 2.

#### Option B: Create New Demo Account via API
You can create a demo account by registering a test user. The app uses **phone number + device ID** authentication.

**Demo Account Details to Create:**
- **Phone Number**: `0780494005` (or any valid 10-digit number starting with 07)
- **Device ID**: `google-play-review-device-2024` (or any unique identifier)
- **Full Name**: `Google Play Reviewer`

**How to Create:**
1. Install the app on a test device
2. Open the app and tap "Create Account"
3. Enter:
   - Full Name: `Google Play Reviewer`
   - Phone Number: `0780494005`
4. Complete registration
5. Note down the exact phone number used (this will be needed in Play Console)

### Step 2: Access Play Console App Access Declaration

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app: **Learn Traffic Rules** (`com.trafficrules.master`)
3. Navigate to: **Policy** → **App content** → **App access**
4. Click **"Manage"** or **"Add credentials"**

### Step 3: Fill in Demo Account Information

In the **App Access Declaration** form, provide:

#### For "Is all functionality available without login?"
Select: **No** (since the app requires authentication)

#### For "Account Type"
Select: **Test/demo account**

#### Demo Account Credentials

**Username/Phone Number:**
```
0780494005
```
(Replace with your actual demo phone number if different)

**Password:**
```
N/A - Phone number authentication only
```

**Additional Instructions for Reviewers:**
Copy and paste this text into the "Additional instructions" field:

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
- If login fails, please try:
  a) Registering as a new user first using "Create Account"
  b) Using phone number: 0780494005 with any device
  
ALTERNATIVE DEMO ACCOUNTS (if primary doesn't work):
- Phone: 0780494000 (Admin account - bypasses device validation)
- Phone: 0780123456 (Alternative test user account)

CONTACT SUPPORT:
If you experience any issues, contact: +250 780 494 000
```

#### Screenshots (Optional but Helpful)
If the form allows, you can attach:
- Screenshot of the login screen
- Screenshot showing where to enter phone number

### Step 4: Save and Submit

1. Review all information
2. Click **"Save"** or **"Submit"**
3. The app status will update to "Under review"

### Step 5: Resubmit Your App

1. Go to **Release** → **Production** (or your current track)
2. Review your app release
3. Click **"Review release"** or **"Send for review"**

## Alternative: Create Multiple Demo Accounts

If you want to provide multiple options for reviewers:

**Demo Account 1 (Primary):**
- Phone: `0780494005`
- Purpose: Standard user account

**Demo Account 2 (Admin - For Full Access):**
- Phone: `0780494000`
- Purpose: Admin account with bypass for device validation
- Note: This account may have additional privileges

## Troubleshooting

### Issue: "Login failed - Device mismatch"
**Solution**: Create a new account using "Create Account" button in the app. The device ID is automatically generated and bound to the account.

### Issue: "Phone number not found"
**Solution**: Make sure the demo account has been registered first using the "Create Account" option.

### Issue: Backend connection errors
**Solution**: Verify that your backend API (`https://traffic.cyangugudims.com`) is accessible and running.

## Verification Checklist

Before submitting:
- [ ] Demo account exists in your backend database
- [ ] Demo account phone number is accessible
- [ ] Demo account has been tested and can login successfully
- [ ] App Access Declaration form is completed
- [ ] Additional instructions are clear and detailed
- [ ] App has been resubmitted for review

## Expected Outcome

Once you've added the demo account credentials:
1. Google Play reviewers will be able to login
2. They can test all app features
3. Your app should be approved within 1-3 business days

## Additional Resources

- [Google Play Console Help - App Access](https://support.google.com/googleplay/android-developer/answer/9868171)
- [Google Play Policies - User Data](https://play.google.com/about/privacy-security-deception/user-data/)

---

**Need Help?**
Contact support: +250 780 494 000

