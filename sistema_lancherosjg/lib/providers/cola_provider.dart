import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cola_model.dart';
import 'firebase_provider.dart';
import 'rol_semanal_provider.dart';

/// Provider que observa la cola en tiempo real
final colaStreamProvider = StreamProvider<List<ColaPonton>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamCola();
});

/// Provider que filtra la cola según los pontones que trabajan hoy
final colaFiltradaProvider = StreamProvider<List<ColaPonton>>((ref) async* {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final esFinDeSemana = ref.watch(esFinDeSemanaProvider);
  
  // Calcular una sola vez al inicio los IDs del grupo activo
  Set<String>? idsPontonesHoy;
  if (!esFinDeSemana) {
    final pontonesHoy = await firebaseService.obtenerPontonesOrdenadosPorRol();
    idsPontonesHoy = pontonesHoy.map((p) => p.id).toSet();
  }
  
  // Stream de la cola completa
  await for (final cola in firebaseService.streamCola()) {
    // Si es fin de semana, mostrar todos
    if (esFinDeSemana) {
      yield cola;
    } else {
      // Si es entre semana, filtrar solo los del grupo activo
      final colaFiltrada = cola.where((c) => idsPontonesHoy!.contains(c.idPonton)).toList();
      yield colaFiltrada;
    }
  }
});

/// Provider que organiza la cola en secciones: cargando, cuadro, espera
final colaOrganizadaProvider = Provider<Map<String, List<ColaPonton>>>((ref) {
  final colaAsync = ref.watch(colaFiltradaProvider);

  return colaAsync.when(
    data: (cola) {
      if (cola.isEmpty) {
        return {
          'cargando': [],
          'cuadro': [],
          'espera': [],
        };
      }

      // Separar por estado
      final cargando = cola.where((p) => p.estado == EstadoCola.cargando).toList();
      final cuadro = cola.where((p) => p.estado == EstadoCola.cuadro).toList();
      final espera = cola.where((p) => p.estado == EstadoCola.espera).toList();

      // Si no hay ninguno marcado como cargando o cuadro, usar la lógica antigua
      if (cargando.isEmpty && cuadro.isEmpty) {
        // Primeros 5 van al cuadro
        final cuadroAutomatico = cola.take(5).toList();
        // El resto en espera
        final esperaAutomatico = cola.length > 5 ? cola.skip(5).toList() : <ColaPonton>[];
        
        return {
          'cargando': [],
          'cuadro': cuadroAutomatico,
          'espera': esperaAutomatico,
        };
      }

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
  final colaAsync = ref.watch(colaFiltradaProvider);
  return colaAsync.when(
    data: (cola) => cola.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider que verifica si ya hay pontones en la cola
final hayPontonesEnColaProvider = FutureProvider<bool>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.hayPontonesEnCola();
});
