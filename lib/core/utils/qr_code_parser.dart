import 'dart:convert';

class QrCodeParser {
  /// Extracts a clean ticket code from scanned QR string.
  /// Supports:
  /// - Raw string: "TKT-1042"
  /// - JSON string: '{"codes":["TKT-1042"]}' or '{"code":"TKT-1042"}' or '{"ticket_code":"TKT-1042"}'
  /// - URL containing code: "https://etikket.co.ke/tickets/TKT-1042"
  static String? extractTicketCode(String? raw) {
    if (raw == null) return null;
    String clean = raw.trim();
    if (clean.isEmpty) return null;

    // Check if JSON
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final dynamic decoded = jsonDecode(clean);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('codes') && decoded['codes'] is List) {
            final List list = decoded['codes'] as List;
            if (list.isNotEmpty) {
              return list.first.toString().trim();
            }
          }
          if (decoded.containsKey('code')) {
            return decoded['code'].toString().trim();
          }
          if (decoded.containsKey('ticket_code')) {
            return decoded['ticket_code'].toString().trim();
          }
        }
      } catch (_) {
        // Fall through to plain text extraction
      }
    }

    // Check if URL format
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      try {
        final uri = Uri.parse(clean);
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          return segments.last.trim();
        }
      } catch (_) {
        // Fallback
      }
    }

    return clean;
  }
}
