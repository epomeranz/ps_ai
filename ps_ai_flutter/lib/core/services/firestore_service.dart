import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_providers.dart';

/// A service class to handle Firestore operations.
/// This is wrapped in a Provider so it can be easily accessed and mocked.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  /// Example: Sync a user profile to Firestore
  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  /// Example: Stream user data
  Stream<DocumentSnapshot> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }
}

/// Provider for [FirestoreService].
/// It depends on [firestoreProvider] to get the [FirebaseFirestore] instance.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreService(firestore);
});
