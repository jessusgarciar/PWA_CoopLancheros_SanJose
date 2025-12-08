import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viaje_model.dart';
import 'firebase_provider.dart';
import 'cola_provider.dart';

/// Provider que observa los viajes de hoy en tiempo real
final viajesHoyStreamProvider = StreamProvider<List<Viaje>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamViajesHoy();
});

/// Provider que calcula estadísticas del día (se actualiza automáticamente)
final estadisticasHoyProvider = Provider<Map<String, dynamic>>((ref) {
  final viajesAsync = ref.watch(viajesHoyStreamProvider);
  
  return viajesAsync.when(
    data: (viajes) {
      int totalPasajeros = 0;
      double totalIngresos = 0;
      int vueltasVacias = 0;

      for (var viaje in viajes) {
        totalPasajeros += viaje.totalPasajeros;
        totalIngresos += viaje.montoCobrado;
        if (viaje.vacioAIsla) vueltasVacias++;
      }

      return {
        'totalViajes': viajes.length,
        'totalPasajeros': totalPasajeros,
        'totalIngresos': totalIngresos,
        'vueltasVacias': vueltasVacias,
        'promedioLlenado': viajes.isEmpty
            ? 0.0
            : totalPasajeros / (viajes.length - vueltasVacias).clamp(1, double.infinity),
      };
    },
    loading: () => {
      'totalViajes': 0,
      'totalPasajeros': 0,
      'totalIngresos': 0.0,
      'vueltasVacias': 0,
      'promedioLlenado': 0.0,
    },
    error: (_, __) => {
      'totalViajes': 0,
      'totalPasajeros': 0,
      'totalIngresos': 0.0,
      'vueltasVacias': 0,
      'promedioLlenado': 0.0,
    },
  );
});

/// Provider del total de vueltas completas hoy (cuando todo el grupo completó un viaje)
final totalVueltasHoyProvider = StreamProvider<int>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.streamConfiguracion().map((config) => config.vueltasCompletadasHoy);
});

/// Provider de estadísticas por pontón (se actualiza automáticamente)
final estadisticasPorPontonProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final viajesAsync = ref.watch(viajesHoyStreamProvider);
  final colaAsync = ref.watch(colaStreamProvider);
  
  return viajesAsync.when(
    data: (viajes) {
      return colaAsync.when(
        data: (cola) {
          // Agrupar viajes por pontón
          final Map<String, List<Viaje>> viajesPorPonton = {};
          for (var viaje in viajes) {
            if (!viajesPorPonton.containsKey(viaje.idPonton)) {
              viajesPorPonton[viaje.idPonton] = [];
            }
            viajesPorPonton[viaje.idPonton]!.add(viaje);
          }
          
          // Crear lista de estadísticas por pontón
          final List<Map<String, dynamic>> estadisticas = [];
          
          for (var colaPonton in cola) {
            final viajesDelPonton = viajesPorPonton[colaPonton.idPonton] ?? [];
            
            int totalPasajeros = 0;
            double totalIngresos = 0;
            int viajesVacios = 0;
            
            for (var viaje in viajesDelPonton) {
              totalPasajeros += viaje.totalPasajeros;
              totalIngresos += viaje.montoCobrado;
              if (viaje.vacioAIsla) viajesVacios++;
            }
            
            estadisticas.add({
              'idPonton': colaPonton.idPonton,
              'nombrePonton': colaPonton.nombrePonton,
              'nombreChofer': colaPonton.nombreChofer,
              'totalViajes': viajesDelPonton.length,
              'vueltasHoy': colaPonton.vueltasHoy,
              'totalPasajeros': totalPasajeros,
              'totalIngresos': totalIngresos,
              'viajesVacios': viajesVacios,
              'promedioLlenado': viajesDelPonton.isEmpty || viajesDelPonton.length == viajesVacios
                  ? 0.0
                  : totalPasajeros / (viajesDelPonton.length - viajesVacios),
              'estado': colaPonton.estado.name,
            });
          }
          
          // Ordenar por total de viajes descendente
          estadisticas.sort((a, b) => (b['totalViajes'] as int).compareTo(a['totalViajes'] as int));
          
          return estadisticas;
        },
        loading: () => [],
        error: (_, __) => [],
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
