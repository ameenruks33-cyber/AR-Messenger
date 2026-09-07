"use client";

import { collection, doc, getDocs, updateDoc } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { useEffect, useState } from "react";
import { db, functions } from "../../lib/firebase";
import type { Device } from "../../lib/types";

export default function DevicesPage() {
  const [devices, setDevices] = useState<Device[]>([]);

  async function load() {
    if (!db) return;
    const snap = await getDocs(collection(db, "devices"));
    setDevices(snap.docs.map((item) => ({ id: item.id, ...(item.data() as Omit<Device, "id">) })));
  }

  useEffect(() => {
    void load();
  }, []);

  async function approve(id: string) {
    if (functions) {
      await httpsCallable(functions, "authorizeDevice")({ deviceId: id });
    } else if (db) {
      await updateDoc(doc(db, "devices", id), { authorized: true });
    }
    await load();
  }

  return (
    <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
      <table className="w-full text-sm">
        <thead className="bg-slate-50 text-left">
          <tr>
            <th className="p-3">Device</th>
            <th>User</th>
            <th>Platform</th>
            <th>Authorized</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {devices.map((device) => (
            <tr key={device.id} className="border-t">
              <td className="p-3">{device.model}</td>
              <td>{device.userId}</td>
              <td>{device.platform}</td>
              <td>{device.authorized ? "Yes" : "No"}</td>
              <td>
                {!device.authorized && (
                  <button className="text-[#128C7E]" onClick={() => approve(device.id)}>Approve</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
