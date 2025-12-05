import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para la configuración del rol semanal
/// Determina qué grupo trabaja cada semana según la rotación
class RolSemanal {
  /// Fecha de inicio de la primera semana registrada
  final DateTime fechaInicio;
  
  /// Orden de grupos para la primera semana
  /// Ejemplo: [2, 3, 4, 1] significa que en la primera semana trabaja el Grupo 2
  final List<int> ordenInicial;

  RolSemanal({
    required this.fechaInicio,
    required this.ordenInicial,
  });

  /// Calcular el orden de grupos para una fecha específica
  List<int> calcularOrdenParaFecha(DateTime fecha) {
    // Calcular semanas transcurridas desde fechaInicio
    final diferencia = fecha.difference(fechaInicio);
    final semanasTranscurridas = (diferencia.inDays / 7).floor();
    
    // Rotar el orden según las semanas transcurridas
    // Cada semana, el último grupo pasa al principio
    final orden = List<int>.from(ordenInicial);
    final rotaciones = semanasTranscurridas % 4; // Ciclo completo cada 4 semanas
    
    for (int i = 0; i < rotaciones; i++) {
      final ultimo = orden.removeLast();
      orden.insert(0, ultimo);
    }
    
    return orden;
  }

  /// Obtener el grupo que trabaja en una fecha específica
  /// Lunes a Viernes: Solo el primer grupo del orden semanal
  /// Sábados y Domingos: Todos los grupos (28 pontones)
  int grupoParaDia(DateTime fecha) {
    final orden = calcularOrdenParaFecha(fecha);
    
    // Para lunes a viernes (1-5), solo trabaja el primer grupo del orden
    // Este grupo abre el lunes y cierra el viernes
    final diaSemana = fecha.weekday; // 1=lunes, 7=domingo
    if (diaSemana >= 1 && diaSemana <= 5) {
      return orden[0];
    }
    
    // Para sábados (6) y domingos (7), trabajan todos los grupos
    // El orden determina la prioridad en la cola
    return orden[0]; // Retornamos el grupo principal para referencia
  }

  /// Verificar si es fin de semana
  bool esFinDeSemana(DateTime fecha) {
    final diaSemana = fecha.weekday;
    return diaSemana == 6 || diaSemana == 7; // Sábado o domingo
  }

  /// Serialización a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'ordenInicial': ordenInicial,
    };
  }

  /// Deserialización desde Firestore
  factory RolSemanal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RolSemanal(
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      ordenInicial: List<int>.from(data['ordenInicial']),
    );
  }

  /// Constructor con valores por defecto
  /// Inicia con el orden observado en la imagen: [2, 3, 4, 1]
  factory RolSemanal.porDefecto() {
    return RolSemanal(
      fechaInicio: DateTime(2024, 11, 24), // 24 de noviembre 2024
      ordenInicial: [2, 3, 4, 1],
    );
  }

  /// Obtener información de la semana actual
  String obtenerInfoSemana(DateTime fecha) {
    final diferencia = fecha.difference(fechaInicio);
    final numeroSemana = (diferencia.inDays / 7).floor() + 1;
    
    return 'Semana $numeroSemana';
  }
}
