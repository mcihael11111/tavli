import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A friend in the friend list.
class Friend {
  final String uid;
  final String name;
  final DateTime addedAt;
  final bool isBlocked;
  final int headToHeadWins;
  final int headToHeadLosses;

  const Friend({
    required this.uid,
    required this.name,
    required this.addedAt,
    this.isBlocked = false,
    this.headToHeadWins = 0,
    this.headToHeadLosses = 0,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'addedAt': addedAt.toIso8601String(),
        'isBlocked': isBlocked,
        'h2hW': headToHeadWins,
        'h2hL': headToHeadLosses,
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        uid: json['uid'] as String,
        name: json['name'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
        isBlocked: json['isBlocked'] as bool? ?? false,
        headToHeadWins: json['h2hW'] as int? ?? 0,
        headToHeadLosses: json['h2hL'] as int? ?? 0,
      );

  Friend copyWith({bool? isBlocked, int? headToHeadWins, int? headToHeadLosses}) {
    return Friend(
      uid: uid,
      name: name,
      addedAt: addedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      headToHeadWins: headToHeadWins ?? this.headToHeadWins,
      headToHeadLosses: headToHeadLosses ?? this.headToHeadLosses,
    );
  }
}

/// Manages the player's friend list with persistence.
class FriendService {
  static const _key = 'tavli_friends';
  static FriendService? _instance;

  final SharedPreferences _prefs;
  final List<Friend> _friends = [];

  FriendService._(this._prefs) { _load(); }

  static Future<FriendService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = FriendService._(prefs);
    return _instance!;
  }

  static FriendService get instance {
    if (_instance == null) throw StateError('FriendService not initialized.');
    return _instance!;
  }

  List<Friend> get friends => List.unmodifiable(
      _friends.where((f) => !f.isBlocked).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  List<Friend> get blockedUsers => List.unmodifiable(
      _friends.where((f) => f.isBlocked).toList());

  void addFriend(String uid, String name) {
    if (_friends.any((f) => f.uid == uid)) return;
    _friends.add(Friend(uid: uid, name: name, addedAt: DateTime.now()));
    _save();
  }

  void removeFriend(String uid) {
    _friends.removeWhere((f) => f.uid == uid);
    _save();
  }

  void blockUser(String uid) {
    final idx = _friends.indexWhere((f) => f.uid == uid);
    if (idx >= 0) {
      _friends[idx] = _friends[idx].copyWith(isBlocked: true);
    } else {
      _friends.add(Friend(uid: uid, name: 'Blocked User', addedAt: DateTime.now(), isBlocked: true));
    }
    _save();
  }

  void unblockUser(String uid) {
    final idx = _friends.indexWhere((f) => f.uid == uid);
    if (idx >= 0) {
      _friends[idx] = _friends[idx].copyWith(isBlocked: false);
      _save();
    }
  }

  void recordResult(String opponentUid, bool won) {
    final idx = _friends.indexWhere((f) => f.uid == opponentUid);
    if (idx < 0) return;
    final f = _friends[idx];
    _friends[idx] = f.copyWith(
      headToHeadWins: won ? f.headToHeadWins + 1 : null,
      headToHeadLosses: !won ? f.headToHeadLosses + 1 : null,
    );
    _save();
  }

  bool isFriend(String uid) => _friends.any((f) => f.uid == uid && !f.isBlocked);
  bool isBlocked(String uid) => _friends.any((f) => f.uid == uid && f.isBlocked);

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    _friends.addAll(list.map((e) => Friend.fromJson(e as Map<String, dynamic>)));
  }

  void _save() {
    _prefs.setString(_key, jsonEncode(_friends.map((f) => f.toJson()).toList()));
  }
}
