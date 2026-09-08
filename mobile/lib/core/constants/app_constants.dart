class AppConstants {
  static const appName = 'AR Messenger';
  static const defaultCountryCode = '+971';
  static const defaultRadiusMeters = 150.0;
  static const selfieMaxBytes = 2 * 1024 * 1024;
  static const messagePageSize = 40;
  static const suspiciousSpeedKmh = 400.0;
  static const workStartHour = 8;
  static const lateAfterMinutes = 15;

  static const roles = [
    'super_admin',
    'hr_admin',
    'company_admin',
    'manager',
    'employee',
  ];
}

class Collections {
  static const users = 'users';
  static const employees = 'employees';
  static const companies = 'companies';
  static const offices = 'offices';
  static const chats = 'chats';
  static const messages = 'messages';
  static const attendance = 'attendance';
  static const devices = 'devices';
  static const announcements = 'announcements';
  static const notifications = 'notifications';
  static const auditLogs = 'auditLogs';
  static const statuses = 'statuses';
}
