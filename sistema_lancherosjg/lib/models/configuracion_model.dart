import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuración global del sistema (precios, límites, etc.)
class Configuracion {
  final Map<String, double> precios; // Precios por tipo de pasajero
  final int maxPasajeros; // Capacidad máxima por pontón
  final List<int> gruposActivos; // Grupos trabajando hoy
  final DateTime? ultimoCambioRol; // Última vez que se rotó el rol

  Configuracion({
    required this.precios,
    required this.maxPasajeros,
    this.gruposActivos = const [1, 2, 3, 4],
    this.ultimoCambioRol,
  });

  /// Precio por tipo de pasajero
  double getPrecio(String tipo) => precios[tipo] ?? 0.0;

  factory Configuracion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Configuracion(
      precios: Map<String, double>.from(
        (data['precios'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      maxPasajeros: data['max_pasajeros'] ?? 15,
      gruposActivos: data['gruposActivos'] != null
          ? List<int>.from(data['gruposActivos'])
          : [1, 2, 3, 4],
      ultimoCambioRol: data['ultimoCambioRol'] != null
          ? (data['ultimoCambioRol'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'precios': precios,
      'max_pasajeros': maxPasajeros,
      'gruposActivos': gruposActivos,
      'ultimoCambioRol': ultimoCambioRol != null
          ? Timestamp.fromDate(ultimoCambioRol!)
          : null,
    };
  }

  /// Configuración por defecto
  factory Configuracion.porDefecto() {
    return Configuracion(
      precios: {
        'adulto': 50.0,
        'nino': 40.0,
        'inapam': 40.0,
        'especial': 40.0,
        'trabajador': 0.0,
        'cortesia': 0.0,
      },
      maxPasajeros: 15,
      gruposActivos: [1, 2, 3, 4],
    );
  }

  Configuracion copyWith({
    Map<String, double>? precios,
    int? maxPasajeros,
    List<int>? gruposActivos,
    DateTime? ultimoCambioRol,
  }) {
    return Configuracion(
      precios: precios ?? this.precios,
      maxPasajeros: maxPasajeros ?? this.maxPasajeros,
      gruposActivos: gruposActivos ?? this.gruposActivos,
      ultimoCambioRol: ultimoCambioRol ?? this.ultimoCambioRol,
    );
  }
}
