import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore;

  SettingsService(this._firestore);

  DocumentReference<Map<String, dynamic>> _settingsDoc(String profileId) =>
      _firestore
          .collection('profiles')
          .doc(profileId)
          .collection('settings')
          .doc('app_settings');

  Stream<Map<String, dynamic>> getSettingsStream(String profileId) {
    return _settingsDoc(profileId).snapshots().map((doc) => doc.data() ?? {});
  }

  Future<void> updateSetting(
    String profileId,
    String key,
    dynamic value,
  ) async {
    await _settingsDoc(profileId).set({key: value}, SetOptions(merge: true));
  }
}
