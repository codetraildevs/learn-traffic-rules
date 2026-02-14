# Rebrand Complete – Drive Rwanda – Prep & Pass

**Branch:** `rebrand-rwanda-driving-prep`  
**App Name:** Drive Rwanda – Prep & Pass  
**Package ID:** `com.rw.drivingprep`

---

## Before Building – You Must Configure

### 1. Backend URL (Required)

Replace `your-backend-domain.com` with your actual backend domain in:

- **File:** `lib/core/constants/app_constants.dart`
- **Search for:** `api.your-backend-domain.com`
- **Replace with:** Your real domain (e.g. `api.driverwandaprep.com` or `traffic.yourdomain.com`)

Also update:

- **File:** `android/app/src/main/res/xml/network_security_config.xml`
- **Search for:** `api.your-backend-domain.com`
- **Replace with:** Same domain as above

### 2. Developer/Publisher Name (Recommended)

Replace `Publisher Name` with the actual publisher/company name in:

- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_fr.dart`
- `lib/l10n/app_localizations_rw.dart`

Search for `Publisher Name` and replace with the new publisher's name.

### 3. New App Icon (Recommended for Full Rebrand)

Replace `assets/icons/app_logo_new.png` with a new icon design. The current icon may be recognized from the previous app. Use a fresh design that matches the new "Drive Rwanda – Prep & Pass" brand and blue color scheme (#1D4ED8).

After replacing the icon file, run:
```bash
flutter pub run flutter_launcher_icons
```

### 4. New Signing Key (Required for Release)

The new publisher must create a **new keystore** for package `com.rw.drivingprep`:

```bash
keytool -genkey -v -keystore rw-driving-prep-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Update `android/key.properties` with the new keystore path and passwords.

**Do NOT reuse the old keystore from the terminated app.**

---

## Build Commands

```bash
cd frontend
flutter clean
flutter pub get
flutter build appbundle
```

---

## Backend Deployment

Deploy the backend to your new domain with:

- SSL certificate (e.g. `certbot --nginx -d api.yourdomain.com`)
- Privacy policy at `https://api.yourdomain.com/privacy-policy`
- Terms & conditions at `https://api.yourdomain.com/terms-conditions`
- CORS configured for the new app

---

## Summary of Changes

- **Package:** `com.trafficrules.master` → `com.rw.drivingprep`
- **App Name:** Rwanda Traffic Driving School → Drive Rwanda – Prep & Pass
- **Database:** `traffic_rules.db` → `rw_driving_prep.db`
- **Version:** 1.4.0+36 → 1.0.0+1
- **Color theme:** Purple #632a9f → Blue #1D4ED8 – traffic/info signs, distinct
- **All backend URLs:** Placeholder – must be configured
- **Contact info:** Placeholder – supportEmail, supportPhone, supportPhoneRaw in AppConstants
- **Developer name:** Placeholder "Publisher Name" – should be updated
- **Debug tag:** TrafficRulesApp → DriveRwandaPrep (logs/crash reports)
- **Share hashtags:** #TrafficRules → #DriveRwanda #PrepAndPass #RwandaDriving

## Linkage Removed (Avoids Re-upload Detection)

- No codetrail.dev@gmail.com
- No traffic.cyangugudims.com
- No com.trafficrules.master
- No "Rwanda Traffic Driving School"
- No "TrafficRulesApp" in logs
- No hardcoded phone numbers (+250 788 659 575, etc.) - all use AppConstants
- Blue theme (#1D4ED8) – distinct from old purple
- User folder: free_exams_screen, payment_instructions_screen, help_support_screen updated for brand colors and contact constants
