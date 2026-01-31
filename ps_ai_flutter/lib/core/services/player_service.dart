import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/player.dart';

class PlayerService {
  final FirebaseFirestore _firestore;

  PlayerService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _playersCollection =>
      _firestore.collection('players');

  Stream<List<Player>> getPlayers() {
    return _playersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addPlayer(Player player) async {
    await _playersCollection.add(player.toMap());
  }

  Future<void> deletePlayer(String id) async {
    await _playersCollection.doc(id).delete();
  }

  Stream<String?> getActivePlayerId(String sportType) {
    return _firestore
        .collection('active_players')
        .doc(sportType)
        .snapshots()
        .map((doc) => doc.data()?['playerId'] as String?);
  }

  Future<void> setActivePlayerId(String sportType, String playerId) async {
    await _firestore.collection('active_players').doc(sportType).set({
      'playerId': playerId,
    });
  }
}
