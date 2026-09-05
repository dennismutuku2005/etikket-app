class ApiEndpoints {
  // Configured via environment variable or defaults to production backend URL
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://etikketapi.quickzingo.co.ke',
  );

  static const String login = '/api/auth/login';
  static const String tickets = '/api/tickets';
  static const String verifyTicket = '/api/tickets/verify';
  static const String organizerStats = '/api/tickets/organizer';
  static const String health = '/api/health';
}
