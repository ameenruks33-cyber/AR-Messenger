"use client";

import { addDoc, collection, getDocs, query, updateDoc, doc, where } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import type { Office } from "../../lib/types";

export default function OfficesPage() {
  const { profile } = useAdminUser();
  const [offices, setOffices] = useState<Office[]>([]);
  const [form, setForm] = useState({
    name: "",
    city: "",
    latitude: "25.2048",
    longitude: "55.2708",
    radiusMeters: "150",
  });

  async function load() {
    if (!db || !profile?.companyId) return;
    const snap = await getDocs(query(collection(db, "offices"), where("companyId", "==", profile.companyId)));
    setOffices(snap.docs.map((item) => ({ id: item.id, ...(item.data() as Omit<Office, "id">) })));
  }

  useEffect(() => {
    void load();
  }, [profile?.companyId]);

  async function addOffice() {
    if (!db || !profile?.companyId) return;
    await addDoc(collection(db, "offices"), {
      companyId: profile.companyId,
      name: form.name,
      city: form.city,
      latitude: Number(form.latitude),
      longitude: Number(form.longitude),
      radiusMeters: Number(form.radiusMeters),
      attendanceEnabled: true,
    });
    setForm({ name: "", city: "", latitude: "25.2048", longitude: "55.2708", radiusMeters: "150" });
    await load();
  }

  async function toggle(office: Office) {
    if (!db) return;
    await updateDoc(doc(db, "offices", office.id), { attendanceEnabled: !office.attendanceEnabled });
    await load();
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
      <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Office</th>
              <th>City</th>
              <th>Coordinates</th>
              <th>Radius</th>
              <th>Attendance</th>
            </tr>
          </thead>
          <tbody>
            {offices.map((office) => (
              <tr key={office.id} className="border-t">
                <td className="p-3 font-medium">{office.name}</td>
                <td>{office.city}</td>
                <td>{office.latitude.toFixed(5)}, {office.longitude.toFixed(5)}</td>
                <td>{office.radiusMeters} m</td>
                <td>
                  <button className="text-[#128C7E]" onClick={() => toggle(office)}>
                    {office.attendanceEnabled ? "Enabled" : "Disabled"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <form
        className="rounded-2xl bg-white p-5 shadow-sm h-fit"
        onSubmit={(e) => {
          e.preventDefault();
          void addOffice();
        }}
      >
        <h2 className="font-bold text-lg">Add office</h2>
        <p className="text-sm text-slate-500 mt-1">Employees do not pick a city. GPS decides the office.</p>
        {(["name", "city", "latitude", "longitude", "radiusMeters"] as const).map((key) => (
          <input
            key={key}
            className="mt-3 w-full rounded-lg border px-3 py-2"
            placeholder={key}
            value={form[key]}
            onChange={(e) => setForm((current) => ({ ...current, [key]: e.target.value }))}
            required
          />
        ))}
        <button className="mt-4 w-full rounded-lg bg-[#128C7E] py-2 text-white font-semibold">Save office</button>
      </form>
    </div>
  );
}
