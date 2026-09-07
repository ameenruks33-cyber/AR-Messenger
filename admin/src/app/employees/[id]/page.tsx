"use client";

import { collection, doc, getDoc, getDocs, query, where } from "firebase/firestore";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";
import { db } from "../../../lib/firebase";
import type { Attendance, Employee } from "../../../lib/types";
import { toDate } from "../../../lib/reports";

export default function EmployeeDetailPage() {
  const params = useParams<{ id: string }>();
  const [employee, setEmployee] = useState<Employee | null>(null);
  const [records, setRecords] = useState<Attendance[]>([]);

  useEffect(() => {
    if (!db || !params.id) return;
    const load = async () => {
      const snap = await getDoc(doc(db, "employees", params.id));
      if (snap.exists()) setEmployee({ id: snap.id, ...(snap.data() as Omit<Employee, "id">) });
      const att = await getDocs(query(collection(db, "attendance"), where("employeeId", "==", params.id)));
      setRecords(
        att.docs
          .map((item) => {
            const data = item.data();
            return {
              id: item.id,
              employeeId: data.employeeId,
              employeeName: data.employeeName,
              companyId: data.companyId,
              type: data.type,
              timestamp: toDate(data.timestamp),
              latitude: data.latitude,
              longitude: data.longitude,
              officeId: data.officeId,
              officeName: data.officeName,
              selfieUrl: data.selfieUrl,
              deviceId: data.deviceId,
              verificationStatus: data.verificationStatus,
              mockLocation: data.mockLocation,
              suspiciousMovement: data.suspiciousMovement,
              deviceAuthorized: data.deviceAuthorized,
            } as Attendance;
          })
          .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime()),
      );
    };
    void load();
  }, [params.id]);

  if (!employee) return <p>Loading employee…</p>;

  return (
    <div className="grid gap-6 lg:grid-cols-[320px_1fr]">
      <div className="rounded-2xl bg-white p-5 shadow-sm">
        <h2 className="text-xl font-bold">{employee.name}</h2>
        <p className="text-slate-500">{employee.phone}</p>
        <dl className="mt-4 grid gap-2 text-sm">
          <div>Department: {employee.department || "Unassigned"}</div>
          <div>Role: {employee.role.replaceAll("_", " ")}</div>
          <div>Status: {employee.status}</div>
          <div>Linked user: {employee.userId || "Not registered yet"}</div>
        </dl>
      </div>
      <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">When</th>
              <th>Type</th>
              <th>Office</th>
              <th>Verification</th>
              <th>Selfie</th>
            </tr>
          </thead>
          <tbody>
            {records.map((record) => (
              <tr key={record.id} className="border-t">
                <td className="p-3">{record.timestamp.toLocaleString()}</td>
                <td>{record.type}</td>
                <td>{record.officeName}</td>
                <td>{record.verificationStatus}</td>
                <td>{record.selfieUrl ? <a className="text-[#128C7E]" href={record.selfieUrl} target="_blank">Photo</a> : "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
