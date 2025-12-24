class AppConstants {
  // App Info
  static const String appName = 'Attendance Pro';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String companiesCollection = 'companies';
  static const String attendanceCollection = 'attendance';
  static const String tasksCollection = 'tasks';

  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyCorpId = 'corp_id';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyProfileImage = 'profile_image';
  static const String keyThemeMode = 'theme_mode';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxAddressLength = 200;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

class AppStrings {
  // App
  static const String appName = 'Attendance Pro';
  
  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String corpId = 'Corp ID';
  static const String userName = 'Username';
  static const String forgotPassword = 'Forgot Password?';
  static const String enableBiometric = 'Enable Biometric Login';
  static const String biometricLogin = 'Login with Biometric';

  // Registration
  static const String fullName = 'Full Name';
  static const String selectCompany = 'Select Company';
  static const String selectCorpId = 'Select Corp ID';
  static const String isAdmin = 'Register as Admin';
  static const String isSupervisor = 'Register as Supervisor';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String checkIn = 'Check In';
  static const String checkOut = 'Check Out';
  static const String attendanceHistory = 'Attendance History';
  static const String todayStatus = 'Today\'s Status';

  // Tasks
  static const String tasks = 'Tasks';
  static const String myTasks = 'My Tasks';
  static const String assignedTasks = 'Assigned Tasks';
  static const String createTask = 'Create Task';
  static const String taskTitle = 'Task Title';
  static const String taskDescription = 'Task Description';
  static const String dueDate = 'Due Date';
  static const String priority = 'Priority';
  static const String submitReport = 'Submit Report';

  // Admin
  static const String adminDashboard = 'Admin Dashboard';
  static const String companies = 'Companies';
  static const String addCompany = 'Add Company';
  static const String companyName = 'Company Name';
  static const String branch = 'Branch';
  static const String state = 'State';
  static const String city = 'City';
  static const String address = 'Address';

  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String changePhoto = 'Change Photo';
  static const String settings = 'Settings';

  // Messages
  static const String successCheckIn = 'Successfully checked in!';
  static const String successCheckOut = 'Successfully checked out!';
  static const String errorCheckIn = 'Failed to check in';
  static const String errorCheckOut = 'Failed to check out';
  static const String alreadyCheckedIn = 'Already checked in for today';
  static const String alreadyCheckedOut = 'Already checked out for today';
  static const String locationRequired = 'Location permission required';
}
