import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de boleto/pasajero según las tarifas
enum TipoPasajero {
  adulto,
  nino,
  inapam,
  especial,
  trabajador,
  cortesia,
}

/// Representa un viaje completado (registro de "La Tabla")
class Viaje {
  final String id;
  final DateTime fecha;
  final String idPonton;
  final String nombrePonton;
  final String nombreChofer;
  final Map<String, int> desglosePasajeros; // {adulto: 2, nino: 1, etc.}
  final Map<String, dynamic> finanzas; // {calculado: 140, cobrado_real: 120, nota: "..."}
  final bool vacioAIsla; // Si fue vacío a la isla
  final int numeroVuelta; // Número de vuelta del día

  Viaje({
    required this.id,
    required this.fecha,
    required this.idPonton,
    required this.nombrePonton,
    required this.nombreChofer,
    required this.desglosePasajeros,
    required this.finanzas,
    this.vacioAIsla = false,
    this.numeroVuelta = 1,
  });

  /// Total de pasajeros en el viaje
  int get totalPasajeros => desglosePasajeros.values.fold(0, (a, b) => a + b);

  /// Monto calculado según tarifas
  double get montoCalculado => (finanzas['calculado'] ?? 0).toDouble();

  /// Monto realmente cobrado
  double get montoCobrado => (finanzas['cobrado_real'] ?? 0).toDouble();

  factory Viaje.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Viaje(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      idPonton: data['idPonton'] ?? '',
      nombrePonton: data['nombrePonton'] ?? '',
      nombreChofer: data['nombreChofer'] ?? '',
      desglosePasajeros: Map<String, int>.from(data['desglosePasajeros'] ?? {}),
      finanzas: Map<String, dynamic>.from(data['finanzas'] ?? {}),
      vacioAIsla: data['vacioAIsla'] ?? false,
      numeroVuelta: data['numeroVuelta'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'idPonton': idPonton,
      'nombrePonton': nombrePonton,
      'nombreChofer': nombreChofer,
      'desglosePasajeros': desglosePasajeros,
      'finanzas': finanzas,
      'vacioAIsla': vacioAIsla,
      'numeroVuelta': numeroVuelta,
    };
  }

  Viaje copyWith({
    String? id,
    DateTime? fecha,
    String? idPonton,
    String? nombrePonton,
    String? nombreChofer,
    Map<String, int>? desglosePasajeros,
    Map<String, dynamic>? finanzas,
    bool? vacioAIsla,
    int? numeroVuelta,
  }) {
    return Viaje(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      idPonton: idPonton ?? this.idPonton,
      nombrePonton: nombrePonton ?? this.nombrePonton,
      nombreChofer: nombreChofer ?? this.nombreChofer,
      desglosePasajeros: desglosePasajeros ?? this.desglosePasajeros,
      finanzas: finanzas ?? this.finanzas,
      vacioAIsla: vacioAIsla ?? this.vacioAIsla,
      numeroVuelta: numeroVuelta ?? this.numeroVuelta,
    );
  }
}
