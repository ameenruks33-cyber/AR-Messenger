"use client";

import Link from "next/link";
import { useAdminUser } from "../../components/Shell";

export default function SettingsPage() {
  const { profile } = useAdminUser();
  const isAdmin =
    profile?.role === "super_admin" || profile?.role === "hr_admin" || profile?.role === "company_admin";

  return (
    <div className="max-w-xl rounded-2xl bg-white p-6 shadow-sm">
      <h2 className="text-xl font-bold">Company setup</h2>
      <p className="mt-2 text-sm text-slate-500">
        Current company: {profile?.companyId || "not linked"}. Only administrators can create, edit, or delete a company.
      </p>
      {isAdmin || profile ? (
        <Link href="/companies" className="mt-6 inline-block rounded-lg bg-[#075E54] px-4 py-2 text-white">
          Manage companies
        </Link>
      ) : null}
    </div>
  );
}
