import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un pontón (lancha) del sistema
/// Basado en el rol físico con 28 pontones divididos en 4 grupos
class Ponton {
  final String id; // Número del pontón (1-28)
  final String nombre; // Nombre del pontón (ej. VAGABUNDO, PINTA, etc.)
  final int grupo; // 1, 2, 3 o 4 según el rol
  final int ordenEnGrupo; // Posición dentro del grupo (1-7)
  final String? nombreChofer; // Nombre del lanchero asignado
  final bool disponible; // Si está operativo
  final String? motivoNoDisponible; // "Perdió Vuelta" o "Falla mecánica"
  final String? fcmToken; // Token para notificaciones push

  Ponton({
    required this.id,
    required this.nombre,
    required this.grupo,
    required this.ordenEnGrupo,
    this.nombreChofer,
    this.disponible = true,
    this.motivoNoDisponible,
    this.fcmToken,
  });

  factory Ponton.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ponton(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      grupo: data['grupo'] ?? 0,
      ordenEnGrupo: data['ordenEnGrupo'] ?? 0,
      nombreChofer: data['nombreChofer'],
      disponible: data['disponible'] ?? true,
      motivoNoDisponible: data['motivoNoDisponible'],
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'grupo': grupo,
      'ordenEnGrupo': ordenEnGrupo,
      'nombreChofer': nombreChofer,
      'disponible': disponible,
      'motivoNoDisponible': motivoNoDisponible,
      'fcmToken': fcmToken,
    };
  }

  Ponton copyWith({
    String? id,
    String? nombre,
    int? grupo,
    int? ordenEnGrupo,
    String? nombreChofer,
    bool? disponible,
    String? motivoNoDisponible,
    String? fcmToken,
  }) {
    return Ponton(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      grupo: grupo ?? this.grupo,
      ordenEnGrupo: ordenEnGrupo ?? this.ordenEnGrupo,
      nombreChofer: nombreChofer ?? this.nombreChofer,
      disponible: disponible ?? this.disponible,
      motivoNoDisponible: motivoNoDisponible ?? this.motivoNoDisponible,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
