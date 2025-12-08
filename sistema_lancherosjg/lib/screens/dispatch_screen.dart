import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/viaje_model.dart';
import '../models/cola_model.dart';
import '../providers/cola_provider.dart';
import '../providers/configuracion_provider.dart';
import '../providers/firebase_provider.dart';

/// Pantalla "La Tabla" - Registro de viajes completados
/// Muestra los 5 pontones activos y permite registrar pasajeros
class DispatchScreen extends ConsumerStatefulWidget {
  const DispatchScreen({super.key});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  ColaPonton? _pontonSeleccionado;
  
  // Guardar datos individuales por cada pontón (Map<idPonton, Map<tipoPasajero, cantidad>>)
  final Map<String, Map<String, int>> _datosPorPonton = {};
  final Map<String, String> _notasPorPonton = {};
  final Map<String, bool> _vacioAIslaPorPonton = {};
  
  bool _registrando = false;

  // Obtener contadores del pontón actual
  Map<String, int> get _contadorPasajeros {
    if (_pontonSeleccionado == null) {
      return {
        'adulto': 0,
        'nino': 0,
        'inapam': 0,
        'especial': 0,
        'trabajador': 0,
        'cortesia': 0,
      };
    }
    return _datosPorPonton.putIfAbsent(_pontonSeleccionado!.idPonton, () => {
      'adulto': 0,
      'nino': 0,
      'inapam': 0,
      'especial': 0,
      'trabajador': 0,
      'cortesia': 0,
    });
  }

  String get _nota {
    if (_pontonSeleccionado == null) return '';
    return _notasPorPonton[_pontonSeleccionado!.idPonton] ?? '';
  }

  set _nota(String value) {
    if (_pontonSeleccionado != null) {
      _notasPorPonton[_pontonSeleccionado!.idPonton] = value;
    }
  }

  bool get _esVacioAIsla {
    if (_pontonSeleccionado == null) return false;
    return _vacioAIslaPorPonton[_pontonSeleccionado!.idPonton] ?? false;
  }

  set _esVacioAIsla(bool value) {
    if (_pontonSeleccionado != null) {
      _vacioAIslaPorPonton[_pontonSeleccionado!.idPonton] = value;
    }
  }

  void _resetearContadores() {
    setState(() {
      if (_pontonSeleccionado != null) {
        _datosPorPonton.remove(_pontonSeleccionado!.idPonton);
        _notasPorPonton.remove(_pontonSeleccionado!.idPonton);
        _vacioAIslaPorPonton.remove(_pontonSeleccionado!.idPonton);
      }
      _pontonSeleccionado = null;
    });
  }

  int get _totalPasajeros => _contadorPasajeros.values.fold(0, (a, b) => a + b);

  Future<void> _registrarViaje() async {
    if (_pontonSeleccionado == null) {
      _mostrarError('Selecciona un pontón');
      return;
    }

    if (_totalPasajeros == 0 && !_esVacioAIsla) {
      _mostrarError('Ingresa al menos un pasajero o marca "Vacío a isla"');
      return;
    }

    setState(() => _registrando = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final precios = ref.read(preciosProvider);

      // Calcular monto
      double montoCalculado = 0;
      for (var entry in _contadorPasajeros.entries) {
        montoCalculado += (precios[entry.key] ?? 0) * entry.value;
      }

      final viaje = Viaje(
        id: '',
        fecha: DateTime.now(),
        idPonton: _pontonSeleccionado!.idPonton,
        nombrePonton: _pontonSeleccionado!.nombrePonton,
        nombreChofer: _pontonSeleccionado!.nombreChofer,
        desglosePasajeros: Map.from(_contadorPasajeros)
          ..removeWhere((key, value) => value == 0),
        finanzas: {
          'calculado': montoCalculado,
          'cobrado_real': montoCalculado,
          'nota': _nota.isEmpty ? null : _nota,
        },
        vacioAIsla: _esVacioAIsla,
        numeroVuelta: _pontonSeleccionado!.vueltasHoy + 1,
      );

      await firebaseService.registrarViaje(viaje);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Viaje registrado: ${_pontonSeleccionado!.nombrePonton}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _resetearContadores();
      }
    } catch (e) {
      _mostrarError('Error al registrar: $e');
    } finally {
      setState(() => _registrando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colaOrganizada = ref.watch(colaOrganizadaProvider);
    final precios = ref.watch(preciosProvider);
    
    // Los pontones activos son: cargando + cuadro
    final pontonesActivos = [
      ...colaOrganizada['cargando']!,
      ...colaOrganizada['cuadro']!,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'La Tabla - Registro',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Panel izquierdo: Pontones activos (cargando + cuadro)
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF132337),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PONTONES ACTIVOS',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: pontonesActivos.isEmpty
                        ? Center(
                            child: Text(
                              'No hay pontones en servicio',
                              style: GoogleFonts.roboto(
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pontonesActivos.length,
                            itemBuilder: (context, index) {
                              final ponton = pontonesActivos[index];
                              final esSeleccionado =
                                  _pontonSeleccionado?.idPonton ==
                                      ponton.idPonton;
                              
                              // Está cargando si tiene pasajeros abordo
                              final esCargando = ponton.tienePasajeros;

                              return _TarjetaPontonActivo(
                                ponton: ponton,
                                esSeleccionado: esSeleccionado,
                                esCargando: esCargando,
                                posicion: index + 1,
                                onTap: () {
                                  setState(() {
                                    _pontonSeleccionado = ponton;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Panel derecho: Formulario de registro
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: _pontonSeleccionado == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 80,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Selecciona un pontón para registrar el viaje',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Pontón seleccionado
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A5F), Color(0xFF2D5F8D)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_boat,
                                    color: Colors.white, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pontonSeleccionado!.nombrePonton,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _pontonSeleccionado!.nombreChofer,
                                        style: GoogleFonts.roboto(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Checkbox: Ida vacía a isla
                          CheckboxListTile(
                            title: Text(
                              'Ida vacía a la isla',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: _esVacioAIsla,
                            onChanged: (value) {
                              setState(() {
                                _esVacioAIsla = value ?? false;
                                if (_esVacioAIsla) {
                                  _contadorPasajeros.updateAll((k, v) => 0);
                                }
                              });
                            },
                            activeColor: Colors.orange,
                            checkColor: Colors.white,
                            tileColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Contadores de pasajeros
                          if (!_esVacioAIsla) ...[
                            Text(
                              'PASAJEROS',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._ordenTiposPasajeros.map((tipo) {
                              final precio = precios[tipo] ?? 0.0;
                              return _ContadorPasajeros(
                                titulo: _formatearTipo(tipo),
                                precio: precio,
                                valor: _contadorPasajeros[tipo] ?? 0,
                                onChanged: (nuevoValor) async {
                                  setState(() {
                                    if (_pontonSeleccionado != null) {
                                      final contadores = _datosPorPonton.putIfAbsent(
                                        _pontonSeleccionado!.idPonton,
                                        () => {
                                          'adulto': 0,
                                          'nino': 0,
                                          'inapam': 0,
                                          'especial': 0,
                                          'trabajador': 0,
                                          'cortesia': 0,
                                        },
                                      );
                                      contadores[tipo] = nuevoValor;
                                    }
                                  });
                                  
                                  // Marcar el pontón como "tiene pasajeros" en Firestore
                                  if (_pontonSeleccionado != null) {
                                    final tienePasajeros = _contadorPasajeros.values.any((v) => v > 0);
                                    final firebaseService = ref.read(firebaseServiceProvider);
                                    await firebaseService.actualizarTienePasajeros(
                                      _pontonSeleccionado!.idPonton,
                                      tienePasajeros,
                                    );
                                  }
                                },
                              );
                            }),
                            const SizedBox(height: 24),

                            // Total
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL PASAJEROS',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$_totalPasajeros',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nota opcional
                            TextField(
                              onChanged: (value) => _nota = value,
                              style: GoogleFonts.roboto(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Nota (opcional)',
                                labelStyle: GoogleFonts.roboto(color: Colors.white70),
                                hintText: 'Ej: Tickets de taquilla',
                                hintStyle: GoogleFonts.roboto(color: Colors.white38),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _registrando ? null : _resetearContadores,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Colors.white54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _registrando ? null : _registrarViaje,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _registrando
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text(
                                          'Registrar Viaje',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Orden estático de tipos de pasajeros para mantener consistencia
  static const List<String> _ordenTiposPasajeros = [
    'adulto',
    'nino',
    'inapam',
    'especial',
    'trabajador',
    'cortesia',
  ];

  String _formatearTipo(String tipo) {
    final map = {
      'adulto': 'Adulto',
      'nino': 'Niño',
      'inapam': 'INAPAM',
      'especial': 'Especial',
      'trabajador': 'Trabajador',
      'cortesia': 'Cortesía',
    };
    return map[tipo] ?? tipo;
  }
}

/// Tarjeta de pontón activo (lista izquierda)
class _TarjetaPontonActivo extends StatelessWidget {
  final ColaPonton ponton;
  final bool esSeleccionado;
  final bool esCargando;
  final int posicion;
  final VoidCallback onTap;

  const _TarjetaPontonActivo({
    required this.ponton,
    required this.esSeleccionado,
    required this.esCargando,
    required this.posicion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esSeleccionado
                  ? Colors.orange.withOpacity(0.3)
                  : esCargando
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: esSeleccionado
                    ? Colors.orange
                    : esCargando
                        ? Colors.green
                        : Colors.white24,
                width: esSeleccionado ? 3 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: esCargando ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$posicion',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ponton.nombrePonton,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ponton.nombreChofer,
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (ponton.vueltasHoy > 0)
                        Text(
                          '${ponton.vueltasHoy} vueltas',
                          style: GoogleFonts.roboto(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (esCargando)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CARGANDO',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contador de pasajeros con botones +/-
class _ContadorPasajeros extends StatelessWidget {
  final String titulo;
  final double precio;
  final int valor;
  final ValueChanged<int> onChanged;

  const _ContadorPasajeros({
    required this.titulo,
    required this.precio,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(precio),
                  style: GoogleFonts.roboto(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: valor > 0 ? () => onChanged(valor - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.white,
                disabledColor: Colors.white24,
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$valor',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(valor + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
