import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/viajes_provider.dart';
import '../providers/cola_provider.dart';

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
