"use client";

import { addDoc, collection, getDocs, query, updateDoc, doc, where } from "firebase/firestore";
import Link from "next/link";
import { useEffect, useState } from "react";
import { db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import type { Employee, Role } from "../../lib/types";

export default function EmployeesPage() {
  const { profile } = useAdminUser();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("+971");
  const [department, setDepartment] = useState("");
  const [role, setRole] = useState<Role>("employee");
  const [error, setError] = useState("");

  async function load() {
    if (!db || !profile?.companyId) return;
    const snap = await getDocs(query(collection(db, "employees"), where("companyId", "==", profile.companyId)));
    setEmployees(snap.docs.map((item) => ({ id: item.id, ...(item.data() as Omit<Employee, "id">) })));
  }

  useEffect(() => {
    void load();
  }, [profile?.companyId]);

  async function addEmployee() {
    if (!db || !profile?.companyId) return;
    setError("");
    try {
      await addDoc(collection(db, "employees"), {
        userId: "",
        companyId: profile.companyId,
        name,
        phone,
        role,
        status: "active",
        department,
        photoUrl: "",
      });
      setName("");
      setPhone("+971");
      setDepartment("");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not add employee");
    }
  }

  async function setStatus(id: string, status: Employee["status"]) {
    if (!db) return;
    await updateDoc(doc(db, "employees", id), { status });
    await load();
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
      <div className="rounded-2xl bg-white shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left">
            <tr>
              <th className="p-3">Name</th>
              <th>Phone</th>
              <th>Department</th>
              <th>Role</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {employees.map((employee) => (
              <tr key={employee.id} className="border-t">
                <td className="p-3">
                  <Link className="font-medium text-[#128C7E]" href={`/employees/${employee.id}`}>{employee.name}</Link>
                </td>
                <td>{employee.phone}</td>
                <td>{employee.department || "—"}</td>
                <td>{employee.role.replaceAll("_", " ")}</td>
                <td>
                  <select value={employee.status} onChange={(e) => setStatus(employee.id, e.target.value as Employee["status"])} className="rounded border px-2 py-1">
                    <option value="active">active</option>
                    <option value="pending">pending</option>
                    <option value="inactive">inactive</option>
                  </select>
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
          void addEmployee();
        }}
      >
        <h2 className="font-bold text-lg">Add employee</h2>
        <p className="text-sm text-slate-500 mt-1">Use the same mobile number they will verify in the app.</p>
        <input className="mt-4 w-full rounded-lg border px-3 py-2" placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} required />
        <input className="mt-3 w-full rounded-lg border px-3 py-2" placeholder="Phone" value={phone} onChange={(e) => setPhone(e.target.value)} required />
        <input className="mt-3 w-full rounded-lg border px-3 py-2" placeholder="Department" value={department} onChange={(e) => setDepartment(e.target.value)} />
        <select className="mt-3 w-full rounded-lg border px-3 py-2" value={role} onChange={(e) => setRole(e.target.value as Role)}>
          <option value="employee">Employee</option>
          <option value="manager">Manager</option>
          <option value="hr_admin">HR admin</option>
          <option value="company_admin">Company admin</option>
        </select>
        {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
        <button className="mt-4 w-full rounded-lg bg-[#128C7E] py-2 text-white font-semibold">Save</button>
      </form>
    </div>
  );
}
