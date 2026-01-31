import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import '../providers/firebase_providers.dart';

class TrackingRepository {
  final FirebaseFirestore _firestore;

  TrackingRepository(this._firestore);

  Future<void> saveSession(TrackingSession session) async {
    // Structure: profiles/{profileId}/sports/{sport}/exercises/{exerciseType}/sessions/{sessionId}
    final docRef = _firestore
        .collection('profiles')
        .doc(session.profileId)
        .collection('sports')
        .doc(session.sportType)
        .collection('exercises')
        .doc(session.exerciseType)
        .collection('sessions')
        .doc(session.sessionId);

    await docRef.set(session.toJson());
  }

  /// In the future, this can be updated to fetch from Firestore
  Future<List<TrackingSession>> getSavedSessions(
    String profileId,
    String sport,
    String exercise,
  ) async {
    // In the future, this can be updated to fetch and map from Firestore
    // final query = await _firestore...
    return [];
  }
}

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TrackingRepository(firestore);
});
