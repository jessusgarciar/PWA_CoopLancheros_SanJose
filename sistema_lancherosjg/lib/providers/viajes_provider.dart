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

/// Provider del total de vueltas completas hoy (cuando todo el grupo completó un viaje)
final totalVueltasHoyProvider = StreamProvider<int>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamConfiguracion().map((config) => config.vueltasCompletadasHoy);
});

/// Provider de estadísticas por pontón
final estadisticasPorPontonProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.obtenerEstadisticasPorPonton();
});
