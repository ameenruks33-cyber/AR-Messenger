"use client";

import { collection, getDocs, query, where } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import type { Attendance } from "../../lib/types";
import { toDate } from "../../lib/reports";

export default function AttendancePage() {
  const { profile } = useAdminUser();
  const [records, setRecords] = useState<Attendance[]>([]);

  useEffect(() => {
    if (!db || !profile?.companyId) return;
    const load = async () => {
      const snap = await getDocs(query(collection(db, "attendance"), where("companyId", "==", profile.companyId)));
      setRecords(
        snap.docs
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
  }, [profile?.companyId]);

  return (
    <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
      <table className="w-full text-sm">
        <thead className="bg-slate-50 text-left">
          <tr>
            <th className="p-3">Employee</th>
            <th>Type</th>
            <th>Time</th>
            <th>Office</th>
            <th>GPS</th>
            <th>Flags</th>
            <th>Selfie</th>
          </tr>
        </thead>
        <tbody>
          {records.map((record) => (
            <tr key={record.id} className="border-t">
              <td className="p-3 font-medium">{record.employeeName}</td>
              <td>{record.type}</td>
              <td>{record.timestamp.toLocaleString()}</td>
              <td>{record.officeName}</td>
              <td>{record.verificationStatus}</td>
              <td>
                {record.mockLocation ? "Mock GPS " : ""}
                {record.suspiciousMovement ? "Suspicious move " : ""}
                {record.deviceAuthorized ? "Device OK" : "Device pending"}
              </td>
              <td>{record.selfieUrl ? <a className="text-[#128C7E]" href={record.selfieUrl} target="_blank">Photo</a> : "—"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
