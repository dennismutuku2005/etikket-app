class ApiEndpoints {
  // Configured via environment variable or defaults to backend port 4010
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:4010',
  );

  static const String login = '/api/auth/login';
  static const String tickets = '/api/tickets';
  static const String verifyTicket = '/api/tickets/verify';
  static const String organizerStats = '/api/tickets/organizer';
  static const String health = '/api/health';
}
