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
  
  /// Forzar reinicialización de pontones (USAR CON CUIDADO)
  Future<void> reinicializarPontones() async {
    try {
      print('🔄 Reinicializando pontones...');
      
      // Eliminar todos los pontones existentes
      final pontonesSnapshot = await _pontonesRef.get();
      final batch1 = _firestore.batch();
      for (var doc in pontonesSnapshot.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();
      
      // Limpiar la cola
      final colaSnapshot = await _colaRef.get();
      final batch2 = _firestore.batch();
      for (var doc in colaSnapshot.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();
      
      // Crear los pontones con el orden correcto
      final pontones = _crearPontonesDelRol();
      final batch3 = _firestore.batch();
      for (var ponton in pontones) {
        batch3.set(_pontonesRef.doc(ponton.id), ponton.toFirestore());
      }
      await batch3.commit();
      
      print('✅ Pontones reinicializados correctamente');
      print('⚠️ Ahora debes presionar "Iniciar Rol del Día" para agregar los pontones correctos a la cola');
    } catch (e) {
      print('❌ Error al reinicializar pontones: $e');
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
      // Verificar si es un nuevo día antes de agregar
      await verificarYResetearContadorDiario();
      
      // SIEMPRE limpiar la cola antes de agregar nuevos pontones
      // Esto asegura que se resetee correctamente
      final colaSnapshot = await _colaRef.get();
      if (colaSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in colaSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('🧹 Cola limpiada antes de agregar pontones del día');
      }
      
      // Obtener pontones que trabajan hoy según el rol
      final pontonesHoy = await obtenerPontonesOrdenadosPorRol();
      
      if (pontonesHoy.isEmpty) {
        print('⚠️ No hay pontones para agregar');
        return;
      }
      
      print('📋 Agregando ${pontonesHoy.length} pontones a la cola...');
      
      final batch = _firestore.batch();
      final ahora = Timestamp.now();
      
      for (var i = 0; i < pontonesHoy.length; i++) {
        final ponton = pontonesHoy[i];
        
        // Determinar el estado inicial según la posición
        // Posición 0 = cargando, 1-4 = cuadro, 5+ = espera
        EstadoCola estadoInicial;
        int? posicionCuadro;
        
        if (i == 0) {
          estadoInicial = EstadoCola.cargando;
          posicionCuadro = 1;
        } else if (i <= 4) {
          estadoInicial = EstadoCola.cuadro;
          posicionCuadro = i + 1; // 2, 3, 4, 5
        } else {
          estadoInicial = EstadoCola.espera;
          posicionCuadro = null;
        }
        
        // Agregar a la cola con un pequeño offset en el timestamp para mantener el orden
        batch.set(_colaRef.doc(ponton.id), {
          'nombrePonton': ponton.nombre,
          'nombreChofer': ponton.nombreChofer ?? 'Sin asignar',
          'fechaIngreso': Timestamp.fromMillisecondsSinceEpoch(
            ahora.millisecondsSinceEpoch + (i * 1000) // 1 segundo entre cada uno
          ),
          'estado': estadoInicial.name,
          'posicionCuadro': posicionCuadro,
          'vueltasHoy': 0,
          'tienePasajeros': false,
          'ordenOriginal': i, // Guardar posición original del rol
        });
      }
      
      await batch.commit();
      
      // Actualizar fecha de última actividad
      await _configRef.update({
        'fechaUltimaActividad': Timestamp.now(),
        'vueltasCompletadasHoy': 0, // Resetear contador de vueltas
      });
      
      print('✅ ${pontonesHoy.length} pontones agregados a la cola (sistema reiniciado)');
    } catch (e) {
      print('❌ Error al agregar pontones a la cola: $e');
      rethrow;
    }
  }
  
  /// Verificar si es un nuevo día y resetear todo el sistema
  Future<void> verificarYResetearContadorDiario() async {
    try {
      final configDoc = await _configRef.get();
      if (!configDoc.exists) return;
      
      final config = Configuracion.fromFirestore(configDoc);
      final ahora = DateTime.now();
      
      // Verificar si hay pontones en la cola primero
      final colaSnapshot = await _colaRef.get();
      
      // Si no hay fecha de actividad registrada o es un día diferente, resetear
      if (config.fechaUltimaActividad == null || 
          !_esElMismoDia(config.fechaUltimaActividad!, ahora)) {
        
        // Solo resetear si hay algo que limpiar
        if (colaSnapshot.docs.isNotEmpty || config.vueltasCompletadasHoy > 0) {
          // Resetear contador global de vueltas y actualizar fecha de actividad
          await _configRef.update({
            'vueltasCompletadasHoy': 0,
            'fechaUltimaVuelta': null,
            'fechaUltimaActividad': Timestamp.fromDate(ahora),
          });
          
          // Limpiar la cola de servicio (eliminar todos los pontones)
          if (colaSnapshot.docs.isNotEmpty) {
            final batch = _firestore.batch();
            for (var doc in colaSnapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            print('🧹 Cola de servicio limpiada para nuevo día');
          }
          
          print('🔄 Sistema reseteado para nuevo día (${ahora.day}/${ahora.month}/${ahora.year})');
        } else {
          // Actualizar la fecha aunque no haya nada que limpiar
          await _configRef.update({
            'fechaUltimaActividad': Timestamp.fromDate(ahora),
          });
        }
      } else {
        print('✅ Mismo día - No se resetea (${ahora.day}/${ahora.month}/${ahora.year})');
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
    // Nombres extraídos directamente de las imágenes del rol
    // Grupo #1 (Obreado #1): 1-7
    final nombresGrupo1 = [
      'MARLIN',
      'DIANA',
      'DELFIN',
      'COLORADO',
      'ASTRO',
      'ALBORADA',
      'LUCHIN'
    ];
    // Grupo #2 (Obreado #2): 8-14
    final nombresGrupo2 = [
      'RODOLFO',
      'MONE',
      'SANTA MARIA',
      'ALCON',
      'COMETA',
      'COMUNERO',
      'GARZA'
    ];
    // Grupo #3 (Obreado #3): 15-21
    final nombresGrupo3 = [
      'ORIGINAL',
      'VAGABUNDO',
      'PINTA',
      'NIÑA',
      'SOÑADOR',
      'PELICANO',
      'RANA'
    ];
    // Grupo #4 (Obreado #4): 22-28
    final nombresGrupo4 = [
      'SPIRIT',
      'TIBURON',
      'PITUFO',
      'RIO BLANCO',
      'PINGUINO',
      'LEON',
      'ALONDRA'
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

  /// Stream de la cola en tiempo real (ordenada por orden original del rol)
  Stream<List<ColaPonton>> streamCola() {
    return _colaRef
        .snapshots()
        .map((snapshot) {
          final pontones = snapshot.docs
              .map((doc) => ColaPonton.fromFirestore(doc))
              .toList();
          
          // Ordenar por: 1) vueltas completadas, 2) orden original del rol
          // Esto mantiene el orden del rol incluso si terminan en diferente orden
          pontones.sort((a, b) {
            // Primero por vueltas (menos vueltas = más prioritario)
            final vueltasCompare = a.vueltasHoy.compareTo(b.vueltasHoy);
            if (vueltasCompare != 0) return vueltasCompare;
            
            // Si tienen las mismas vueltas, por orden original
            return a.ordenOriginal.compareTo(b.ordenOriginal);
          });
          
          return pontones;
        });
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

      // Obtener cuántos pontones hay en cola para calcular el ordenOriginal
      final snapshot = await _colaRef.get();
      final ordenOriginal = snapshot.docs.length;

      await _colaRef.doc(idPonton).set({
        'nombrePonton': ponton.nombre,
        'nombreChofer': nombreChofer,
        'fechaIngreso': Timestamp.now(),
        'estado': EstadoCola.espera.name,
        'vueltasHoy': 0,
        'tienePasajeros': false,
        'ordenOriginal': ordenOriginal,
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

      // Actualizar solo vueltas y estado, NO el ordenOriginal
      // Esto mantiene el orden del rol original
      await _colaRef.doc(idPonton).update({
        'fechaIngreso': Timestamp.now(), // Solo para referencia de tiempo
        'estado': EstadoCola.espera.name,
        'posicionCuadro': null,
        'vueltasHoy': cola.vueltasHoy + 1,
        'tienePasajeros': false,
        // NO actualizar 'ordenOriginal' - se mantiene fijo
      });

      // Reorganizar estados de los pontones restantes
      await _reorganizarEstadosCola();

      print('✅ Pontón reingresado manteniendo su orden original');
    } catch (e) {
      print('❌ Error al reingresar a cola: $e');
      rethrow;
    }
  }

  /// Reorganizar estados y posiciones después de cambios en la cola
  Future<void> _reorganizarEstadosCola() async {
    try {
      // Obtener todos los pontones ordenados correctamente
      final pontones = await streamCola().first;

      if (pontones.isEmpty) return;

      final batch = _firestore.batch();

      for (var i = 0; i < pontones.length; i++) {
        final ponton = pontones[i];
        EstadoCola nuevoEstado;
        int? nuevaPosicion;

        if (i == 0) {
          // Primer pontón: cargando
          nuevoEstado = EstadoCola.cargando;
          nuevaPosicion = 1;
        } else if (i <= 4) {
          // Posiciones 2-5: cuadro
          nuevoEstado = EstadoCola.cuadro;
          nuevaPosicion = i + 1;
        } else {
          // Resto: espera
          nuevoEstado = EstadoCola.espera;
          nuevaPosicion = null;
        }

        // Solo actualizar si cambió
        if (ponton.estado != nuevoEstado || ponton.posicionCuadro != nuevaPosicion) {
          batch.update(_colaRef.doc(ponton.idPonton), {
            'estado': nuevoEstado.name,
            'posicionCuadro': nuevaPosicion,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('⚠️ Error al reorganizar cola: $e');
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

  /// Actualizar si el pontón tiene pasajeros (está cargando)
  Future<void> actualizarTienePasajeros(String idPonton, bool tienePasajeros) async {
    try {
      await _colaRef.doc(idPonton).update({
        'tienePasajeros': tienePasajeros,
      });
    } catch (e) {
      print('❌ Error al actualizar tienePasajeros: $e');
      // No lanzar error para no interrumpir el flujo
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

  /// ============ LLEGADAS A ISLA (PASEOS) ============

  /// Registrar cantidad de personas que llegan a la isla (paseos con llegada)
  Future<void> registrarLlegadasIsla(int cantidad) async {
    try {
      final hoy = DateTime.now();
      final id = '${hoy.year}-${hoy.month}-${hoy.day}';
      await _firestore.collection('admin').doc('llegadas_isla').set({
        id: FieldValue.increment(cantidad),
      }, SetOptions(merge: true));
      print('📝 Llegadas a isla registradas: +$cantidad');
    } catch (e) {
      print('❌ Error registrando llegadas: $e');
    }
  }

  /// Stream de llegadas para panel admin
  Stream<Map<String, int>> streamLlegadasIsla() {
    return _firestore.collection('admin').doc('llegadas_isla').snapshots().map((doc) {
      if (!doc.exists) return <String, int>{};
      final data = doc.data() as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    });
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
    // Verificar si es un nuevo día antes de retornar las vueltas
    await verificarYResetearContadorDiario();
    
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

  /// NOTA: Ya no se necesita rotación manual del rol
  /// La rotación es AUTOMÁTICA y DIARIA basada en RolSemanal.grupoParaDia()
  /// Cada día determina automáticamente qué grupo trabaja según la fecha

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
    
    // Obtener todos los pontones
    final snapshot = await _pontonesRef.get();
    final todosPontones = snapshot.docs
        .map((doc) => Ponton.fromFirestore(doc))
        .toList();

    // FINES DE SEMANA (Sábado y Domingo): Todos los pontones trabajan (28 pontones)
    if (rol.esFinDeSemana(fechaConsulta)) {
      final ordenGrupos = rol.calcularOrdenParaFecha(fechaConsulta);
      
      // Agrupar pontones por grupo
      final pontonesPorGrupo = <int, List<Ponton>>{};
      for (var ponton in todosPontones) {
        pontonesPorGrupo.putIfAbsent(ponton.grupo, () => []).add(ponton);
      }
      
      // Ordenar cada grupo y aplicar rotación interna específica por grupo
      for (var grupo in pontonesPorGrupo.keys) {
        pontonesPorGrupo[grupo]!.sort((a, b) => a.ordenEnGrupo.compareTo(b.ordenEnGrupo));
        
        // Calcular rotaciones para este grupo específico
        final rotacionesInternas = rol.calcularRotacionesInternas(fechaConsulta, grupo);
        
        // Rotar internamente
        for (int i = 0; i < rotacionesInternas; i++) {
          if (pontonesPorGrupo[grupo]!.isNotEmpty) {
            final primero = pontonesPorGrupo[grupo]!.removeAt(0);
            pontonesPorGrupo[grupo]!.add(primero);
          }
        }
      }
      
      // Reconstruir lista en orden de grupos
      final resultado = <Ponton>[];
      for (var numeroGrupo in ordenGrupos) {
        resultado.addAll(pontonesPorGrupo[numeroGrupo] ?? []);
      }
      
      return resultado;
    }

    // DÍAS DE SEMANA (Lunes a Viernes): Trabaja solo el grupo del día
    // La rotación es DIARIA: Lunes→Martes→Miércoles→Jueves (grupos diferentes)
    // Viernes repite el grupo del lunes
    final grupoDelDia = rol.grupoParaDia(fechaConsulta);
    final pontonesDelDia = todosPontones
        .where((p) => p.grupo == grupoDelDia)
        .toList();
    
    // Ordenar por ordenEnGrupo
    pontonesDelDia.sort((a, b) => a.ordenEnGrupo.compareTo(b.ordenEnGrupo));
    
    // Aplicar rotación interna semanal: el primero pasa al final cada semana
    // Calcular rotaciones para este grupo específico
    final rotacionesInternas = rol.calcularRotacionesInternas(fechaConsulta, grupoDelDia);
    for (int i = 0; i < rotacionesInternas; i++) {
      if (pontonesDelDia.isNotEmpty) {
        final primero = pontonesDelDia.removeAt(0);
        pontonesDelDia.add(primero);
      }
    }
    
    return pontonesDelDia;
  }

  /// Obtener información legible del rol actual
  Future<String> obtenerInfoRolActual() async {
    final rol = await obtenerRolSemanal();
    return rol.obtenerInfoSemana(DateTime.now());
  }
}
