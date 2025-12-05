import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rol_semanal_model.dart';
import '../models/ponton_model.dart';
import 'firebase_provider.dart';

/// Provider para el stream del rol semanal
final rolSemanalStreamProvider = StreamProvider<RolSemanal>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.streamRolSemanal();
});

/// Provider para obtener el orden de grupos del día actual
final ordenGruposHoyProvider = FutureProvider<List<int>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.obtenerOrdenGruposParaFecha(DateTime.now());
});

/// Provider para obtener los pontones ordenados según el rol del día
final pontonesOrdenadosHoyProvider = FutureProvider<List<Ponton>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.obtenerPontonesOrdenadosPorRol();
});

/// Provider para obtener información legible del rol actual
final infoRolActualProvider = FutureProvider<String>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.obtenerInfoRolActual();
});

/// Provider para verificar si hoy es fin de semana
final esFinDeSemanaProvider = Provider<bool>((ref) {
  final ahora = DateTime.now();
  final diaSemana = ahora.weekday;
  return diaSemana == 6 || diaSemana == 7;
});

/// Provider para calcular qué grupo trabaja hoy
final grupoTrabajoHoyProvider = FutureProvider<int>((ref) async {
  final ordenGrupos = await ref.watch(ordenGruposHoyProvider.future);
  return ordenGrupos[0]; // El primer grupo del orden semanal
});
