"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth, firebaseReady } from "../../lib/firebase";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (!auth) {
      setError("Add Firebase web keys to admin/.env.local first.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      await signInWithEmailAndPassword(auth, email, password);
      router.replace("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen grid place-items-center bg-[#075E54] p-6">
      <form onSubmit={submit} className="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl">
        <h1 className="text-2xl font-bold text-[#075E54]">AR Messenger Admin</h1>
        <p className="mt-2 text-sm text-slate-500">Sign in with an administrator email account.</p>
        {!firebaseReady && (
          <p className="mt-4 rounded-lg bg-amber-50 p-3 text-sm text-amber-800">
            Firebase is not configured. Copy admin/.env.example to .env.local.
          </p>
        )}
        <label className="mt-6 block text-sm font-medium">Email</label>
        <input className="mt-1 w-full rounded-lg border px-3 py-2" value={email} onChange={(e) => setEmail(e.target.value)} type="email" required />
        <label className="mt-4 block text-sm font-medium">Password</label>
        <input className="mt-1 w-full rounded-lg border px-3 py-2" value={password} onChange={(e) => setPassword(e.target.value)} type="password" required />
        {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
        <button disabled={loading} className="mt-6 w-full rounded-lg bg-[#128C7E] py-3 font-semibold text-white">
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </div>
  );
}
