"use client";

import { collection, getDocs, query, where } from "firebase/firestore";
import { useEffect, useMemo, useState } from "react";
import { db } from "../../lib/firebase";
import { useAdminUser } from "../../components/Shell";
import type { Employee } from "../../lib/types";

export default function DepartmentsPage() {
  const { profile } = useAdminUser();
  const [employees, setEmployees] = useState<Employee[]>([]);

  useEffect(() => {
    if (!db || !profile?.companyId) return;
    const load = async () => {
      const snap = await getDocs(query(collection(db, "employees"), where("companyId", "==", profile.companyId)));
      setEmployees(snap.docs.map((item) => ({ id: item.id, ...(item.data() as Omit<Employee, "id">) })));
    };
    void load();
  }, [profile?.companyId]);

  const groups = useMemo(() => {
    const map = new Map<string, Employee[]>();
    for (const employee of employees) {
      const key = employee.department || "Unassigned";
      map.set(key, [...(map.get(key) || []), employee]);
    }
    return [...map.entries()];
  }, [employees]);

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {groups.map(([name, members]) => (
        <section key={name} className="rounded-2xl bg-white p-5 shadow-sm">
          <h2 className="font-bold">{name}</h2>
          <p className="text-sm text-slate-500">{members.length} people</p>
          <ul className="mt-3 grid gap-1 text-sm">
            {members.map((member) => (
              <li key={member.id}>{member.name} · {member.role.replaceAll("_", " ")}</li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}
