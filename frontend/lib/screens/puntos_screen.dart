import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PuntosScreen extends StatefulWidget {
  const PuntosScreen({Key? key}) : super(key: key);

  @override
  State<PuntosScreen> createState() => _PuntosScreenState();
}

class _PuntosScreenState extends State<PuntosScreen>
    with TickerProviderStateMixin {
  // ── Estado de balance ──
  Map<String, dynamic>? _balance;
  bool _loadingBalance = true;

  // ── Estado del formulario de reciclaje ──
  List<dynamic> _tiposReciclaje = [];
  int? _tipoSeleccionado;
  int _cantidad = 1;
  bool _enviando = false;

  // ── Historial ──
  List<dynamic> _transacciones = [];
  bool _loadingTransacciones = true;

  // ── Cluster Bully ──
  Map<String, dynamic>? _gatewayStatus;
  int _prevLeaderId = -1;
  bool _leaderChanged = false;
  Timer? _clusterTimer;

  // ── Animaciones ──
  late AnimationController _leaderPulseController;
  late Animation<double> _leaderPulseAnim;
  late AnimationController _changeBannerController;
  late Animation<double> _changeBannerAnim;

  @override
  void initState() {
    super.initState();

    _leaderPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _leaderPulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _leaderPulseController, curve: Curves.easeInOut),
    );

    _changeBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _changeBannerAnim = CurvedAnimation(
      parent: _changeBannerController,
      curve: Curves.easeOut,
    );

    _loadAll();

    // Polling del cluster cada 3 segundos
    _clusterTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshClusterStatus();
    });
  }

  @override
  void dispose() {
    _clusterTimer?.cancel();
    _leaderPulseController.dispose();
    _changeBannerController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _refreshBalance(),
      _loadTiposReciclaje(),
      _loadTransacciones(),
      _refreshClusterStatus(),
    ]);
  }

  Future<void> _refreshBalance() async {
    setState(() => _loadingBalance = true);
    final result = await ApiService.getBalance();
    if (mounted) {
      setState(() {
        _loadingBalance = false;
        if (result['success'] == true) _balance = result['data'];
      });
    }
  }

  Future<void> _loadTiposReciclaje() async {
    final tipos = await ApiService.getTiposReciclaje();
    if (mounted) setState(() => _tiposReciclaje = tipos);
  }

  Future<void> _loadTransacciones() async {
    setState(() => _loadingTransacciones = true);
    final list = await ApiService.getTransacciones();
    if (mounted) {
      setState(() {
        _transacciones = list;
        _loadingTransacciones = false;
      });
    }
  }

  Future<void> _refreshClusterStatus() async {
    final status = await ApiService.getGatewayStatus();
    if (!mounted) return;
    
    // Evitar rebuilds innecesarios cada 3 segundos si no hay cambios
    if (status.toString() != _gatewayStatus.toString()) {
      setState(() {
        _gatewayStatus = status;
        if (status != null) {
          final newLeader = status['currentLeaderId'] as int? ?? -1;
          if (_prevLeaderId != -1 && _prevLeaderId != newLeader && newLeader != -1) {
            _leaderChanged = true;
            _changeBannerController.forward(from: 0);
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) setState(() => _leaderChanged = false);
            });
          }
          _prevLeaderId = newLeader;
        }
      });
    }
  }

  Future<void> _submitReciclaje() async {
    if (_tipoSeleccionado == null) {
      _showSnack('Selecciona un tipo de reciclaje', isError: true);
      return;
    }
    setState(() => _enviando = true);
    final result = await ApiService.registrarReciclaje(
      tipoReciclajeId: _tipoSeleccionado!,
      cantidad: _cantidad,
    );
    if (mounted) {
      setState(() => _enviando = false);
      if (result['success'] == true) {
        final data = result['data'];
        _showSnack(
          '¡+${data['puntos']} EcoPuntos acumulados! 🌱',
          isError: false,
        );
        await Future.wait([_refreshBalance(), _loadTransacciones()]);
      } else {
        _showSnack(result['message'] ?? 'Error al registrar', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ══════════════════════════════════════════════════
  //  UI
  // ══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EcoPuntos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Laboratorio Distribuido',
            icon: const Icon(Icons.science_rounded, color: Color(0xFF8B5CF6)),
            onPressed: () => Navigator.pushNamed(context, '/lab'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: _loadAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1E293B),
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de cambio de líder
              if (_leaderChanged) _buildLeaderChangeBanner(),

              // Balance Card
              _buildBalanceCard(),
              const SizedBox(height: 20),

              // Cluster Bully Visualizer
              _buildBullyClusterPanel(),
              const SizedBox(height: 12),

              // Botón Laboratorio Distribuido
              _buildLabButton(),
              const SizedBox(height: 20),

              // Formulario de reciclaje
              _buildRecycleForm(),
              const SizedBox(height: 20),

              // Historial
              _buildTransaccionesPanel(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Banner de cambio de líder ──────────────────────
  Widget _buildLeaderChangeBanner() {
    final newLeader = _gatewayStatus?['currentLeaderId'] ?? '?';
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_changeBannerAnim),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Cambio de líder! Nodo $newLeader ahora es el coordinador',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Balance Card ────────────────────────────────────
  Widget _buildBalanceCard() {
    final puntos = _balance?['puntosEcologicos'] ?? 0;
    final nombre = _balance?['nombres'] ?? '';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _loadingBalance
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 2,
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isNotEmpty ? 'Hola, $nombre 👋' : 'Mis EcoPuntos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$puntos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'EcoPuntos acumulados',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Cluster Bully Visualizer ────────────────────────
  Widget _buildBullyClusterPanel() {
    final status = _gatewayStatus;
    final leaderId = status?['currentLeaderId'] as int? ?? -1;
    final nodes = (status?['nodes'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Cluster Bully — Estado en Tiempo Real',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (leaderId != -1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                  ),
                  child: Text(
                    'Líder: Nodo $leaderId',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (status == null)
            _buildGatewayOffline()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: nodes.isEmpty
                  ? [_buildNodeCard(1, false, false), _buildNodeCard(2, false, false), _buildNodeCard(3, false, false)]
                  : nodes.map<Widget>((n) {
                      final nodeId = n['nodeId'] as int;
                      final alive = n['alive'] as bool? ?? false;
                      final isLeader = n['isLeader'] as bool? ?? false;
                      return _buildNodeCard(nodeId, alive, isLeader);
                    }).toList(),
            ),

          const SizedBox(height: 12),
          _buildClusterLegend(),
        ],
      ),
    );
  }

  Widget _buildGatewayOffline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gateway no disponible\n(levanta el servicio_gateway en :8080)',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(int nodeId, bool alive, bool isLeader) {
    final Color nodeColor = isLeader
        ? const Color(0xFF10B981)
        : alive
            ? const Color(0xFF3B82F6)
            : const Color(0xFF6B7280);

    return ScaleTransition(
      scale: isLeader ? _leaderPulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: nodeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: nodeColor.withOpacity(isLeader ? 0.8 : 0.4),
            width: isLeader ? 2 : 1,
          ),
          boxShadow: isLeader
              ? [BoxShadow(color: nodeColor.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: nodeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alive ? Icons.dns_rounded : Icons.dns_outlined,
                    color: nodeColor,
                    size: 22,
                  ),
                ),
                if (isLeader)
                  const Positioned(
                    top: -2,
                    right: -2,
                    child: Text('👑', style: TextStyle(fontSize: 14)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nodo $nodeId',
              style: TextStyle(
                color: nodeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: nodeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLeader ? 'LÍDER' : (alive ? 'ACTIVO' : 'CAÍDO'),
                style: TextStyle(
                  color: nodeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(const Color(0xFF10B981), 'Líder'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFF3B82F6), 'Activo'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFF6B7280), 'Caído'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  // ── Formulario de reciclaje ──────────────────────────
  Widget _buildRecycleForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recycling_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Registrar Reciclaje',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de reciclaje
          DropdownButtonFormField<int>(
            value: _tipoSeleccionado,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tipo de material reciclado',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
            items: _tiposReciclaje.map<DropdownMenuItem<int>>((t) {
              return DropdownMenuItem<int>(
                value: t['id'] as int,
                child: Text(
                  '${t['nombre']} — ${t['puntosPorUnidad']} pts/ud',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _tipoSeleccionado = v),
            hint: _tiposReciclaje.isEmpty
                ? const Text('Cargando tipos...', style: TextStyle(color: Colors.white38))
                : const Text('Selecciona un tipo', style: TextStyle(color: Colors.white38)),
          ),
          const SizedBox(height: 14),

          // Cantidad
          Row(
            children: [
              const Text('Cantidad:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => setState(() { if (_cantidad > 1) _cantidad--; }),
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF10B981)),
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  '$_cantidad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _cantidad++),
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enviando ? null : _submitReciclaje,
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.eco_rounded),
              label: Text(_enviando ? 'Registrando...' : 'Acumular EcoPuntos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Historial de transacciones ───────────────────────
  Widget _buildTransaccionesPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Historial de Transacciones',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_loadingTransacciones)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                strokeWidth: 2,
              ),
            )
          else if (_transacciones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, color: Colors.white.withOpacity(0.2), size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Sin transacciones aún',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transacciones.length > 10 ? 10 : _transacciones.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withOpacity(0.05),
                height: 1,
              ),
              itemBuilder: (ctx, i) {
                final t = _transacciones[i];
                final puntos = t['puntos'] as int? ?? 0;
                final tipo = t['tipo'] as String? ?? '';
                final desc = t['descripcion'] as String? ?? '';
                final fecha = t['fecha'] as String? ?? '';
                final lamportTs = t['lamportTimestamp'];
                final nodeId = t['nodeId'];
                final isAcum = tipo == 'ACUMULACION';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (isAcum ? const Color(0xFF10B981) : Colors.redAccent)
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAcum ? Icons.add_rounded : Icons.remove_rounded,
                          color: isAcum ? const Color(0xFF10B981) : Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc.isNotEmpty ? desc : tipo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                if (fecha.isNotEmpty)
                                  Text(
                                    _formatFecha(fecha),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (lamportTs != null && nodeId != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'ts: $lamportTs (Nodo $nodeId)',
                                      style: const TextStyle(
                                        color: Color(0xFF60A5FA),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isAcum ? '+' : '-'}$puntos pts',
                        style: TextStyle(
                          color: isAcum ? const Color(0xFF10B981) : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  // ── Botón Laboratorio Distribuido ─────────────────────
  Widget _buildLabButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/lab'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laboratorio Distribuido',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bully · Lamport · Exclusión Mutua — tiempo real',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

