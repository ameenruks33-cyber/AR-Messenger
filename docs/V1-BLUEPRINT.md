# AR Messenger V1 blueprint

Positioning: WhatsApp-like messenger + company workspace. One phone/PIN account.

Do not build the full spec in one pass. Finish and test each module before starting the next.

## Already in the repo

- Flutter Android app + Next.js admin + Firebase
- Free phone + PIN login (Spark plan; SMS OTP needs Blaze)
- Profiles, 1:1 and group chat, photos, files, voice notes, reply
- GPS + live selfie attendance with office geofence
- Admin dashboard (employees, offices, attendance, reports)

## V1 in, V1 out

**Ship in V1:** chats, groups, media, status, communities shell, company hub, attendance, admin, notifications later.

**Not in V1:** voice/video calls, AR AI, leave, tasks, calendar, SOS, recognition, web/desktop, E2EE, face matching.

## Modules (build in this order)

| # | Module | Cursor prompt | Done when |
|---|--------|---------------|-----------|
| 0 | Auth + profile | Keep PIN login working. Do not re-enable paid SMS. | User can register, set PIN, create profile |
| 1 | WhatsApp shell | Bottom tabs: Chats, Status, Communities, Calls, Settings. Green app bar, chat list, FAB. | Navigation matches mockups |
| 2 | Chat completeness | Reply, delete, edit, star, unread, typing, read receipts | Chat feels usable daily |
| 3 | Status | 24h text/photo status, company vs personal | Users can post and view |
| 4 | Communities | Company as a community; channels map to groups | Company groups grouped, not a flat list |
| 5 | Company hub | Attendance, directory, announcements, today strip | Check-in from Company tab |
| 6 | Notifications | FCM for new messages and check-in alerts | Phone gets a notification |
| 7 | Calls (stub then WebRTC) | Keep a Calls tab; implement later | Tab exists; real calls after chat is stable |
| 8 | AR AI | Summarize, translate, draft, tasks | Only after a free/paid AI key exists |
| 9 | Leave, tasks, SOS, lock | One feature per PR | Each has its own rules + tests |

## Data (keep existing collections)

`users`, `chats`/`messages`, `companies`, `offices`, `employees`, `attendance`, `announcements`, `statuses` (new).

## Stack (do not change)

Flutter + Firebase Auth/Firestore/Storage/FCM, Next.js admin on Vercel, GitHub `AR-Messenger`.

## Next prompt after Module 1

> Implement Module 2 only: unread counts, read receipts, delete-for-me, star/important, and typing indicator. Do not add AI, calls, or leave.
