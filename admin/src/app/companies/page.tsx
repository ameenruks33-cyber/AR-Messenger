"use client";

import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import { useEffect, useMemo, useState } from "react";
import { auth, db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import { publishMobileUpdate } from "../../lib/publishUpdate";
import type { Company } from "../../lib/types";

const emptyForm = {
  name: "",
  phone: "+971",
  email: "",
  address: "",
  city: "",
  country: "United Arab Emirates",
  workStartHour: "8",
  lateAfterMinutes: "15",
  notes: "",
};

function isAdminRole(role?: string) {
  return role === "super_admin" || role === "hr_admin" || role === "company_admin";
}

function isDashboardAdminEmail(email?: string | null) {
  if (!email) return false;
  return !email.endsWith("@users.armessenger.app");
}

export default function CompaniesPage() {
  const { user, profile } = useAdminUser();
  const canManage = isAdminRole(profile?.role) || isDashboardAdminEmail(user?.email);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [form, setForm] = useState(emptyForm);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const selected = useMemo(
    () => companies.find((item) => item.id === editingId) || null,
    [companies, editingId],
  );

  async function load() {
    if (!db) return;
    const snap = await getDocs(collection(db, "companies"));
    setCompanies(
      snap.docs.map((item) => {
        const data = item.data();
        return {
          id: item.id,
          name: String(data.name || ""),
          phone: String(data.phone || ""),
          email: String(data.email || ""),
          address: String(data.address || ""),
          city: String(data.city || ""),
          country: String(data.country || ""),
          workStartHour: Number(data.workStartHour || 8),
          lateAfterMinutes: Number(data.lateAfterMinutes || 15),
          notes: String(data.notes || ""),
        };
      }),
    );
  }

  useEffect(() => {
    if (canManage) void load();
  }, [canManage]);

  function fill(company: Company) {
    setEditingId(company.id);
    setForm({
      name: company.name,
      phone: company.phone || "+971",
      email: company.email,
      address: company.address,
      city: company.city,
      country: company.country || "United Arab Emirates",
      workStartHour: String(company.workStartHour || 8),
      lateAfterMinutes: String(company.lateAfterMinutes || 15),
      notes: company.notes,
    });
    setError("");
    setMessage("");
  }

  function companyPayload() {
    return {
      name: form.name.trim(),
      phone: form.phone.trim(),
      email: form.email.trim(),
      address: form.address.trim(),
      city: form.city.trim(),
      country: form.country.trim(),
      workStartHour: Number(form.workStartHour),
      lateAfterMinutes: Number(form.lateAfterMinutes),
      notes: form.notes.trim(),
    };
  }

  async function linkAdmin(companyId: string) {
    const current = auth.currentUser;
    if (!db || !current) return;
    const ref = doc(db, "users", current.uid);
    const snap = await getDoc(ref);
    const displayName = (form.name.trim() || current.email || "Admin").slice(0, 80);
    const phone = form.phone.trim().length >= 8 ? form.phone.trim() : "+97150000000";
    if (!snap.exists()) {
      await setDoc(ref, {
        phone,
        displayName: displayName.length >= 2 ? displayName : "Admin",
        photoUrl: "",
        about: "Available",
        role: "company_admin",
        companyId,
        employeeId: "",
        isOnline: true,
        lastSeen: serverTimestamp(),
        createdAt: serverTimestamp(),
      });
      return;
    }
    const role = String(snap.data()?.role || "employee");
    await updateDoc(ref, {
      companyId,
      role: isAdminRole(role) ? role : "company_admin",
    });
  }

  async function save(event: React.FormEvent) {
    event.preventDefault();
    if (!db || !canManage) return;
    setBusy(true);
    setError("");
    setMessage("");
    try {
      const payload = companyPayload();
      if (payload.name.length < 2) throw new Error("Enter a company name.");
      if (editingId) {
        await updateDoc(doc(db, "companies", editingId), payload);
        await linkAdmin(editingId);
        await publishMobileUpdate({
          message: `${payload.name} was updated. Tap Update on your phone.`,
          companyId: editingId,
          companyName: payload.name,
        });
        setMessage("Company details updated. Phones will show an Update button.");
      } else {
        const created = await addDoc(collection(db, "companies"), {
          ...payload,
          createdAt: serverTimestamp(),
        });
        await linkAdmin(created.id);
        await publishMobileUpdate({
          message: `${payload.name} is ready. Tap Update on your phone to load it.`,
          companyId: created.id,
          companyName: payload.name,
        });
        setEditingId(created.id);
        setMessage("Company created. Open the mobile app and tap Update.");
      }
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not save company.");
    } finally {
      setBusy(false);
    }
  }

  async function remove(company: Company) {
    if (!db || !canManage) return;
    const ok = window.confirm(`Delete ${company.name}? This cannot be undone.`);
    if (!ok) return;
    setBusy(true);
    setError("");
    try {
      await deleteDoc(doc(db, "companies", company.id));
      await publishMobileUpdate({
        message: `${company.name} was deleted. Tap Update on your phone.`,
        companyId: "",
        companyName: company.name,
      });
      if (profile?.companyId === company.id && auth.currentUser) {
        await updateDoc(doc(db, "users", auth.currentUser.uid), { companyId: "" });
      }
      if (editingId === company.id) {
        setEditingId(null);
        setForm(emptyForm);
      }
      setMessage("Company deleted.");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not delete company.");
    } finally {
      setBusy(false);
    }
  }

  if (!canManage) {
    return (
      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="text-xl font-bold">Admin only</h2>
        <p className="mt-2 text-sm text-slate-500">
          Creating, editing, and deleting companies is limited to administrators.
        </p>
      </div>
    );
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_380px]">
      <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
        <div className="flex items-center justify-between p-4">
          <div>
            <h2 className="text-lg font-bold">Companies</h2>
            <p className="text-sm text-slate-500">Only admins can create, edit, or delete a company.</p>
          </div>
          <button
            className="rounded-lg bg-[#075E54] px-3 py-2 text-sm text-white"
            onClick={() => {
              setEditingId(null);
              setForm(emptyForm);
              setMessage("");
              setError("");
            }}
          >
            New company
          </button>
        </div>
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Name</th>
              <th>City</th>
              <th>Phone</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {companies.length === 0 && (
              <tr>
                <td className="p-4 text-slate-500" colSpan={4}>
                  No company yet. Create one with the form.
                </td>
              </tr>
            )}
            {companies.map((company) => (
              <tr key={company.id} className={`border-t ${profile?.companyId === company.id ? "bg-emerald-50" : ""}`}>
                <td className="p-3 font-medium">
                  {company.name}
                  {profile?.companyId === company.id ? <span className="ml-2 text-xs text-[#128C7E]">current</span> : null}
                </td>
                <td>{company.city || "—"}</td>
                <td>{company.phone || "—"}</td>
                <td className="p-3 text-right">
                  <button className="mr-3 text-[#128C7E]" onClick={() => fill(company)}>
                    Edit
                  </button>
                  <button className="text-red-600" onClick={() => void remove(company)}>
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <form className="rounded-2xl bg-white p-5 shadow-sm h-fit" onSubmit={(event) => void save(event)}>
        <h2 className="text-lg font-bold">{editingId ? "Edit company" : "Create company"}</h2>
        <p className="mt-1 text-sm text-slate-500">
          {selected ? `Editing ${selected.name}` : "Add company details, then save."}
        </p>
        {(
          [
            ["name", "Company name"],
            ["phone", "Phone"],
            ["email", "Email"],
            ["address", "Address"],
            ["city", "City"],
            ["country", "Country"],
            ["workStartHour", "Work start hour (0-23)"],
            ["lateAfterMinutes", "Late after minutes"],
          ] as const
        ).map(([key, label]) => (
          <label key={key} className="mt-3 block text-sm">
            {label}
            <input
              className="mt-1 w-full rounded-lg border px-3 py-2"
              value={form[key]}
              onChange={(event) => setForm((current) => ({ ...current, [key]: event.target.value }))}
              required={key === "name"}
            />
          </label>
        ))}
        <label className="mt-3 block text-sm">
          Notes
          <textarea
            className="mt-1 w-full rounded-lg border px-3 py-2"
            rows={3}
            value={form.notes}
            onChange={(event) => setForm((current) => ({ ...current, notes: event.target.value }))}
          />
        </label>
        {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
        {message && <p className="mt-3 text-sm text-emerald-700">{message}</p>}
        <button disabled={busy} className="mt-4 w-full rounded-lg bg-[#128C7E] py-2 font-semibold text-white">
          {busy ? "Saving…" : editingId ? "Save changes" : "Create company"}
        </button>
      </form>
    </div>
  );
}
