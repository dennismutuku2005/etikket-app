class ApiEndpoints {
  // Default base URL - Android Emulator points to 10.0.2.2 for host localhost,
  // or can be overridden dynamically in Settings screen.
  static const String defaultBaseUrl = 'http://10.0.2.2:5000';
  static const String defaultLocalIpUrl = 'http://192.168.1.100:5000';

  static const String login = '/api/auth/login';
  static const String tickets = '/api/tickets';
  static const String verifyTicket = '/api/tickets/verify';
  static const String organizerStats = '/api/tickets/organizer';
  static const String health = '/api/health';
}
