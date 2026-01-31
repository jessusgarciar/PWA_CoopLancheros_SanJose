import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de un pontón en la cola
enum EstadoCola {
  espera,    // En espera (después de los primeros 6)
  cuadro,    // En cuadro (posiciones 2-6)
  cargando,  // Cargando actualmente (posición 1)
  completado // Terminó el viaje
}

/// Representa un pontón en la cola de servicio
/// Se ordena por ordenOriginal (del rol) y luego por vueltas completadas
class ColaPonton {
  final String idPonton;
  final String nombrePonton;
  final String nombreChofer;
  final DateTime fechaIngreso;
  final EstadoCola estado;
  final int? posicionCuadro; // 1-6 para mostrar en pantalla (1=cargando, 2-6=cuadro)
  final int vueltasHoy; // Contador de vueltas completadas en el día
  final bool tienePasajeros; // Indica si ya tiene pasajeros abordo (está cargando)
  final int ordenOriginal; // Orden según el rol del día (se mantiene fijo toda la jornada)

  ColaPonton({
    required this.idPonton,
    required this.nombrePonton,
    required this.nombreChofer,
    required this.fechaIngreso,
    required this.estado,
    this.posicionCuadro,
    this.vueltasHoy = 0,
    this.tienePasajeros = false,
    required this.ordenOriginal,
  });

  factory ColaPonton.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ColaPonton(
      idPonton: doc.id,
      nombrePonton: data['nombrePonton'] ?? '',
      nombreChofer: data['nombreChofer'] ?? '',
      fechaIngreso: (data['fechaIngreso'] as Timestamp).toDate(),
      estado: EstadoCola.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoCola.espera,
      ),
      posicionCuadro: data['posicionCuadro'],
      vueltasHoy: data['vueltasHoy'] ?? 0,
      tienePasajeros: data['tienePasajeros'] ?? false,
      ordenOriginal: data['ordenOriginal'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombrePonton': nombrePonton,
      'nombreChofer': nombreChofer,
      'fechaIngreso': Timestamp.fromDate(fechaIngreso),
      'estado': estado.name,
      'posicionCuadro': posicionCuadro,
      'vueltasHoy': vueltasHoy,
      'tienePasajeros': tienePasajeros,
      'ordenOriginal': ordenOriginal,
    };
  }

  ColaPonton copyWith({
    String? idPonton,
    String? nombrePonton,
    String? nombreChofer,
    DateTime? fechaIngreso,
    EstadoCola? estado,
    int? posicionCuadro,
    int? vueltasHoy,
    bool? tienePasajeros,
    int? ordenOriginal,
  }) {
    return ColaPonton(
      idPonton: idPonton ?? this.idPonton,
      nombrePonton: nombrePonton ?? this.nombrePonton,
      nombreChofer: nombreChofer ?? this.nombreChofer,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      estado: estado ?? this.estado,
      posicionCuadro: posicionCuadro ?? this.posicionCuadro,
      vueltasHoy: vueltasHoy ?? this.vueltasHoy,
      tienePasajeros: tienePasajeros ?? this.tienePasajeros,
      ordenOriginal: ordenOriginal ?? this.ordenOriginal,
    );
  }
}
