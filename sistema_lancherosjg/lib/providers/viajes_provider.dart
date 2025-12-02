import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viaje_model.dart';
import 'firebase_provider.dart';

/// Provider que observa los viajes de hoy en tiempo real
final viajesHoyStreamProvider = StreamProvider<List<Viaje>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamViajesHoy();
});

/// Provider que calcula estadísticas del día
final estadisticasHoyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.obtenerEstadisticasHoy();
});

/// Provider del total de vueltas hoy
final totalVueltasHoyProvider = Provider<int>((ref) {
  final viajesAsync = ref.watch(viajesHoyStreamProvider);
  return viajesAsync.when(
    data: (viajes) => viajes.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
