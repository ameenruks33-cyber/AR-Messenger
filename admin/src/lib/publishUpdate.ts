import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "./firebase";

export async function publishMobileUpdate(input: {
  message: string;
  companyId?: string;
  companyName?: string;
}) {
  if (!db) return;
  await setDoc(doc(db, "appUpdates", "latest"), {
    message: input.message.slice(0, 200),
    companyId: input.companyId || "",
    companyName: input.companyName || "",
    appVersion: "1.0.8",
    apkUrl: "https://ar-messenger.vercel.app/downloads/ar-messenger.apk",
    seq: Date.now(),
    updatedAt: serverTimestamp(),
  });
}
