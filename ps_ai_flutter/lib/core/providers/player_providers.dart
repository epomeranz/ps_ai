import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';
import '../services/player_service.dart';
import '../../models/player.dart';

final playerServiceProvider = Provider<PlayerService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return PlayerService(firestore);
});

final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  return ref.watch(playerServiceProvider).getPlayers();
});
