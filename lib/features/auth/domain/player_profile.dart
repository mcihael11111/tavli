/// Player profile stored in Firestore `players/{uid}`.
class PlayerProfile {
  final String uid;
  final String displayName;
  final int rating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final DateTime createdAt;
  final String? activeGameId;

  /// The player's selected tradition (tavli, tavla, nardy, sheshBesh).
  final String tradition;

  /// Per-tradition game stats: { 'tavli': { 'games': 10, 'wins': 6 }, ... }
  final Map<String, Map<String, int>> traditionStats;

  const PlayerProfile({
    required this.uid,
    required this.displayName,
    this.rating = 1000,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    required this.createdAt,
    this.activeGameId,
    this.tradition = 'tavli',
    this.traditionStats = const {},
  });

  PlayerProfile copyWith({
    String? displayName,
    int? rating,
    int? gamesPlayed,
    int? wins,
    int? losses,
    String? activeGameId,
    bool clearActiveGame = false,
    String? tradition,
    Map<String, Map<String, int>>? traditionStats,
  }) {
    return PlayerProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      rating: rating ?? this.rating,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      createdAt: createdAt,
      activeGameId:
          clearActiveGame ? null : (activeGameId ?? this.activeGameId),
      tradition: tradition ?? this.tradition,
      traditionStats: traditionStats ?? this.traditionStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'rating': rating,
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'losses': losses,
        'createdAt': createdAt.toIso8601String(),
        'activeGameId': activeGameId,
        'tradition': tradition,
        'traditionStats': traditionStats.map(
          (k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2, v2))),
        ),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        rating: json['rating'] as int? ?? 1000,
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        activeGameId: json['activeGameId'] as String?,
        tradition: json['tradition'] as String? ?? 'tavli',
        traditionStats: _parseTraditionStats(json['traditionStats']),
      );

  static Map<String, Map<String, int>> _parseTraditionStats(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final result = <String, Map<String, int>>{};
    for (final entry in (raw as Map<String, dynamic>).entries) {
      if (entry.value is Map) {
        result[entry.key] = (entry.value as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
        );
      }
    }
    return result;
  }

  /// Create a new profile for a first-time user.
  factory PlayerProfile.newPlayer({
    required String uid,
    required String displayName,
    String tradition = 'tavli',
  }) =>
      PlayerProfile(
        uid: uid,
        displayName: displayName,
        createdAt: DateTime.now(),
        tradition: tradition,
      );
}
