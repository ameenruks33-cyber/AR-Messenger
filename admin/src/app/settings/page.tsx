"use client";

import { httpsCallable } from "firebase/functions";
import { useState } from "react";
import { functions } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";

export default function SettingsPage() {
  const { profile } = useAdminUser();
  const [message, setMessage] = useState("");

  async function seed() {
    if (!functions) {
      setMessage("Cloud Functions are not configured yet.");
      return;
    }
    const result = await httpsCallable(functions, "seedDemoCompany")({});
    setMessage(JSON.stringify(result.data));
  }

  return (
    <div className="max-w-xl rounded-2xl bg-white p-6 shadow-sm">
      <h2 className="text-xl font-bold">Company setup</h2>
      <p className="mt-2 text-sm text-slate-500">
        Current company: {profile?.companyId || "not linked"}. Use seed to create EA Apple with Dubai, Sharjah and Abu Dhabi offices.
      </p>
      <button onClick={seed} className="mt-6 rounded-lg bg-[#075E54] px-4 py-2 text-white">
        Seed demo company + offices
      </button>
      {message && <pre className="mt-4 whitespace-pre-wrap text-xs bg-slate-50 p-3 rounded">{message}</pre>}
    </div>
  );
}
