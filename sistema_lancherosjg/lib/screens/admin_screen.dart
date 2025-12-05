import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/viajes_provider.dart';
import '../providers/cola_provider.dart';
import '../providers/rol_semanal_provider.dart';

/// Pantalla de administrador - Estadísticas y reportes
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadisticasAsync = ref.watch(estadisticasHoyProvider);
    final totalPontonesEnCola = ref.watch(totalPontonesEnColaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Administración',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(DateTime.now()),
              style: GoogleFonts.roboto(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: estadisticasAsync.when(
        data: (estadisticas) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjetas de resumen
              Row(
                children: [
                  Expanded(
                    child: _TarjetaEstadistica(
                      titulo: 'Total Viajes',
                      valor: '${estadisticas['totalViajes']}',
                      icono: Icons.directions_boat,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TarjetaEstadistica(
                      titulo: 'Pasajeros',
                      valor: '${estadisticas['totalPasajeros']}',
                      icono: Icons.people,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TarjetaEstadistica(
                      titulo: 'Ingresos',
                      valor: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                          .format(estadisticas['totalIngresos']),
                      icono: Icons.attach_money,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _TarjetaEstadistica(
                      titulo: 'En Cola',
                      valor: '$totalPontonesEnCola',
                      icono: Icons.queue,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TarjetaEstadistica(
                      titulo: 'Viajes Vacíos',
                      valor: '${estadisticas['vueltasVacias']}',
                      icono: Icons.warning_amber,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TarjetaEstadistica(
                      titulo: 'Promedio Llenado',
                      valor: estadisticas['promedioLlenado']
                          .toStringAsFixed(1),
                      icono: Icons.analytics,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Información adicional
              Text(
                'Detalles del Día',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    _FilaDetalle(
                      titulo: 'Hora de inicio',
                      valor: '7:00 AM', // TODO: Obtener de primer viaje
                    ),
                    const Divider(color: Colors.white24),
                    _FilaDetalle(
                      titulo: 'Última actualización',
                      valor: DateFormat('h:mm a').format(DateTime.now()),
                    ),
                    const Divider(color: Colors.white24),
                    _FilaDetalle(
                      titulo: 'Pontones operativos',
                      valor: '$totalPontonesEnCola',
                    ),
                    const Divider(color: Colors.white24),
                    _FilaDetalle(
                      titulo: 'Eficiencia de llenado',
                      valor:
                          '${((estadisticas['promedioLlenado'] / 15) * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Estadísticas por Pontón
              const _SeccionEstadisticasPorPonton(),
              
              const SizedBox(height: 32),

              // Configuración del Rol Semanal
              _SeccionRolSemanal(),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'Error al cargar estadísticas',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.roboto(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de estadística individual
class _TarjetaEstadistica extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _TarjetaEstadistica({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: GoogleFonts.roboto(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de detalle (clave-valor)
class _FilaDetalle extends StatelessWidget {
  final String titulo;
  final String valor;

  const _FilaDetalle({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: GoogleFonts.roboto(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para configurar el rol semanal
class _SeccionRolSemanal extends ConsumerWidget {
  const _SeccionRolSemanal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoRolAsync = ref.watch(infoRolActualProvider);
    final esFinDeSemana = ref.watch(esFinDeSemanaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuraci�n del Rol Semanal',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoRolAsync.when(
                data: (info) => Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        info,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error al cargar info'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: esFinDeSemana ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esFinDeSemana ? Colors.blue : Colors.green,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esFinDeSemana ? Icons.weekend : Icons.work,
                      color: esFinDeSemana ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      esFinDeSemana 
                          ? 'FIN DE SEMANA (Sáb-Dom): Trabajan todos los grupos (28 pontones)'
                          : 'DÍA DE SEMANA (Lun-Vie): Trabaja 1 grupo (7 pontones)',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar estadísticas por pontón
class _SeccionEstadisticasPorPonton extends ConsumerWidget {
  const _SeccionEstadisticasPorPonton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadisticasAsync = ref.watch(estadisticasPorPontonProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas por Pontón',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        estadisticasAsync.when(
          data: (estadisticas) {
            if (estadisticas.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    'No hay pontones en servicio',
                    style: GoogleFonts.roboto(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  // Encabezado de la tabla
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Pontón',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Viajes',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Pasajeros',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Ingresos',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Promedio',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filas de datos
                  ...estadisticas.map((stats) => _FilaPonton(stats: stats)),
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          ),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red),
            ),
            child: Center(
              child: Text(
                'Error al cargar estadísticas por pontón',
                style: GoogleFonts.roboto(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila individual de estadísticas de un pontón
class _FilaPonton extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _FilaPonton({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = _obtenerColorPorRendimiento(stats['totalViajes'] as int);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats['nombrePonton'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats['nombreChofer'] as String,
                  style: GoogleFonts.roboto(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(
                '${stats['totalViajes']}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${stats['totalPasajeros']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                  .format(stats['totalIngresos']),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (stats['promedioLlenado'] as double).toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorPorRendimiento(int viajes) {
    if (viajes == 0) return Colors.grey;
    if (viajes == 1) return Colors.orange;
    if (viajes == 2) return Colors.blue;
    return Colors.green;
  }
}
