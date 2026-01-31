import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import 'package:ps_ai_flutter/models/exercise_metadata.dart';
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
        .collection('players')
        .doc(session.activePlayerId)
        .collection('exercises')
        .doc(session.exerciseType)
        .collection('sessions')
        .doc(session.sessionId);

    await docRef.set(session.toJson());
  }

  Future<void> saveReferenceExercise(
    TrackingSession session,
    ExerciseMetadata metadata,
  ) async {
    // 1. Save metadata
    // Structure: profiles/{profileId}/sports/{sport}/custom_exercises/{exerciseId}
    final metaRef = _firestore
        .collection('profiles')
        .doc(session.profileId)
        .collection('sports')
        .doc(metadata.sportType)
        .collection('custom_exercises')
        .doc(metadata.id);

    await metaRef.set(metadata.toJson());

    // 2. Save the reference session (pose data)
    // We can save it as a subcollection 'reference_session' of the exercise document
    // or keep the standard session structure but mark it as reference.
    // Let's save it under the standard structure but we might want to link it if needed.
    // For now, let's also save it in a subcollection for easy retrieval of the "Gold Standard".
    final refSessionDoc = metaRef
        .collection('reference_sessions')
        .doc('standard');
    await refSessionDoc.set(session.toJson());

    // Also save to standard logs if desired, but user requirements said:
    // "save the post estimation to firestore under the user, sports, and excersise name"
    // The implementation above puts it under .../custom_exercises/{exerciseName}/reference_sessions/standard
    // This seems to align well.
  }

  Stream<List<ExerciseMetadata>> getCustomExercises(
    String profileId,
    String sport,
  ) {
    return _firestore
        .collection('profiles')
        .doc(profileId)
        .collection('sports')
        .doc(sport)
        .collection('custom_exercises')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ExerciseMetadata.fromJson(doc.data());
          }).toList();
        });
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
