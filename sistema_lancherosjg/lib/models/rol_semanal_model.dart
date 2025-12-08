import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para la configuración del rol diario
/// Determina qué grupo trabaja cada DÍA según la rotación
/// Patrón: Cada día rota entre grupos [1,2,3,4], ciclo de 4 días
class RolSemanal {
  /// Fecha de inicio de referencia (primer lunes registrado)
  final DateTime fechaInicio;
  
  /// Grupo que trabaja en la fecha de inicio
  /// Ejemplo: Si fechaInicio es lunes 25-nov-2024 y grupoInicio=2,
  /// entonces ese lunes trabaja Grupo 2
  final int grupoInicio;

  RolSemanal({
    required this.fechaInicio,
    required this.grupoInicio,
  });

  /// Calcular qué grupo trabaja en una fecha específica
  /// Patrón de rotación DIARIA:
  /// - Lunes a Jueves: Rota entre grupos [1,2,3,4] cada día
  /// - Viernes: Repite el grupo del lunes
  /// - Sábado/Domingo: Trabajan todos los grupos (28 pontones)
  int grupoParaDia(DateTime fecha) {
    final diaSemana = fecha.weekday; // 1=lunes, 2=martes, ..., 7=domingo
    
    // Fines de semana: todos los grupos trabajan
    if (diaSemana == 6 || diaSemana == 7) {
      return 0; // Código especial para "todos los grupos"
    }
    
    // Obtener el lunes de la semana actual
    final lunesActual = _obtenerInicioSemana(fecha);
    
    // Calcular cuántos lunes han pasado desde fechaInicio
    final lunesReferencia = _obtenerInicioSemana(fechaInicio);
    final diferenciaDias = lunesActual.difference(lunesReferencia).inDays;
    final semanasCompletas = (diferenciaDias / 7).round();
    
    // El grupo del lunes rota cada semana: grupoInicio -> siguiente -> siguiente...
    // Ciclo: 1->2->3->4->1
    final grupoLunes = ((grupoInicio - 1 + semanasCompletas) % 4) + 1;
    
    // De lunes a jueves: avanza un grupo cada día
    // Lunes: grupoLunes, Martes: grupoLunes+1, Miércoles: grupoLunes+2, Jueves: grupoLunes+3
    // Viernes: repite el grupo del lunes
    if (diaSemana == 5) { // Viernes
      return grupoLunes;
    } else { // Lunes (1) a Jueves (4)
      final offset = diaSemana - 1; // 0 para lunes, 1 para martes, 2 para miércoles, 3 para jueves
      return ((grupoLunes - 1 + offset) % 4) + 1;
    }
  }

  /// Calcular el orden de grupos para una fecha específica
  /// Mantiene compatibilidad con código existente
  List<int> calcularOrdenParaFecha(DateTime fecha) {
    final grupoActual = grupoParaDia(fecha);
    
    // Si es fin de semana, retorna orden completo empezando por el grupo del lunes
    if (grupoActual == 0) {
      final lunesActual = _obtenerInicioSemana(fecha);
      final grupoLunes = grupoParaDia(lunesActual);
      return _generarOrden(grupoLunes);
    }
    
    // Para días de semana, retorna orden empezando por el grupo actual
    return _generarOrden(grupoActual);
  }
  
  /// Generar lista ordenada empezando por un grupo específico
  List<int> _generarOrden(int grupoInicial) {
    final orden = <int>[];
    for (int i = 0; i < 4; i++) {
      orden.add(((grupoInicial - 1 + i) % 4) + 1);
    }
    return orden;
  }
  
  /// Obtener el lunes de la semana de una fecha
  DateTime _obtenerInicioSemana(DateTime fecha) {
    final diaSemana = fecha.weekday; // 1=lunes, 7=domingo
    return DateTime(fecha.year, fecha.month, fecha.day).subtract(Duration(days: diaSemana - 1));
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
      'grupoInicio': grupoInicio,
    };
  }

  /// Deserialización desde Firestore
  factory RolSemanal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RolSemanal(
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      grupoInicio: data['grupoInicio'] as int,
    );
  }

  /// Constructor con valores por defecto
  /// 1 Diciembre 2025 (Lunes) = Grupo 3 según tu calendario
  factory RolSemanal.porDefecto() {
    return RolSemanal(
      fechaInicio: DateTime(2025, 12, 1), // Lunes 1 de diciembre 2025
      grupoInicio: 3, // Ese día trabaja Grupo 3
    );
  }

  /// Obtener información del día actual
  String obtenerInfoSemana(DateTime fecha) {
    final grupo = grupoParaDia(fecha);
    if (grupo == 0) {
      return 'Fin de semana - Todos los grupos';
    }
    return 'Grupo $grupo';
  }
}
