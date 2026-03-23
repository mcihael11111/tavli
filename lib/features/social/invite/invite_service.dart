/// Friend invitation service — username, QR, deep link methods.
class InviteService {
  /// Generate a game invite deep link.
  String generateDeepLink(String gameRoomId) {
    return 'https://tavli.app/join/$gameRoomId';
  }

  /// Generate QR code data for game room.
  String generateQrData(String gameRoomId) {
    return 'tavli://join/$gameRoomId';
  }

  /// Parse a QR code or deep link to extract game room ID.
  String? parseInviteLink(String link) {
    final patterns = [
      RegExp(r'tavli://join/(\w+)'),
      RegExp(r'tavli\.app/join/(\w+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(link);
      if (match != null) return match.group(1);
    }
    return null;
  }
}
