import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/ponton_model.dart';
import '../models/cola_model.dart';
import '../models/viaje_model.dart';
import '../models/configuracion_model.dart';
import '../models/rol_semanal_model.dart';

/// Servicio principal que maneja todas las operaciones con Firebase
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Referencias a colecciones
  CollectionReference get _pontonesRef => _firestore.collection('pontones');
  CollectionReference get _colaRef => _firestore.collection('cola_servicio');
  CollectionReference get _viajesRef => _firestore.collection('historial_viajes');
  DocumentReference get _configRef =>
      _firestore.collection('configuracion').doc('general');
  DocumentReference get _rolSemanalRef =>
      _firestore.collection('configuracion').doc('rol_semanal');

  /// ============ INICIALIZACIÓN DEL SISTEMA ============

  /// Inicializar la base de datos con los 28 pontones del rol
  Future<void> inicializarSistema() async {
    try {
      // Verificar si ya está inicializado
      final configDoc = await _configRef.get();
      if (configDoc.exists) {
        print('Sistema ya inicializado');
        return;
      }

      // Crear configuración inicial
      final configInicial = Configuracion.porDefecto();
      await _configRef.set(configInicial.toFirestore());

      // Crear configuración del rol semanal
      final rolSemanal = RolSemanal.porDefecto();
      await _rolSemanalRef.set(rolSemanal.toFirestore());

      // Crear los 28 pontones según el rol de la imagen
      final pontones = _crearPontonesDelRol();
      final batch = _firestore.batch();

      for (var ponton in pontones) {
        batch.set(_pontonesRef.doc(ponton.id), ponton.toFirestore());
      }

      await batch.commit();
      
      // Agregar automáticamente los pontones del grupo activo a la cola
      await agregarPontonesActivosACola();
      
      print('✅ Sistema inicializado con éxito');
    } catch (e) {
      print('❌ Error al inicializar sistema: $e');
      rethrow;
    }
  }

  /// Verificar si ya hay pontones en la cola
  Future<bool> hayPontonesEnCola() async {
    try {
      final snapshot = await _colaRef.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar cola: $e');
      return false;
    }
  }

  /// Agregar los pontones del grupo activo a la cola de servicio
  Future<void> agregarPontonesActivosACola() async {
    try {
      // Obtener pontones que trabajan hoy según el rol
      final pontonesHoy = await obtenerPontonesOrdenadosPorRol();
      
      // Verificar cuáles ya están en cola
      final snapshot = await _colaRef.get();
      final idsEnCola = snapshot.docs.map((doc) => doc.id).toSet();
      
      // Filtrar solo los que NO están en cola
      final pontonesNuevos = pontonesHoy.where((p) => !idsEnCola.contains(p.id)).toList();
      
      if (pontonesNuevos.isEmpty) {
        print('ℹ️ Todos los pontones del grupo ya están en servicio');
        return;
      }
      
      print('📋 Agregando ${pontonesNuevos.length} pontones nuevos a la cola...');
      
      final batch = _firestore.batch();
      final ahora = Timestamp.now();
      
      for (var i = 0; i < pontonesNuevos.length; i++) {
        final ponton = pontonesNuevos[i];
        
        // Agregar a la cola con un pequeño offset en el timestamp para mantener el orden
        batch.set(_colaRef.doc(ponton.id), {
          'nombrePonton': ponton.nombre,
          'nombreChofer': ponton.nombreChofer ?? 'Sin asignar',
          'fechaIngreso': Timestamp.fromMillisecondsSinceEpoch(
            ahora.millisecondsSinceEpoch + i
          ),
          'estado': EstadoCola.espera.name,
          'vueltasHoy': 0,
        });
      }
      
      await batch.commit();
      print('✅ ${pontonesNuevos.length} pontones agregados a la cola');
    } catch (e) {
      print('❌ Error al agregar pontones a la cola: $e');
      rethrow;
    }
  }
  
  /// Verificar si es un nuevo día y resetear el contador de vueltas
  Future<void> verificarYResetearContadorDiario() async {
    try {
      final configDoc = await _configRef.get();
      if (!configDoc.exists) return;
      
      final config = Configuracion.fromFirestore(configDoc);
      final ahora = DateTime.now();
      
      // Si no hay fecha registrada o es un día diferente, resetear
      if (config.fechaUltimaVuelta == null || 
          !_esElMismoDia(config.fechaUltimaVuelta!, ahora)) {
        await _configRef.update({
          'vueltasCompletadasHoy': 0,
          'fechaUltimaVuelta': null,
        });
        print('🔄 Contador de vueltas reseteado para nuevo día');
      }
    } catch (e) {
      print('⚠️ Error al verificar contador diario: $e');
    }
  }
  
  /// Verificar si dos fechas son del mismo día
  bool _esElMismoDia(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
           fecha1.month == fecha2.month &&
           fecha1.day == fecha2.day;
  }

  /// Crear los 28 pontones según la imagen del rol
  List<Ponton> _crearPontonesDelRol() {
    // Nombres extraídos directamente de la imagen
    final nombresGrupo1 = [
      'VAGABUNDO',
      'PINTA',
      'NIÑA',
      'SOÑADOR',
      'PELICANO',
      'RANA',
      'ORIGINAL'
    ];
    final nombresGrupo2 = [
      'TIBURON',
      'PITUFO',
      'RIO BLANCO',
      'PINGUINO',
      'SOL',
      'ALONDRA',
      'SPIRIT'
    ];
    final nombresGrupo3 = [
      'DIANA',
      'DELFIN',
      'COLORAO',
      'ASTRO',
      'ALBORADA',
      'LUCHIN',
      'MARLIN'
    ];
    final nombresGrupo4 = [
      'MORE',
      'SANTA MARIA',
      'ALCON',
      'COMETA',
      'COMUNERO',
      'GARZA',
      'RODOLFO'
    ];

    final List<Ponton> pontones = [];
    int numeroGlobal = 1;

    for (int grupo = 1; grupo <= 4; grupo++) {
      final nombres = grupo == 1
          ? nombresGrupo1
          : grupo == 2
              ? nombresGrupo2
              : grupo == 3
                  ? nombresGrupo3
                  : nombresGrupo4;

      for (int i = 0; i < nombres.length; i++) {
        pontones.add(Ponton(
          id: numeroGlobal.toString(),
          nombre: nombres[i],
          grupo: grupo,
          ordenEnGrupo: i + 1,
        ));
        numeroGlobal++;
      }
    }

    return pontones;
  }

  /// ============ GESTIÓN DE LA COLA ============

  /// Stream de la cola en tiempo real (ordenada por antigüedad)
  Stream<List<ColaPonton>> streamCola() {
    return _colaRef
        .orderBy('fechaIngreso')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ColaPonton.fromFirestore(doc))
            .toList());
  }

  /// Agregar pontón a la cola
  Future<void> agregarACola(String idPonton, String nombreChofer) async {
    try {
      final pontonDoc = await _pontonesRef.doc(idPonton).get();
      if (!pontonDoc.exists) {
        throw Exception('Pontón no encontrado');
      }

      final ponton = Ponton.fromFirestore(pontonDoc);

      // Verificar si ya está en cola
      final yaEnCola = await _colaRef.doc(idPonton).get();
      if (yaEnCola.exists) {
        throw Exception('Este pontón ya está en la cola');
      }

      await _colaRef.doc(idPonton).set({
        'nombrePonton': ponton.nombre,
        'nombreChofer': nombreChofer,
        'fechaIngreso': Timestamp.now(),
        'estado': EstadoCola.espera.name,
        'vueltasHoy': 0,
      });

      print('✅ Pontón ${ponton.nombre} agregado a la cola');
    } catch (e) {
      print('❌ Error al agregar a cola: $e');
      rethrow;
    }
  }

  /// Mover pontón al final de la cola (después de completar viaje)
  Future<void> reingresarACola(String idPonton) async {
    try {
      final colaDoc = await _colaRef.doc(idPonton).get();
      if (!colaDoc.exists) return;

      final cola = ColaPonton.fromFirestore(colaDoc);

      // Actualizar con nueva fecha para ir al final
      await _colaRef.doc(idPonton).update({
        'fechaIngreso': Timestamp.now(),
        'estado': EstadoCola.espera.name,
        'vueltasHoy': cola.vueltasHoy + 1,
      });

      print('✅ Pontón reingresado al final de la cola');
    } catch (e) {
      print('❌ Error al reingresar a cola: $e');
      rethrow;
    }
  }

  /// Actualizar estado del pontón (cargando, cuadro, espera)
  Future<void> actualizarEstadoCola(String idPonton, EstadoCola estado) async {
    try {
      await _colaRef.doc(idPonton).update({
        'estado': estado.name,
      });
    } catch (e) {
      print('❌ Error al actualizar estado: $e');
      rethrow;
    }
  }

  /// Marcar pontón como cargando (puede haber múltiples)
  Future<void> marcarComoCargando(String idPonton) async {
    await actualizarEstadoCola(idPonton, EstadoCola.cargando);
    print('🚤 Pontón marcado como CARGANDO');
  }

  /// Marcar pontón como en cuadro
  Future<void> marcarComoCuadro(String idPonton) async {
    await actualizarEstadoCola(idPonton, EstadoCola.cuadro);
    print('📋 Pontón marcado como EN CUADRO');
  }

  /// Obtener todos los pontones que están cargando actualmente
  Future<List<ColaPonton>> obtenerPontonesCargando() async {
    try {
      final snapshot = await _colaRef
          .where('estado', isEqualTo: EstadoCola.cargando.name)
          .get();
      return snapshot.docs.map((doc) => ColaPonton.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error al obtener pontones cargando: $e');
      return [];
    }
  }

  /// Remover pontón de la cola (por falla mecánica, perdió vuelta, etc.)
  Future<void> removerDeCola(String idPonton, String motivo) async {
    try {
      await _colaRef.doc(idPonton).delete();
      await _pontonesRef.doc(idPonton).update({
        'disponible': false,
        'motivoNoDisponible': motivo,
      });

      print('✅ Pontón removido de cola: $motivo');
    } catch (e) {
      print('❌ Error al remover de cola: $e');
      rethrow;
    }
  }

  /// ============ REGISTRO DE VIAJES (LA TABLA) ============

  /// Registrar un viaje completado
  Future<void> registrarViaje(Viaje viaje) async {
    try {
      // Guardar viaje en historial
      await _viajesRef.add(viaje.toFirestore());

      // Reingresar pontón al final de la cola
      await reingresarACola(viaje.idPonton);

      // Verificar si todos los pontones del grupo activo completaron un viaje
      await _verificarVueltaCompleta();

      print('✅ Viaje registrado correctamente');
    } catch (e) {
      print('❌ Error al registrar viaje: $e');
      rethrow;
    }
  }
  
  /// Verificar si todos los pontones del grupo activo completaron un viaje
  /// Si es así, incrementar el contador de vueltas completas
  Future<void> _verificarVueltaCompleta() async {
    try {
      // Obtener pontones del grupo activo
      final pontonesActivos = await obtenerPontonesOrdenadosPorRol();
      final idsActivos = pontonesActivos.map((p) => p.id).toSet();
      
      // Obtener todos los viajes de hoy
      final ahora = DateTime.now();
      final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
      
      final viajesSnapshot = await _viajesRef
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .get();
      
      // Agrupar viajes por pontón (solo contar los del grupo activo)
      final Map<String, int> viajesPorPonton = {};
      for (var doc in viajesSnapshot.docs) {
        final viaje = Viaje.fromFirestore(doc);
        if (idsActivos.contains(viaje.idPonton)) {
          viajesPorPonton[viaje.idPonton] = (viajesPorPonton[viaje.idPonton] ?? 0) + 1;
        }
      }
      
      // Verificar si todos los pontones activos tienen al menos un viaje
      final todosCompletaron = idsActivos.every((id) => (viajesPorPonton[id] ?? 0) > 0);
      
      if (todosCompletaron) {
        // Encontrar el mínimo de viajes entre todos los pontones
        final minViajes = viajesPorPonton.values.reduce((a, b) => a < b ? a : b);
        
        // Actualizar el contador global de vueltas
        final configDoc = await _configRef.get();
        
        if (configDoc.exists) {
          final config = Configuracion.fromFirestore(configDoc);
          
          // Solo actualizar si el número de vueltas cambió
          if (minViajes > config.vueltasCompletadasHoy) {
            await _configRef.update({
              'vueltasCompletadasHoy': minViajes,
              'fechaUltimaVuelta': Timestamp.now(),
            });
            print('🎉 ¡Vuelta completa #$minViajes del grupo completada!');
          }
        }
      }
    } catch (e) {
      print('⚠️ Error al verificar vuelta completa: $e');
      // No lanzar error para no afectar el registro del viaje
    }
  }

  /// Registrar ida vacía a la isla
  Future<void> registrarIdaVacia(String idPonton) async {
    try {
      final pontonDoc = await _pontonesRef.doc(idPonton).get();
      final ponton = Ponton.fromFirestore(pontonDoc);

      final colaDoc = await _colaRef.doc(idPonton).get();
      final cola = ColaPonton.fromFirestore(colaDoc);

      final viaje = Viaje(
        id: '',
        fecha: DateTime.now(),
        idPonton: idPonton,
        nombrePonton: ponton.nombre,
        nombreChofer: cola.nombreChofer,
        desglosePasajeros: {},
        finanzas: {'calculado': 0, 'cobrado_real': 0, 'nota': 'Ida vacía a isla'},
        vacioAIsla: true,
        numeroVuelta: cola.vueltasHoy + 1,
      );

      await registrarViaje(viaje);
    } catch (e) {
      print('❌ Error al registrar ida vacía: $e');
      rethrow;
    }
  }

  /// Calcular monto según pasajeros y precios
  Future<double> calcularMontoViaje(Map<String, int> desglosePasajeros) async {
    final configDoc = await _configRef.get();
    final config = Configuracion.fromFirestore(configDoc);

    double total = 0;
    desglosePasajeros.forEach((tipo, cantidad) {
      total += config.getPrecio(tipo) * cantidad;
    });

    return total;
  }

  /// ============ CONSULTAS Y ESTADÍSTICAS ============

  /// Obtener pontones que deben trabajar hoy según el rol
  Future<List<Ponton>> obtenerPontonesDelDia() async {
    final gruposActivos = _calcularGruposActivos(DateTime.now());

    final pontonesQuery = await _pontonesRef
        .where('grupo', whereIn: gruposActivos)
        .where('disponible', isEqualTo: true)
        .get();

    return pontonesQuery.docs.map((doc) => Ponton.fromFirestore(doc)).toList();
  }

  /// Calcular qué grupos trabajan según el día de la semana
  List<int> _calcularGruposActivos(DateTime fecha) {
    final diaSemana = fecha.weekday;

    // Sábado y Domingo: TODOS los grupos
    if (diaSemana == DateTime.saturday || diaSemana == DateTime.sunday) {
      return [1, 2, 3, 4];
    }

    // Entre semana: rotación diaria
    // TODO: Implementar lógica de feriados y días especiales
    switch (diaSemana) {
      case DateTime.monday:
        return [1]; // Grupo 1 (pontones 1-7)
      case DateTime.tuesday:
        return [2]; // Grupo 2 (pontones 8-14)
      case DateTime.wednesday:
        return [3]; // Grupo 3 (pontones 15-21)
      case DateTime.thursday:
        return [4]; // Grupo 4 (pontones 22-28)
      case DateTime.friday:
        return [1]; // Grupo 1 de nuevo
      default:
        return [1];
    }
  }

  /// Obtener viajes de hoy
  Stream<List<Viaje>> streamViajesHoy() {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    return _viajesRef
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDelDia))
        .where('fecha', isLessThan: Timestamp.fromDate(finDelDia))
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Viaje.fromFirestore(doc)).toList());
  }

  /// Obtener total de vueltas hoy
  Future<int> obtenerTotalVueltasHoy() async {
    final configDoc = await _configRef.get();
    if (configDoc.exists) {
      final config = Configuracion.fromFirestore(configDoc);
      return config.vueltasCompletadasHoy;
    }
    return 0;
  }

  /// Obtener estadísticas del día
  Future<Map<String, dynamic>> obtenerEstadisticasHoy() async {
    final viajes = await streamViajesHoy().first;

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
          : totalPasajeros / (viajes.length - vueltasVacias),
    };
  }
  
  /// Obtener estadísticas por pontón para el día
  Future<List<Map<String, dynamic>>> obtenerEstadisticasPorPonton() async {
    final viajes = await streamViajesHoy().first;
    final cola = await streamCola().first;
    
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
  }

  /// ============ NOTIFICACIONES PUSH ============

  /// Configurar notificaciones para un lanchero
  Future<void> configurarNotificaciones(String idPonton) async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging.getToken();

      if (token != null) {
        await _pontonesRef.doc(idPonton).update({
          'fcmToken': token,
        });
        print('✅ Token FCM guardado');
      }
    } catch (e) {
      print('❌ Error al configurar notificaciones: $e');
    }
  }

  /// Enviar notificación cuando está próximo a entrar
  Future<void> notificarProximoTurno(String idPonton) async {
    // TODO: Implementar con Cloud Functions
    // Enviar notificación push usando FCM
    print('📲 Notificación enviada a pontón $idPonton');
  }

  /// ============ GESTIÓN DEL ROL ============

  /// Rotar el rol semanalmente (grupo 1 al final, todos suben)
  Future<void> rotarRolSemanal() async {
    try {
      final pontonesSnapshot = await _pontonesRef.get();
      final batch = _firestore.batch();

      for (var doc in pontonesSnapshot.docs) {
        final ponton = Ponton.fromFirestore(doc);

        // El grupo 4 pasa a ser grupo 1, los demás suben
        int nuevoGrupo = ponton.grupo == 4 ? 1 : ponton.grupo + 1;

        batch.update(doc.reference, {'grupo': nuevoGrupo});
      }

      // Actualizar fecha de último cambio
      batch.update(_configRef, {
        'ultimoCambioRol': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('✅ Rol rotado correctamente');
    } catch (e) {
      print('❌ Error al rotar rol: $e');
      rethrow;
    }
  }

  /// ============ CONFIGURACIÓN ============

  /// Obtener configuración actual
  Future<Configuracion> obtenerConfiguracion() async {
    final doc = await _configRef.get();
    if (!doc.exists) {
      return Configuracion.porDefecto();
    }
    return Configuracion.fromFirestore(doc);
  }

  /// Stream de configuración
  Stream<Configuracion> streamConfiguracion() {
    return _configRef.snapshots().map((doc) {
      if (!doc.exists) return Configuracion.porDefecto();
      return Configuracion.fromFirestore(doc);
    });
  }

  /// Actualizar precios
  Future<void> actualizarPrecios(Map<String, double> nuevosPrecios) async {
    await _configRef.update({'precios': nuevosPrecios});
  }

  /// ============ GESTIÓN DEL ROL SEMANAL ============

  /// Obtener configuración del rol semanal actual
  Future<RolSemanal> obtenerRolSemanal() async {
    final doc = await _rolSemanalRef.get();
    if (!doc.exists) {
      return RolSemanal.porDefecto();
    }
    return RolSemanal.fromFirestore(doc);
  }

  /// Stream del rol semanal
  Stream<RolSemanal> streamRolSemanal() {
    return _rolSemanalRef.snapshots().map((doc) {
      if (!doc.exists) return RolSemanal.porDefecto();
      return RolSemanal.fromFirestore(doc);
    });
  }

  /// Actualizar configuración del rol semanal
  Future<void> actualizarRolSemanal(RolSemanal rolSemanal) async {
    await _rolSemanalRef.set(rolSemanal.toFirestore());
  }

  /// Obtener el orden de grupos para una fecha específica
  Future<List<int>> obtenerOrdenGruposParaFecha(DateTime fecha) async {
    final rol = await obtenerRolSemanal();
    return rol.calcularOrdenParaFecha(fecha);
  }

  /// Obtener pontones ordenados según el rol semanal del día
  Future<List<Ponton>> obtenerPontonesOrdenadosPorRol({DateTime? fecha}) async {
    final fechaConsulta = fecha ?? DateTime.now();
    final rol = await obtenerRolSemanal();
    final ordenGrupos = rol.calcularOrdenParaFecha(fechaConsulta);
    
    // Obtener todos los pontones
    final snapshot = await _pontonesRef.get();
    final todosPontones = snapshot.docs
        .map((doc) => Ponton.fromFirestore(doc))
        .toList();

    // FINES DE SEMANA (Sábado y Domingo): Todos los pontones trabajan (28 pontones)
    if (rol.esFinDeSemana(fechaConsulta)) {
      // Ordenar por grupo según el orden semanal, luego por orden dentro del grupo
      todosPontones.sort((a, b) {
        final indexA = ordenGrupos.indexOf(a.grupo);
        final indexB = ordenGrupos.indexOf(b.grupo);
        if (indexA != indexB) return indexA.compareTo(indexB);
        return a.ordenEnGrupo.compareTo(b.ordenEnGrupo);
      });
      return todosPontones;
    }

    // DÍAS DE SEMANA (Lunes a Viernes): Solo trabaja el grupo que abre la semana
    // Este grupo trabaja de lunes a viernes (abre lunes, cierra viernes)
    final grupoTrabajo = ordenGrupos[0];
    final pontonesDelDia = todosPontones
        .where((p) => p.grupo == grupoTrabajo)
        .toList();
    
    pontonesDelDia.sort((a, b) => a.ordenEnGrupo.compareTo(b.ordenEnGrupo));
    return pontonesDelDia;
  }

  /// Obtener información legible del rol actual
  Future<String> obtenerInfoRolActual() async {
    final rol = await obtenerRolSemanal();
    return rol.obtenerInfoSemana(DateTime.now());
  }
}
