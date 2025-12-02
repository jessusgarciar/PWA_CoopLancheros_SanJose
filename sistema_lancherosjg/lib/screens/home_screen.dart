import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/cola_model.dart';
import '../providers/cola_provider.dart';
import '../providers/viajes_provider.dart';
import '../services/firebase_service.dart';

/// Pantalla principal para lancheros
/// Muestra: Quién está cargando, cuadro (próximos 5), y cola de espera
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colaOrganizada = ref.watch(colaOrganizadaProvider);
    final totalVueltas = ref.watch(totalVueltasHoyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lancheros San José',
              style: GoogleFonts.poppins(
                color: Colors.white,
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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$totalVueltas vueltas',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Cargando (el que está actualmente en servicio)
            _SeccionCola(
              titulo: '🚤 CARGANDO',
              pontones: colaOrganizada['cargando']!,
              color: Colors.green,
              destacado: true,
            ),
            const SizedBox(height: 24),

            // Sección: Cuadro (los próximos 5)
            _SeccionCola(
              titulo: '📋 EN CUADRO',
              pontones: colaOrganizada['cuadro']!,
              color: Colors.orange,
              mostrarNumeros: true,
            ),
            const SizedBox(height: 24),

            // Sección: En Espera (el resto)
            _SeccionCola(
              titulo: '⏳ EN ESPERA',
              pontones: colaOrganizada['espera']!,
              color: Colors.grey,
              colapsable: true,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón temporal (Bórralo después de usarlo una vez)
          FloatingActionButton(
            heroTag: 'initPontones',
            onPressed: () async {
              try {
                final firebaseService = FirebaseService();
                await firebaseService.inicializarSistema();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Listo! 28 Pontones creados en la base de datos.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Icon(Icons.cloud_upload),
            backgroundColor: Colors.red,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'goTabla',
            onPressed: () {
              context.go('/tabla');
            },
            backgroundColor: const Color(0xFF1E3A5F),
            icon: const Icon(Icons.edit_note),
            label: Text(
              'Ir a Tabla',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget reutilizable para mostrar secciones de la cola
class _SeccionCola extends StatefulWidget {
  final String titulo;
  final List<ColaPonton> pontones;
  final Color color;
  final bool mostrarNumeros;
  final bool destacado;
  final bool colapsable;

  const _SeccionCola({
    required this.titulo,
    required this.pontones,
    required this.color,
    this.mostrarNumeros = false,
    this.destacado = false,
    this.colapsable = false,
  });

  @override
  State<_SeccionCola> createState() => _SeccionColaState();
}

class _SeccionColaState extends State<_SeccionCola> {
  bool _expandido = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        InkWell(
          onTap: widget.colapsable
              ? () => setState(() => _expandido = !_expandido)
              : null,
          child: Row(
            children: [
              Text(
                widget.titulo,
                style: GoogleFonts.poppins(
                  fontSize: widget.destacado ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              if (widget.pontones.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.pontones.length}',
                    style: GoogleFonts.poppins(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (widget.colapsable) ...[
                const Spacer(),
                Icon(
                  _expandido ? Icons.expand_less : Icons.expand_more,
                  color: widget.color,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Contenido
        if (_expandido) ...[
          if (widget.pontones.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  'Ninguno',
                  style: GoogleFonts.roboto(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...widget.pontones.asMap().entries.map((entry) {
              final index = entry.key;
              final ponton = entry.value;
              return _TarjetaPonton(
                ponton: ponton,
                color: widget.color,
                numero: widget.mostrarNumeros ? index + 1 : null,
                destacado: widget.destacado,
              );
            }),
        ],
      ],
    );
  }
}

/// Tarjeta individual de un pontón
class _TarjetaPonton extends StatelessWidget {
  final ColaPonton ponton;
  final Color color;
  final int? numero;
  final bool destacado;

  const _TarjetaPonton({
    required this.ponton,
    required this.color,
    this.numero,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(destacado ? 20 : 16),
      decoration: BoxDecoration(
        gradient: destacado
            ? LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: destacado ? null : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: destacado ? 3 : 2,
        ),
        boxShadow: destacado
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Número de posición
          if (numero != null) ...[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Información del pontón
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ponton.nombrePonton,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: destacado ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.white70,
                      size: destacado ? 18 : 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ponton.nombreChofer,
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: destacado ? 16 : 14,
                      ),
                    ),
                  ],
                ),
                if (ponton.vueltasHoy > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Colors.white60,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ponton.vueltasHoy} ${ponton.vueltasHoy == 1 ? 'vuelta' : 'vueltas'} hoy',
                        style: GoogleFonts.roboto(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Indicador de tiempo en cola
          if (!destacado)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Text(
                  _calcularTiempoEspera(ponton.fechaIngreso),
                  style: GoogleFonts.roboto(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _calcularTiempoEspera(DateTime fechaIngreso) {
    final diferencia = DateTime.now().difference(fechaIngreso);
    if (diferencia.inMinutes < 60) {
      return '${diferencia.inMinutes} min';
    } else {
      return '${diferencia.inHours}h ${diferencia.inMinutes % 60}m';
    }
  }
}
