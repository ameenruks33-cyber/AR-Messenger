# AR Messenger

Single mobile app for WhatsApp-style messaging and company attendance.

The project lives only in `E:\Messenger`.

```text
E:\Messenger
├── mobile/       Flutter Android + iOS app
├── admin/        Next.js administrator dashboard
├── functions/    Cloud Functions for geofence, FCM, devices
├── firestore.rules
├── storage.rules
└── firebase.json
```

## What is included

### Mobile
- Phone OTP registration (Firebase Auth)
- Profile with live camera photo
- Chats, groups, images, documents, voice notes
- Delivery/read receipts, reply, edit, delete
- Company tab: check-in, check-out, history, notices
- GPS + office geofence (no manual city selection)
- Live selfie (gallery photos are not accepted for attendance)
- Mock-GPS flag, suspicious-movement flag, device authorization

### Admin
- Dashboard: present / absent / late
- Employees, offices, attendance photos
- Device approval
- Company announcements
- Daily / weekly / monthly reports with CSV, Excel, PDF export

Office matching is automatic:

Admin defines offices → employee GPS is measured → if inside the radius, attendance is allowed. If the employee is in another city, check-in is rejected.

## 1. Create a Firebase project

This repo is ready, but it is not tied to a live Firebase project yet.

1. Create a Firebase project (or give me an existing project ID).
2. Enable **Authentication** providers:
   - Phone
   - Email/Password (admin dashboard)
3. Enable **Firestore**, **Storage**, **Cloud Messaging**, and **Cloud Functions**.
4. Add Android app `com.armessenger.ar_messenger` and iOS app `com.armessenger.arMessenger`.
5. Download `google-services.json` into `mobile/android/app/` and `GoogleService-Info.plist` into `mobile/ios/Runner/`.

```bash
cd E:\Messenger\mobile
dart pub global activate flutterfire_cli
flutterfire configure --project YOUR_PROJECT_ID --platforms=android,ios --yes
```

That command overwrites `mobile/lib/firebase_options.dart`.

For Android phone OTP, add your debug SHA-1 in Firebase:

```bash
cd mobile/android
./gradlew signingReport
```

## 2. Deploy backend

```bash
cd E:\Messenger
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use YOUR_PROJECT_ID
npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage,functions
```

I've set up prototype Security Rules to keep Firestore data private to signed-in company users, stop employees changing their own role, and require pending attendance records to be verified by Cloud Functions. Review them before you share the app broadly.

## 3. Run the Flutter app

```bash
cd E:\Messenger\mobile
flutter pub get
flutter run
```

Phone flow: enter `+9715XXXXXXXX` → OTP → name + live photo → Chats / Calls / Contacts / Company.

## 4. Run the admin dashboard

```bash
cd E:\Messenger\admin
copy .env.example .env.local
```

Fill the Firebase web app keys, then:

```bash
npm install
npm run dev
```

Open http://localhost:3000

1. Create an Email/Password user in Firebase Authentication.
2. Sign in on `/login`.
3. Open **Settings** and click **Seed demo company + offices**.
   This creates EA Apple with Dubai, Sharjah and Abu Dhabi geofences (150m) and makes you `super_admin`.
4. Add employees with the exact phone numbers they will verify in the app.

When an employee registers, Cloud Functions attach their `employeeId` and `companyId` automatically.

## 5. Check-in rules

Check-in is accepted only when all of these pass:

- The phone account is linked to an active employee
- GPS is on and not mocked
- Coordinates fall inside an enabled office radius
- A live front-camera selfie is captured
- The device is authorized (first device auto-approved, later devices need admin)

Cloud Functions re-check the geofence and set `verificationStatus` to `verified` or `rejected`.

## Roles

| Feature | Employee | Manager | HR | Admin |
| --- | ---: | ---: | ---: | ---: |
| Chat | yes | yes | yes | yes |
| Own attendance | yes | yes | yes | yes |
| Team attendance | no | yes | yes | yes |
| Add employees | no | no | yes | yes |
| Add offices | no | no | no | yes |
| Reports | own | team | yes | yes |

Voice/video calls, stories, and true E2EE are deferred to later phases on purpose.
