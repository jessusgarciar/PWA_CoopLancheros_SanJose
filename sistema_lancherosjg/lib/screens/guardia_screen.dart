import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/cola_provider.dart';

/// Interfaz Guardia: muestra lanchas en cuadro con contador 1-15 y cronómetro 15:00
class GuardiaScreen extends ConsumerWidget {
  const GuardiaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colaOrganizada = ref.watch(colaOrganizadaProvider);
    final cargando = colaOrganizada['cargando']!;
    final enCuadro = colaOrganizada['cuadro']!;
    final todosActivos = [...cargando, ...enCuadro];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text('Guardia', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: todosActivos.isEmpty
            ? Center(
                child: Text('No hay lanchas activas', style: GoogleFonts.roboto(color: Colors.white70)),
              )
            : ListView.separated(
                itemCount: todosActivos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = todosActivos[i];
                  return _TarjetaGuardia(nombre: p.nombrePonton, idPonton: p.idPonton);
                },
              ),
      ),
    );
  }
}

class _TarjetaGuardia extends StatefulWidget {
  final String nombre;
  final String idPonton;
  const _TarjetaGuardia({required this.nombre, required this.idPonton});

  @override
  State<_TarjetaGuardia> createState() => _TarjetaGuardiaState();
}

class _TarjetaGuardiaState extends State<_TarjetaGuardia> {
  int contador = 0; // 0-15
  Duration restante = const Duration(minutes: 15);
  bool corriendo = false;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsed) {
      if (!corriendo) return;
      setState(() {
        if (restante.inSeconds > 0) {
          restante = Duration(seconds: restante.inSeconds - 1);
        } else {
          corriendo = false;
        }
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nombre, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Cronómetro', style: GoogleFonts.roboto(color: Colors.white70)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                  child: Text(_fmt(restante), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('Personas', style: GoogleFonts.roboto(color: Colors.white70)),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: contador > 0 ? () => setState(() => contador--) : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                  ),
                  Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Text('$contador', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: contador < 15 ? () => setState(() => contador++) : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() => corriendo = true),
                    child: const Text('Iniciar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() { corriendo = false; restante = const Duration(minutes: 15); }),
                    child: const Text('Reiniciar'),
                  ),
                ],
              ),
              if (contador > 0 && contador < 15) ...[
                const SizedBox(height: 8),
                Text(
                  'Faltan ${15 - contador} personas para completar.',
                  style: GoogleFonts.roboto(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple Ticker using AnimationController-less loop
class Ticker {
  final void Function(Duration) onTick;
  late final Stopwatch _sw;
  late final Duration _interval;
  bool _running = false;

  Ticker(this.onTick) {
    _sw = Stopwatch();
    _interval = const Duration(seconds: 1);
  }

  void start() {
    _running = true;
    _sw.start();
    _loop();
  }

  void dispose() { _running = false; _sw.stop(); }

  Future<void> _loop() async {
    while (_running) {
      await Future.delayed(_interval);
      onTick(_sw.elapsed);
    }
  }
}