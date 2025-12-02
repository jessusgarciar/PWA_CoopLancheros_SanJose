import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/configuracion_model.dart';
import 'firebase_provider.dart';

/// Provider que observa la configuración del sistema
final configuracionStreamProvider = StreamProvider<Configuracion>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamConfiguracion();
});

/// Provider de precios actual
final preciosProvider = Provider<Map<String, double>>((ref) {
  final configAsync = ref.watch(configuracionStreamProvider);
  return configAsync.when(
    data: (config) => config.precios,
    loading: () => {},
    error: (_, __) => {},
  );
});
