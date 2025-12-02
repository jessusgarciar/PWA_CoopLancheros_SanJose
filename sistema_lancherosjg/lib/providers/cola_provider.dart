import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cola_model.dart';
import 'firebase_provider.dart';

/// Provider que observa la cola en tiempo real
final colaStreamProvider = StreamProvider<List<ColaPonton>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamCola();
});

/// Provider que organiza la cola en secciones: cargando, cuadro, espera
final colaOrganizadaProvider = Provider<Map<String, List<ColaPonton>>>((ref) {
  final colaAsync = ref.watch(colaStreamProvider);

  return colaAsync.when(
    data: (cola) {
      if (cola.isEmpty) {
        return {
          'cargando': [],
          'cuadro': [],
          'espera': [],
        };
      }

      // Posición 1: Cargando (el primero)
      final cargando = cola.take(1).toList();

      // Posiciones 2-6: En cuadro (5 próximos)
      final cuadro = cola.length > 1 ? cola.skip(1).take(5).toList() : <ColaPonton>[];

      // Resto: En espera
      final espera = cola.length > 6 ? cola.skip(6).toList() : <ColaPonton>[];

      return {
        'cargando': cargando,
        'cuadro': cuadro,
        'espera': espera,
      };
    },
    loading: () => {
      'cargando': [],
      'cuadro': [],
      'espera': [],
    },
    error: (_, __) => {
      'cargando': [],
      'cuadro': [],
      'espera': [],
    },
  );
});

/// Provider que retorna el total de pontones en cola
final totalPontonesEnColaProvider = Provider<int>((ref) {
  final colaAsync = ref.watch(colaStreamProvider);
  return colaAsync.when(
    data: (cola) => cola.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
