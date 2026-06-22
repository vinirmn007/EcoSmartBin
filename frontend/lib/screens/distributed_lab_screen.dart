import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// ════════════════════════════════════════════════════════════
///  Pantalla "Laboratorio Distribuido"
///  Muestra en tiempo real los 3 algoritmos del sistema:
///   Tab 0 — ⚡ Bully       (Elección de Líder)
///   Tab 1 — 🕐 Lamport     (Relojes Lógicos)
///   Tab 2 — 🔒 Mutex       (Exclusión Mutua Ricart-Agrawala)
/// ════════════════════════════════════════════════════════════
class DistributedLabScreen extends StatefulWidget {
  const DistributedLabScreen({Key? key}) : super(key: key);

  @override
  State<DistributedLabScreen> createState() => _DistributedLabScreenState();
}

class _DistributedLabScreenState extends State<DistributedLabScreen>
    with TickerProviderStateMixin {

  late TabController _tabController;

  // ── Datos Bully ──
  Map<String, dynamic>? _gatewayStatus;
  int _prevLeaderId = -1;
  bool _leaderChanged = false;

  // ── Datos Lamport ──
  final List<Map<String, dynamic>?> _lamportStatus = [null, null, null];
  bool _triggeringLamport = false;
  int _selectedLamportNode = 0; // nodo desde el cual disparar evento

  // ── Datos Mutex ──
  final List<Map<String, dynamic>?> _mutexStatus = [null, null, null];
  bool _requestingMutex = false;
  int _selectedMutexNode = 0;

  // ── Timers ──
  Timer? _refreshTimer;

  // ── Animaciones ──
  late AnimationController _leaderPulseCtrl;
  late Animation<double> _leaderPulseAnim;
  late AnimationController _heldPulseCtrl;
  late Animation<double> _heldPulseAnim;

  // ── Colores del sistema ──
  static const _bg       = Color(0xFF0F172A);
  static const _surface  = Color(0xFF1E293B);
  static const _green    = Color(0xFF10B981);
  static const _blue     = Color(0xFF3B82F6);
  static const _amber    = Color(0xFFF59E0B);
  static const _red      = Color(0xFFEF4444);
  static const _purple   = Color(0xFF8B5CF6);
  static const _gray     = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _leaderPulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _leaderPulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _leaderPulseCtrl, curve: Curves.easeInOut),
    );

    _heldPulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _heldPulseAnim = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _heldPulseCtrl, curve: Curves.easeInOut),
    );

    _refreshAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshAll());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _leaderPulseCtrl.dispose();
    _heldPulseCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  //  Refresh de todos los estados
  // ──────────────────────────────────────────────────────────

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshBully(),
      _refreshLamport(),
      _refreshMutex(),
    ]);
  }

  Future<void> _refreshBully() async {
    final status = await ApiService.getGatewayStatus();
    if (!mounted) return;
    if (status.toString() != _gatewayStatus.toString()) {
      setState(() {
        _gatewayStatus = status;
        if (status != null) {
          final newLeader = status['currentLeaderId'] as int? ?? -1;
          if (_prevLeaderId != -1 && _prevLeaderId != newLeader && newLeader != -1) {
            _leaderChanged = true;
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) setState(() => _leaderChanged = false);
            });
          }
          _prevLeaderId = newLeader;
        }
      });
    }
  }

  Future<void> _refreshLamport() async {
    final urls = ApiService.nodeUrls;
    final results = await Future.wait(
      urls.map((url) => ApiService.getLamportStatus(url)),
    );
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < results.length; i++) {
        _lamportStatus[i] = results[i];
      }
    });
  }

  Future<void> _refreshMutex() async {
    final urls = ApiService.nodeUrls;
    final results = await Future.wait(
      urls.map((url) => ApiService.getMutexStatus(url)),
    );
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < results.length; i++) {
        _mutexStatus[i] = results[i];
      }
    });
  }

  // ──────────────────────────────────────────────────────────
  //  Acciones de usuario
  // ──────────────────────────────────────────────────────────

  Future<void> _triggerLamportEvent() async {
    setState(() => _triggeringLamport = true);
    final url = ApiService.nodeUrls[_selectedLamportNode];
    await ApiService.triggerLamportEvent(url);
    await _refreshLamport();
    if (mounted) setState(() => _triggeringLamport = false);
  }

  Future<void> _requestMutex() async {
    setState(() => _requestingMutex = true);
    final url = ApiService.nodeUrls[_selectedMutexNode];
    await ApiService.requestMutex(url);
    await _refreshMutex();
    if (mounted) setState(() => _requestingMutex = false);
  }

  Future<void> _releaseMutex(int nodeIndex) async {
    final url = ApiService.nodeUrls[nodeIndex];
    await ApiService.releaseMutex(url);
    await _refreshMutex();
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD principal
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.4)),
              ),
              child: const Icon(Icons.science_rounded, color: _green, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Laboratorio Distribuido',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _green),
            onPressed: _refreshAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _green,
          indicatorWeight: 3,
          labelColor: _green,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.bolt_rounded, size: 18), text: 'Bully'),
            Tab(icon: Icon(Icons.access_time_rounded, size: 18), text: 'Lamport'),
            Tab(icon: Icon(Icons.lock_rounded, size: 18), text: 'Mutex'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBullyTab(),
          _buildLamportTab(),
          _buildMutexTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 0 — BULLY
  // ══════════════════════════════════════════════════════════

  Widget _buildBullyTab() {
    final status = _gatewayStatus;
    final leaderId = status?['currentLeaderId'] as int? ?? -1;
    final nodes = (status?['nodes'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header teórico
          _buildAlgorithmHeader(
            icon: Icons.bolt_rounded,
            color: _amber,
            title: 'Algoritmo Bully',
            description:
                'Elección de líder: el nodo con mayor ID gana. '
                'Si el líder cae, los nodos con menor ID inician una elección '
                'enviando ELECTION. El que no recibe OK se proclama VICTORY.',
          ),
          const SizedBox(height: 20),

          // Banner de cambio de líder
          if (_leaderChanged)
            _buildChangeBanner('¡Nuevo líder elegido! Nodo $leaderId toma el control', _amber),

          // Estado del cluster
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.hub_rounded, _green, 'Estado del Cluster'),
                const SizedBox(height: 16),
                status == null
                    ? _buildOfflineWidget('Gateway no disponible (:8080)')
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: nodes.isEmpty
                            ? List.generate(3, (i) => _buildBullyNode(i + 1, false, false))
                            : nodes.map<Widget>((n) {
                                final nodeId = n['nodeId'] as int;
                                final alive = n['alive'] as bool? ?? false;
                                final isLeader = n['isLeader'] as bool? ?? false;
                                return _buildBullyNode(nodeId, alive, isLeader);
                              }).toList(),
                      ),
                const SizedBox(height: 16),
                _buildLegend([
                  (_green, 'Líder'),
                  (_blue, 'Activo'),
                  (_gray, 'Caído'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info adicional
          if (status != null) ...[
            _buildInfoGrid([
              ('Líder actual', leaderId != -1 ? 'Nodo $leaderId' : 'En elección...'),
              ('Nodos totales', '${nodes.length}'),
              ('Nodos activos', '${nodes.where((n) => n['alive'] == true).length}'),
              ('Algoritmo', 'Bully (Max ID)'),
            ]),
          ],

          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.info_outline_rounded, _blue, 'Cómo demostrarlo'),
                const SizedBox(height: 12),
                _buildStep('1', 'Los 3 nodos están corriendo. El nodo con ID más alto es Líder (👑).'),
                _buildStep('2', 'Cierra el contenedor del nodo líder → los otros detectan que cayó.'),
                _buildStep('3', 'El siguiente nodo inicia ELECTION → gana el de mayor ID activo.'),
                _buildStep('4', 'El nodo recuperado vuelve y reconoce al líder actual.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullyNode(int nodeId, bool alive, bool isLeader) {
    final color = isLeader ? _green : (alive ? _blue : _gray);
    final label = isLeader ? 'LÍDER' : (alive ? 'ACTIVO' : 'CAÍDO');

    return ScaleTransition(
      scale: isLeader ? _leaderPulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(isLeader ? 0.8 : 0.4), width: isLeader ? 2 : 1),
          boxShadow: isLeader ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)] : null,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(alive ? Icons.dns_rounded : Icons.dns_outlined, color: color, size: 22),
                ),
                if (isLeader)
                  const Positioned(top: -2, right: -2,
                    child: Text('👑', style: TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Nodo $nodeId',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 1 — LAMPORT
  // ══════════════════════════════════════════════════════════

  Widget _buildLamportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAlgorithmHeader(
            icon: Icons.access_time_rounded,
            color: _blue,
            title: 'Relojes Lógicos de Lamport',
            description:
                'Sin reloj global, Lamport ordena eventos: '
                '• Evento interno: clock++  '
                '• Envío: clock++ antes de enviar  '
                '• Recepción: clock = max(local, recibido) + 1',
          ),
          const SizedBox(height: 20),

          // Relojes de los 3 nodos
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.schedule_rounded, _blue, 'Relojes en Tiempo Real'),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      child: _buildLamportClock(i),
                    ),
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Control de disparo
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.play_circle_rounded, _green, 'Disparar Evento'),
                const SizedBox(height: 12),
                const Text(
                  'Selecciona el nodo que disparará el evento interno. '
                  'Su reloj sube y propaga el timestamp a los demás.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(3, (i) => Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedLamportNode = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedLamportNode == i
                                ? _blue.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedLamportNode == i
                                  ? _blue.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            'Nodo ${i + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedLamportNode == i ? _blue : Colors.white54,
                              fontWeight: FontWeight.bold, fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _triggeringLamport ? null : _triggerLamportEvent,
                    icon: _triggeringLamport
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.flash_on_rounded),
                    label: Text(_triggeringLamport
                        ? 'Propagando...' : 'Disparar Evento en Nodo ${_selectedLamportNode + 1}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log de eventos del nodo seleccionado
          _buildLamportLog(),
          const SizedBox(height: 16),

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.info_outline_rounded, _blue, 'Cómo demostrarlo'),
                const SizedBox(height: 12),
                _buildStep('1', 'Presiona "Disparar Evento" desde Nodo 1 → su reloj sube.'),
                _buildStep('2', 'Los otros nodos reciben el timestamp y actualizan: max(local, recibido)+1.'),
                _buildStep('3', 'Dispara desde varios nodos y observa cómo los relojes se sincronizan.'),
                _buildStep('4', 'El reloj siempre crece → ordena eventos aunque lleguen desordenados.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLamportClock(int index) {
    final status = _lamportStatus[index];
    final alive = status != null;
    final clock = status?['clock'] as int? ?? 0;
    final nodeId = index + 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alive ? _blue.withOpacity(0.1) : _gray.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alive ? _blue.withOpacity(0.4) : _gray.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('Nodo $nodeId',
            style: TextStyle(color: alive ? _blue : _gray,
              fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: alive ? _blue.withOpacity(0.15) : _gray.withOpacity(0.1),
              border: Border.all(color: alive ? _blue.withOpacity(0.5) : _gray.withOpacity(0.2)),
            ),
            child: Center(
              child: alive
                  ? Text('$clock',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w900))
                  : const Icon(Icons.wifi_off_rounded, color: _gray, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          Text(alive ? 'ts=$clock' : 'Caído',
            style: TextStyle(color: alive ? Colors.white54 : _gray, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLamportLog() {
    final status = _lamportStatus[_selectedLamportNode];
    final events = (status?['eventLog'] as List<dynamic>?) ?? [];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.timeline_rounded, _blue,
            'Log de Eventos — Nodo ${_selectedLamportNode + 1}'),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Sin eventos aún — dispara uno',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
              ),
            )
          else
            ...events.take(10).map((e) {
              final type = e['type'] as String? ?? '';
              final clock = e['clock'];
              final from = e['from'];
              final to = e['to'];
              final ts = e['timestamp'] as String? ?? '';
              return _buildLamportEventRow(type, clock, from, to, ts);
            }),
        ],
      ),
    );
  }

  Widget _buildLamportEventRow(String type, dynamic clock, dynamic from, dynamic to, String ts) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case 'SEND':
        color = _green; icon = Icons.arrow_forward_rounded; label = 'ENVÍO';
        break;
      case 'RECEIVE':
        color = _blue; icon = Icons.arrow_back_rounded; label = 'RECEPCIÓN';
        break;
      case 'INTERNAL':
        color = _purple; icon = Icons.fiber_manual_record_rounded; label = 'INTERNO';
        break;
      case 'SEND_FAILED':
        color = _red; icon = Icons.error_outline_rounded; label = 'ENVÍO FALLIDO';
        break;
      default:
        color = _gray; icon = Icons.circle_outlined; label = type;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('ts=$clock',
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                Text(
                  type == 'SEND' || type == 'SEND_FAILED'
                    ? 'Nodo $from → Nodo $to'
                    : type == 'RECEIVE'
                    ? 'Nodo $from → Nodo $to'
                    : 'Nodo $from',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(ts, style: const TextStyle(color: Colors.white24, fontSize: 9)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 2 — MUTEX (Ricart-Agrawala)
  // ══════════════════════════════════════════════════════════

  Widget _buildMutexTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAlgorithmHeader(
            icon: Icons.lock_rounded,
            color: _purple,
            title: 'Exclusión Mutua — Ricart-Agrawala',
            description:
                'Solo 1 nodo puede estar en la Sección Crítica a la vez. '
                'Solicita ENTER → espera OK de todos → entra. '
                'Salen con RELEASE y notifican a los que esperaban.',
          ),
          const SizedBox(height: 20),

          // Estado de los 3 nodos
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.lock_clock_rounded, _purple, 'Estado de los Nodos'),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      child: _buildMutexNodeCard(i),
                    ),
                  )),
                ),
                const SizedBox(height: 16),
                _buildLegend([
                  (_green, 'HELD (SC)'),
                  (_amber, 'WANTED'),
                  (_gray, 'RELEASED'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Control
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.touch_app_rounded, _green, 'Solicitar Sección Crítica'),
                const SizedBox(height: 12),
                const Text(
                  'El nodo seleccionado enviará REQUEST a los demás. '
                  'Si nadie más quiere entrar, entrará en ~1 segundo.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(3, (i) {
                    final ms = _mutexStatus[i];
                    final state = ms?['state'] as String? ?? 'RELEASED';
                    final available = state == 'RELEASED';
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      child: Expanded(
                        child: GestureDetector(
                          onTap: available ? () => setState(() => _selectedMutexNode = i) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMutexNode == i && available
                                  ? _purple.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedMutexNode == i && available
                                    ? _purple.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text('Nodo ${i + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: available
                                        ? (_selectedMutexNode == i ? _purple : Colors.white54)
                                        : _gray,
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(state, textAlign: TextAlign.center,
                                  style: TextStyle(color: _stateColor(state), fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _requestingMutex ? null : _requestMutex,
                        icon: _requestingMutex
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : const Icon(Icons.lock_open_rounded),
                        label: Text(_requestingMutex
                            ? 'Esperando OKs...' : 'Solicitar SC (Nodo ${_selectedMutexNode + 1})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                // Botón de liberar si algún nodo está en HELD
                ...List.generate(3, (i) {
                  final ms = _mutexStatus[i];
                  final state = ms?['state'] as String? ?? 'RELEASED';
                  if (state != 'HELD') return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => _releaseMutex(i),
                      icon: const Icon(Icons.lock_open_rounded, size: 16),
                      label: Text('Liberar SC — Nodo ${i + 1}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: BorderSide(color: _red.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log del nodo seleccionado
          _buildMutexLog(),
          const SizedBox(height: 16),

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.info_outline_rounded, _purple, 'Cómo demostrarlo'),
                const SizedBox(height: 12),
                _buildStep('1', 'Solicita SC desde Nodo 1 → envía REQUEST a Nodo 2 y 3.'),
                _buildStep('2', 'Si Nodo 2 también solicita → el de menor timestamp gana.'),
                _buildStep('3', 'El ganador entra a HELD (verde) por 3 segundos automáticamente.'),
                _buildStep('4', 'Al salir, envía OK al que estaba esperando → ese entra.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutexNodeCard(int index) {
    final status = _mutexStatus[index];
    final alive = status != null;
    final state = status?['state'] as String? ?? 'RELEASED';
    final clock = status?['clock'] as int? ?? 0;
    final queue = (status?['deferredQueue'] as List<dynamic>?) ?? [];
    final color = _stateColor(state);
    final isHeld = state == 'HELD';

    return ScaleTransition(
      scale: isHeld ? _heldPulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(isHeld ? 0.9 : 0.4),
            width: isHeld ? 2 : 1),
          boxShadow: isHeld ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)] : null,
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(
                isHeld ? Icons.lock_rounded
                    : state == 'WANTED' ? Icons.pending_rounded
                    : Icons.lock_open_rounded,
                color: color, size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text('Nodo ${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(state,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
            if (alive) ...[
              const SizedBox(height: 4),
              Text('ts=$clock',
                style: const TextStyle(color: Colors.white38, fontSize: 9)),
            ],
            if (queue.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Cola: $queue',
                style: TextStyle(color: _amber, fontSize: 9),
                textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMutexLog() {
    final status = _mutexStatus[_selectedMutexNode];
    final events = (status?['eventLog'] as List<dynamic>?) ?? [];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.list_alt_rounded, _purple,
            'Log de Mutex — Nodo ${_selectedMutexNode + 1}'),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Sin eventos — solicita la SC',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
              ),
            )
          else
            ...events.take(10).map((e) {
              final type = e['type'] as String? ?? '';
              final clock = e['clock'];
              final detail = e['detail'] as String? ?? '';
              final ts = e['timestamp'] as String? ?? '';
              return _buildMutexEventRow(type, clock, detail, ts);
            }),
        ],
      ),
    );
  }

  Widget _buildMutexEventRow(String type, dynamic clock, String detail, String ts) {
    Color color;
    IconData icon;

    switch (type) {
      case 'REQUEST':       color = _amber;  icon = Icons.send_rounded; break;
      case 'OK_SENT':       color = _green;  icon = Icons.check_circle_rounded; break;
      case 'OK_RECEIVED':   color = _green;  icon = Icons.check_rounded; break;
      case 'DEFERRED':      color = _amber;  icon = Icons.pause_circle_rounded; break;
      case 'ENTER_SC':      color = _purple; icon = Icons.lock_rounded; break;
      case 'RELEASE_SC':    color = _blue;   icon = Icons.lock_open_rounded; break;
      case 'OK_DEFERRED_RECEIVED': color = _green; icon = Icons.done_all_rounded; break;
      default:              color = _gray;   icon = Icons.circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(type,
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('ts=$clock',
                      style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
                  ],
                ),
                Text(detail,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(ts, style: const TextStyle(color: Colors.white24, fontSize: 9)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  WIDGETS COMPARTIDOS
  // ══════════════════════════════════════════════════════════

  Widget _buildAlgorithmHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                  style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _buildCardHeader(IconData icon, Color color, String title) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildOfflineWidget(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: _red, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
            style: const TextStyle(color: _red, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildChangeBanner(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildLegend(List<(Color, String)> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(color: item.$1, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(item.$2,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _green.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(num,
                style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<(String, String)> items) {
    return _buildCard(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: items.map((item) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.$1, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            Text(item.$2,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        )).toList(),
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'HELD':     return _green;
      case 'WANTED':   return _amber;
      default:         return _gray;
    }
  }
}
