"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { onAuthStateChanged, signOut, type User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { useEffect, useState } from "react";
import { auth, db, firebaseReady } from "../lib/firebase";
import type { UserDoc } from "../lib/types";

const links = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/companies", label: "Companies" },
  { href: "/employees", label: "Employees" },
  { href: "/offices", label: "Offices" },
  { href: "/attendance", label: "Attendance" },
  { href: "/reports", label: "Reports" },
  { href: "/devices", label: "Devices" },
  { href: "/departments", label: "Departments" },
  { href: "/announcements", label: "Notices" },
  { href: "/settings", label: "Settings" },
];

const publicPaths = ["/", "/login"];

export function useAdminUser() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserDoc | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, async (next) => {
      setUser(next);
      if (next) {
        const snap = await getDoc(doc(db, "users", next.uid));
        const data = snap.data() || {};
        setProfile({
          id: next.uid,
          phone: String(data.phone || next.phoneNumber || ""),
          displayName: String(data.displayName || next.email || "Admin"),
          photoUrl: String(data.photoUrl || ""),
          role: (data.role || "employee") as UserDoc["role"],
          companyId: String(data.companyId || ""),
          employeeId: String(data.employeeId || ""),
        });
      } else {
        setProfile(null);
      }
      setLoading(false);
    });
  }, []);

  return { user, profile, loading, firebaseReady };
}

export default function Shell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, profile, loading } = useAdminUser();
  const isPublic = publicPaths.includes(pathname);

  useEffect(() => {
    if (!loading && !user && !isPublic) {
      router.replace("/login");
    }
  }, [loading, user, isPublic, router]);

  if (isPublic) return <>{children}</>;
  if (loading) return <div className="p-10 text-slate-500">Loading…</div>;
  if (!user) return null;

  return (
    <div className="min-h-screen bg-[#f3f6f6] text-slate-900">
      <aside className="fixed inset-y-0 left-0 w-60 bg-[#075E54] text-white p-5">
        <div className="text-lg font-bold">AR Messenger</div>
        <div className="text-xs text-emerald-100 mt-1">Admin dashboard</div>
        <nav className="mt-8 grid gap-1">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={`rounded-lg px-3 py-2 text-sm ${pathname === link.href ? "bg-white/15" : "hover:bg-white/10"}`}
            >
              {link.label}
            </Link>
          ))}
        </nav>
        <button
          className="absolute bottom-5 left-5 right-5 rounded-lg bg-black/20 px-3 py-2 text-sm"
          onClick={() => signOut(auth)}
        >
          Sign out
        </button>
      </aside>
      <main className="ml-60 p-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <div className="text-sm text-slate-500">{profile?.role?.replaceAll("_", " ")}</div>
            <h1 className="text-2xl font-bold">{profile?.displayName}</h1>
          </div>
        </div>
        {children}
      </main>
    </div>
  );
}
