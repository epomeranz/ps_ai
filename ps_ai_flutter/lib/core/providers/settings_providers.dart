import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SettingsService(firestore);
});

final appSettingsProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, profileId) {
    return ref.watch(settingsServiceProvider).getSettingsStream(profileId);
  },
);

final enableUDMIProvider = Provider.family<bool, String>((ref, profileId) {
  final settingsAsync = ref.watch(appSettingsProvider(profileId));
  return settingsAsync.value?['enableUDMI'] ?? true; // Default to true
});
