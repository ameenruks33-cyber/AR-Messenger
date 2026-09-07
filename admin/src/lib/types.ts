export type Role = "super_admin" | "hr_admin" | "company_admin" | "manager" | "employee";

export type UserDoc = {
  id: string;
  phone: string;
  displayName: string;
  photoUrl: string;
  role: Role;
  companyId: string;
  employeeId: string;
};

export type Employee = {
  id: string;
  userId: string;
  companyId: string;
  name: string;
  phone: string;
  role: Role;
  status: "pending" | "active" | "inactive";
  department: string;
  photoUrl: string;
};

export type Office = {
  id: string;
  companyId: string;
  name: string;
  city: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  attendanceEnabled: boolean;
};

export type Attendance = {
  id: string;
  employeeId: string;
  employeeName: string;
  companyId: string;
  type: "check_in" | "check_out";
  timestamp: Date;
  latitude: number;
  longitude: number;
  officeId: string;
  officeName: string;
  selfieUrl: string;
  deviceId: string;
  verificationStatus: string;
  mockLocation: boolean;
  suspiciousMovement: boolean;
  deviceAuthorized: boolean;
};

export type Device = {
  id: string;
  userId: string;
  employeeId: string;
  platform: string;
  model: string;
  authorized: boolean;
};
