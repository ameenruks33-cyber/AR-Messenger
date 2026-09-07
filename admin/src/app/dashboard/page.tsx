"use client";

import { collection, getDocs, query, where } from "firebase/firestore";
import { useEffect, useMemo, useState } from "react";
import { db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import type { Attendance, Employee } from "../../lib/types";
import { startOfDay, toDate } from "../../lib/reports";

export default function DashboardPage() {
  const { profile } = useAdminUser();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [records, setRecords] = useState<Attendance[]>([]);

  useEffect(() => {
    if (!db || !profile?.companyId) return;
    const load = async () => {
      const empSnap = await getDocs(query(collection(db, "employees"), where("companyId", "==", profile.companyId)));
      setEmployees(empSnap.docs.map((docSnap) => ({ id: docSnap.id, ...(docSnap.data() as Omit<Employee, "id">) })));
      const attSnap = await getDocs(query(collection(db, "attendance"), where("companyId", "==", profile.companyId)));
      setRecords(
        attSnap.docs.map((docSnap) => {
          const data = docSnap.data();
          return {
            id: docSnap.id,
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
          };
        }),
      );
    };
    void load();
  }, [profile?.companyId]);

  const stats = useMemo(() => {
    const today = startOfDay();
    const todays = records.filter((r) => r.timestamp >= today);
    const presentIds = new Set(todays.filter((r) => r.type === "check_in").map((r) => r.employeeId));
    const late = todays.filter((r) => r.type === "check_in" && (r.timestamp.getHours() > 8 || (r.timestamp.getHours() === 8 && r.timestamp.getMinutes() > 15)));
    return {
      employees: employees.length,
      present: presentIds.size,
      absent: Math.max(employees.length - presentIds.size, 0),
      late: late.length,
      todays,
    };
  }, [employees, records]);

  return (
    <div>
      <h2 className="text-xl font-bold mb-4">Today&apos;s attendance</h2>
      <div className="grid grid-cols-4 gap-4">
        <Card label="Employees" value={stats.employees} />
        <Card label="Present" value={stats.present} />
        <Card label="Absent" value={stats.absent} />
        <Card label="Late" value={stats.late} />
      </div>
      <div className="mt-8 overflow-hidden rounded-2xl bg-white shadow-sm">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Employee</th>
              <th>Check-in</th>
              <th>Office</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {employees.map((employee) => {
              const checkIn = stats.todays.find((r) => r.employeeId === employee.id && r.type === "check_in");
              return (
                <tr key={employee.id} className="border-t">
                  <td className="p-3 font-medium">{employee.name}</td>
                  <td>{checkIn ? checkIn.timestamp.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "Absent"}</td>
                  <td>{checkIn?.officeName || "—"}</td>
                  <td>{checkIn ? "Present" : "Absent"}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Card({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-2xl bg-white p-5 shadow-sm">
      <div className="text-sm text-slate-500">{label}</div>
      <div className="mt-2 text-3xl font-bold text-[#075E54]">{value}</div>
    </div>
  );
}
