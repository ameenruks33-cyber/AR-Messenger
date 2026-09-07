"use client";

import { addDoc, collection, getDocs, query, where, Timestamp } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db, auth } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";

type Notice = { id: string; title: string; body: string; createdAt: Date };

export default function AnnouncementsPage() {
  const { profile } = useAdminUser();
  const [items, setItems] = useState<Notice[]>([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");

  async function load() {
    if (!db || !profile?.companyId) return;
    const snap = await getDocs(query(collection(db, "announcements"), where("companyId", "==", profile.companyId)));
    setItems(
      snap.docs.map((item) => ({
        id: item.id,
        title: String(item.get("title") || ""),
        body: String(item.get("body") || ""),
        createdAt: item.get("createdAt")?.toDate?.() || new Date(),
      })),
    );
  }

  useEffect(() => {
    void load();
  }, [profile?.companyId]);

  async function publish() {
    if (!db || !profile?.companyId || !auth?.currentUser) return;
    await addDoc(collection(db, "announcements"), {
      companyId: profile.companyId,
      title,
      body,
      createdBy: auth.currentUser.uid,
      createdAt: Timestamp.now(),
    });
    setTitle("");
    setBody("");
    await load();
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
      <div className="grid gap-4">
        {items.map((item) => (
          <article key={item.id} className="rounded-2xl bg-white p-5 shadow-sm">
            <h2 className="font-bold">{item.title}</h2>
            <p className="mt-2 whitespace-pre-wrap text-slate-600">{item.body}</p>
            <p className="mt-3 text-xs text-slate-400">{item.createdAt.toLocaleString()}</p>
          </article>
        ))}
      </div>
      <form
        className="rounded-2xl bg-white p-5 shadow-sm h-fit"
        onSubmit={(e) => {
          e.preventDefault();
          void publish();
        }}
      >
        <h2 className="font-bold text-lg">New announcement</h2>
        <input className="mt-4 w-full rounded-lg border px-3 py-2" placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} required />
        <textarea className="mt-3 w-full rounded-lg border px-3 py-2 min-h-32" placeholder="Message" value={body} onChange={(e) => setBody(e.target.value)} required />
        <button className="mt-4 w-full rounded-lg bg-[#128C7E] py-2 text-white font-semibold">Publish</button>
      </form>
    </div>
  );
}
