"use client";

import { collection, getDocs, query, where } from "firebase/firestore";
import { useEffect, useMemo, useState } from "react";
import * as XLSX from "xlsx";
import { jsPDF } from "jspdf";
import autoTable from "jspdf-autotable";
import { db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import type { Attendance } from "../../lib/types";
import { attendanceToRows, exportCsv, startOfDay, toDate } from "../../lib/reports";

export default function ReportsPage() {
  const { profile } = useAdminUser();
  const [records, setRecords] = useState<Attendance[]>([]);
  const [range, setRange] = useState<"daily" | "weekly" | "monthly">("daily");

  useEffect(() => {
    if (!db || !profile?.companyId) return;
    const load = async () => {
      const snap = await getDocs(query(collection(db, "attendance"), where("companyId", "==", profile.companyId)));
      setRecords(
        snap.docs.map((item) => {
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
        }),
      );
    };
    void load();
  }, [profile?.companyId]);

  const filtered = useMemo(() => {
    const now = new Date();
    const from = startOfDay(now);
    if (range === "weekly") from.setDate(from.getDate() - 7);
    if (range === "monthly") from.setDate(from.getDate() - 30);
    return records.filter((record) => record.timestamp >= from);
  }, [records, range]);

  function exportExcel() {
    const rows = attendanceToRows(filtered);
    const sheet = XLSX.utils.json_to_sheet(rows);
    const book = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(book, sheet, "Attendance");
    XLSX.writeFile(book, `attendance-${range}.xlsx`);
  }

  function exportPdf() {
    const doc = new jsPDF();
    doc.text(`AR Messenger ${range} attendance`, 14, 16);
    autoTable(doc, {
      startY: 22,
      head: [["Employee", "Type", "Date", "Office", "Status"]],
      body: filtered.map((record) => [
        record.employeeName,
        record.type,
        record.timestamp.toLocaleString(),
        record.officeName,
        record.verificationStatus,
      ]),
    });
    doc.save(`attendance-${range}.pdf`);
  }

  return (
    <div>
      <div className="flex flex-wrap gap-3 mb-6">
        {(["daily", "weekly", "monthly"] as const).map((value) => (
          <button key={value} onClick={() => setRange(value)} className={`rounded-full px-4 py-2 ${range === value ? "bg-[#075E54] text-white" : "bg-white"}`}>
            {value}
          </button>
        ))}
        <button onClick={() => exportCsv(filtered)} className="rounded-full bg-white px-4 py-2">CSV</button>
        <button onClick={exportExcel} className="rounded-full bg-white px-4 py-2">Excel</button>
        <button onClick={exportPdf} className="rounded-full bg-white px-4 py-2">PDF</button>
      </div>
      <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Employee</th>
              <th>Type</th>
              <th>Time</th>
              <th>Office</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((record) => (
              <tr key={record.id} className="border-t">
                <td className="p-3">{record.employeeName}</td>
                <td>{record.type}</td>
                <td>{record.timestamp.toLocaleString()}</td>
                <td>{record.officeName}</td>
                <td>{record.verificationStatus}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
