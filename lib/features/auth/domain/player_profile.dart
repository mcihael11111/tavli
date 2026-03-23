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

  const PlayerProfile({
    required this.uid,
    required this.displayName,
    this.rating = 1000,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    required this.createdAt,
    this.activeGameId,
  });

  PlayerProfile copyWith({
    String? displayName,
    int? rating,
    int? gamesPlayed,
    int? wins,
    int? losses,
    String? activeGameId,
    bool clearActiveGame = false,
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
      );

  /// Create a new profile for a first-time user.
  factory PlayerProfile.newPlayer({
    required String uid,
    required String displayName,
  }) =>
      PlayerProfile(
        uid: uid,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
}
