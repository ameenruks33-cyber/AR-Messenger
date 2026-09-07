import { Timestamp } from "firebase/firestore";
import type { Attendance } from "./types";

export function startOfDay(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function toDate(value: Timestamp | Date | undefined) {
  if (!value) return new Date(0);
  if (value instanceof Date) return value;
  return value.toDate();
}

export function csvEscape(value: string | number | boolean) {
  const text = String(value ?? "");
  if (text.includes(",") || text.includes("\"") || text.includes("\n")) {
    return `"${text.replaceAll("\"", "\"\"")}"`;
  }
  return text;
}

export function attendanceToRows(records: Attendance[]) {
  return records.map((record) => ({
    Employee: record.employeeName,
    Type: record.type,
    Date: record.timestamp.toISOString().slice(0, 10),
    Time: record.timestamp.toLocaleTimeString(),
    Office: record.officeName,
    Status: record.verificationStatus,
    Latitude: record.latitude,
    Longitude: record.longitude,
    MockGPS: record.mockLocation ? "yes" : "no",
    Suspicious: record.suspiciousMovement ? "yes" : "no",
    Device: record.deviceAuthorized ? "authorized" : "pending",
  }));
}

export function downloadText(filename: string, content: string, mime: string) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

export function exportCsv(records: Attendance[]) {
  const rows = attendanceToRows(records);
  const headers = Object.keys(rows[0] || { Employee: "", Type: "" });
  const csv = [
    headers.join(","),
    ...rows.map((row) => headers.map((key) => csvEscape(row[key as keyof typeof row])).join(",")),
  ].join("\n");
  downloadText(`attendance-${new Date().toISOString().slice(0, 10)}.csv`, csv, "text/csv");
}
