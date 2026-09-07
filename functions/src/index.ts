import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as v1 from "firebase-functions/v1";

initializeApp();
const db = getFirestore();

function toRad(value: number) {
  return (value * Math.PI) / 180;
}

function distanceMeters(lat1: number, lon1: number, lat2: number, lon2: number) {
  const earth = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  return earth * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function isAdminRole(role: string | undefined) {
  return ["super_admin", "hr_admin", "company_admin"].includes(role || "");
}

export const onAuthUserCreated = v1.auth.user().onCreate(async (user) => {
  if (!user.phoneNumber) return;
  const snap = await db.collection("employees").where("phone", "==", user.phoneNumber).limit(1).get();
  const payload: Record<string, unknown> = {
    phone: user.phoneNumber,
    displayName: user.displayName || "",
    photoUrl: "",
    about: "Available",
    role: "employee",
    companyId: "",
    employeeId: "",
    isOnline: true,
    lastSeen: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  };
  if (!snap.empty) {
    const employee = snap.docs[0];
    payload.employeeId = employee.id;
    payload.companyId = employee.get("companyId") || "";
    payload.role = employee.get("role") || "employee";
    payload.displayName = employee.get("name") || user.displayName || "";
    payload.photoUrl = employee.get("photoUrl") || "";
    await employee.ref.update({userId: user.uid, status: "active"});
  }
  await db.collection("users").doc(user.uid).set(payload, {merge: true});
});

export const onAttendanceCreated = onDocumentCreated("attendance/{attendanceId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data();
  const officeId = String(data.officeId || "");
  const officeSnap = await db.collection("offices").doc(officeId).get();
  let status = "rejected";
  let reason = "Office not found";

  if (officeSnap.exists) {
    const office = officeSnap.data()!;
    if (office.attendanceEnabled === false) {
      reason = "Attendance disabled for this office";
    } else {
      const meters = distanceMeters(
        Number(data.latitude),
        Number(data.longitude),
        Number(office.latitude),
        Number(office.longitude),
      );
      if (data.mockLocation === true) {
        reason = "Mock location detected";
      } else if (meters > Number(office.radiusMeters || 150)) {
        reason = "Outside authorized geofence";
      } else {
        status = "verified";
        reason = "Inside office geofence";
      }
    }
  }

  await snap.ref.update({
    verificationStatus: status,
    verificationReason: reason,
    verifiedAt: FieldValue.serverTimestamp(),
  });

  await db.collection("auditLogs").add({
    actorId: data.userId || "",
    action: "attendance." + String(data.type || "unknown"),
    target: event.params.attendanceId,
    createdAt: FieldValue.serverTimestamp(),
    metadata: {status, reason, officeId},
  });
});

export const onMessageCreated = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const message = snap.data();
  const chat = await db.collection("chats").doc(event.params.chatId).get();
  const memberIds: string[] = chat.get("memberIds") || [];
  const senderId = String(message.senderId || "");
  const recipients = memberIds.filter((id) => id !== senderId);
  if (recipients.length === 0) return;

  const users = await Promise.all(recipients.map((id) => db.collection("users").doc(id).get()));
  const tokens = users.map((doc) => doc.get("fcmToken")).filter((token): token is string => Boolean(token));
  if (tokens.length === 0) return;

  const preview = message.type === "text" ? String(message.text || "New message") : "New message";
  try {
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "AR Messenger",
        body: preview.slice(0, 120),
      },
      data: {
        chatId: event.params.chatId,
        type: "chat",
      },
    });
  } catch (error) {
    logger.error("FCM send failed", error);
  }
});

export const onDeviceCreated = onDocumentCreated("devices/{deviceId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data();
  const existing = await db.collection("devices").where("userId", "==", data.userId).get();
  const others = existing.docs.filter((doc) => doc.id !== event.params.deviceId);
  if (others.length === 0) {
    await snap.ref.update({authorized: true, autoAuthorized: true});
  } else if (data.authorized === true) {
    await snap.ref.update({authorized: false, needsAdminApproval: true});
  }
});

export const authorizeDevice = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const caller = await db.collection("users").doc(request.auth.uid).get();
  if (!isAdminRole(caller.get("role"))) {
    throw new HttpsError("permission-denied", "Admin only");
  }
  const deviceId = String(request.data?.deviceId || "");
  if (!deviceId) throw new HttpsError("invalid-argument", "deviceId required");
  await db.collection("devices").doc(deviceId).update({authorized: true});
  return {ok: true};
});

export const seedDemoCompany = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  if (!request.auth.token.email) {
    throw new HttpsError("permission-denied", "Only an email administrator can seed the company.");
  }
  const existing = await db.collection("companies").limit(1).get();
  if (!existing.empty && !request.data?.force) {
    return {companyId: existing.docs[0].id, seeded: false};
  }

  const companyRef = db.collection("companies").doc();
  await companyRef.set({
    name: "EA Apple",
    workStartHour: 8,
    lateAfterMinutes: 15,
    createdAt: FieldValue.serverTimestamp(),
  });

  const offices = [
    {name: "EA Apple Office", city: "Dubai", latitude: 25.2048, longitude: 55.2708},
    {name: "Sharjah Office", city: "Sharjah", latitude: 25.3463, longitude: 55.4209},
    {name: "Abu Dhabi Office", city: "Abu Dhabi", latitude: 24.4539, longitude: 54.3773},
  ];
  for (const office of offices) {
    await db.collection("offices").add({
      companyId: companyRef.id,
      ...office,
      radiusMeters: 150,
      attendanceEnabled: true,
    });
  }

  await db.collection("announcements").add({
    companyId: companyRef.id,
    title: "Company announcement",
    body: "Tomorrow's working hours: 08:00 AM – 05:00 PM. All employees must complete attendance check-in before 08:15 AM.",
    createdBy: request.auth.uid,
    createdAt: Timestamp.now(),
  });

  await db.collection("users").doc(request.auth.uid).set({
    role: "super_admin",
    companyId: companyRef.id,
  }, {merge: true});

  return {companyId: companyRef.id, seeded: true};
});
