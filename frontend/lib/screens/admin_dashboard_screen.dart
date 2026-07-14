import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Datos locales
  List<dynamic> _usuarios = [];
  List<dynamic> _recompensas = [];
  List<dynamic> _canjes = [];

  bool _loadingUsuarios = false;
  bool _loadingRecompensas = false;
  bool _loadingCanjes = false;

  // Filtros de búsqueda
  String _searchUsuario = '';
  String _searchRecompensa = '';
  String _filterCanjeEstado = 'TODOS';

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _fetchRecompensas();
    _fetchCanjes();
  }

  // ── Fetching Data ──────────────────────────────────────────────────────────

  Future<void> _fetchUsuarios() async {
    setState(() => _loadingUsuarios = true);
    final users = await ApiService.getAdminUsuarios();
    if (mounted) {
      setState(() {
        _usuarios = users;
        _loadingUsuarios = false;
      });
    }
  }

  Future<void> _fetchRecompensas() async {
    setState(() => _loadingRecompensas = true);
    final rewards = await ApiService.getAdminRecompensas();
    if (mounted) {
      setState(() {
        _recompensas = rewards;
        _loadingRecompensas = false;
      });
    }
  }

  Future<void> _fetchCanjes() async {
    setState(() => _loadingCanjes = true);
    final claims = await ApiService.getAdminCanjes();
    if (mounted) {
      setState(() {
        _canjes = claims;
        _loadingCanjes = false;
      });
    }
  }

  // ── Acciones de Recompensas ────────────────────────────────────────────────

  Future<void> _showRecompensaDialog({Map<String, dynamic>? recompensa}) async {
    final isEdit = recompensa != null;
    final nameController = TextEditingController(text: isEdit ? recompensa['nombre'] : '');
    final descController = TextEditingController(text: isEdit ? recompensa['descripcion'] : '');
    final ptsController = TextEditingController(text: isEdit ? recompensa['costoPuntos'].toString() : '100');
    final stockController = TextEditingController(text: isEdit ? recompensa['stock'].toString() : '10');
    bool activa = isEdit ? (recompensa['activa'] ?? true) : true;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(
                isEdit ? 'Editar Recompensa' : 'Nueva Recompensa',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ptsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Costo en EcoPuntos',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator: (value) => int.tryParse(value ?? '') == null ? 'Ingresa un número válido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Stock Inicial',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        validator: (value) => int.tryParse(value ?? '') == null ? 'Ingresa un número válido' : null,
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Activa y Canjeable:', style: TextStyle(color: Colors.white70)),
                            const Spacer(),
                            Switch(
                              value: activa,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) {
                                setDialogState(() => activa = val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'nombre': nameController.text.trim(),
                        'descripcion': descController.text.trim(),
                        'costoPuntos': int.parse(ptsController.text),
                        'stock': int.parse(stockController.text),
                        'activa': activa,
                        'imagenUrl': isEdit ? recompensa['imagenUrl'] : null,
                      };

                      Map<String, dynamic> result;
                      if (isEdit) {
                        result = await ApiService.actualizarRecompensa(recompensa['id'], data);
                      } else {
                        result = await ApiService.crearRecompensa(data);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        _showSnackBar(result['success']
                            ? (isEdit ? 'Recompensa actualizada' : 'Recompensa creada')
                            : (result['message'] ?? 'Error procesando solicitud'));
                        _fetchRecompensas();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _desactivarRecompensa(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Desactivar Recompensa', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas desactivar esta recompensa? No se mostrará en el catálogo.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sí, Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.desactivarRecompensa(id);
      if (mounted) {
        _showSnackBar(res['success'] ? 'Recompensa desactivada' : (res['message'] ?? 'Error'));
        _fetchRecompensas();
      }
    }
  }

  // ── Acciones de Canjes ──────────────────────────────────────────────────────

  Future<void> _cambiarEstadoCanje(int id, String nuevoEstado) async {
    final actionName = nuevoEstado == 'ENTREGADO' ? 'entregar' : 'cancelar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('${actionName.toUpperCase()} Canje', style: const TextStyle(color: Colors.white)),
        content: Text('¿Deseas marcar este canje como $nuevoEstado?${nuevoEstado == 'CANCELADO' ? ' Se devolverán los puntos y repondrá el stock.' : ''}', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado == 'ENTREGADO' ? const Color(0xFF10B981) : Colors.redAccent,
            ),
            child: const Text('Sí, Proceder'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.cambiarEstadoCanje(id, nuevoEstado);
      if (mounted) {
        _showSnackBar(res['success'] ? 'Estado actualizado a $nuevoEstado' : (res['message'] ?? 'Error'));
        _fetchCanjes();
        _fetchUsuarios(); // refrescar puntos de usuarios si fue cancelado
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          title: const Text(
            'Panel de Administrador 🔧',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF10B981),
            labelColor: Color(0xFF10B981),
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Usuarios'),
              Tab(icon: Icon(Icons.card_giftcard_rounded), text: 'Recompensas'),
              Tab(icon: Icon(Icons.local_shipping_rounded), text: 'Canjes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsuariosTab(),
            _buildRecompensasTab(),
            _buildCanjesTab(),
          ],
        ),
      ),
    );
  }

  // ── VISTAS DE TABS ──────────────────────────────────────────────────────────

  Widget _buildUsuariosTab() {
    final filtered = _usuarios.where((u) {
      final query = _searchUsuario.toLowerCase();
      final nombres = (u['nombres'] ?? '').toString().toLowerCase();
      final apellidos = (u['apellidos'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final cedula = (u['cedula'] ?? '').toString().toLowerCase();
      return nombres.contains(query) || apellidos.contains(query) || email.contains(query) || cedula.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o cédula...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchUsuario = val),
          ),
        ),
        Expanded(
          child: _loadingUsuarios
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF10B981))))
              : RefreshIndicator(
                  onRefresh: _fetchUsuarios,
                  color: const Color(0xFF10B981),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final u = filtered[index];
                      final role = u['role'] ?? 'user';
                      final isAdmin = role.toString().toLowerCase() == 'admin';

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isAdmin ? Colors.blue.withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                            child: Icon(
                              isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                              color: isAdmin ? Colors.blue : const Color(0xFF10B981),
                            ),
                          ),
                          title: Text(
                            '${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Email: ${u['email'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text('Cédula: ${u['cedula'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${u['puntos_ecologicos'] ?? 0} pts',
                                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin ? Colors.blue.withOpacity(0.2) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  role.toString().toUpperCase(),
                                  style: TextStyle(color: isAdmin ? Colors.blueAccent : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecompensasTab() {
    final filtered = _recompensas.where((r) {
      final query = _searchRecompensa.toLowerCase();
      final name = (r['nombre'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecompensaDialog(),
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar recompensa por nombre...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchRecompensa = val),
            ),
          ),
          Expanded(
            child: _loadingRecompensas
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF10B981))))
                : RefreshIndicator(
                    onRefresh: _fetchRecompensas,
                    color: const Color(0xFF10B981),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final r = filtered[index];
                        final activa = r['activa'] ?? true;

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              r['nombre'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: activa ? TextDecoration.none : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(r['descripcion'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Stock: ${r['stock'] ?? 0}',
                                        style: TextStyle(
                                          color: (r['stock'] ?? 0) <= 0 ? Colors.redAccent : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: activa ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        activa ? 'ACTIVA' : 'INACTIVA',
                                        style: TextStyle(
                                          color: activa ? const Color(0xFF10B981) : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${r['costoPuntos'] ?? 0} pts',
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Colors.white60),
                                  onPressed: () => _showRecompensaDialog(recompensa: r),
                                ),
                                if (activa)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _desactivarRecompensa(r['id']),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanjesTab() {
    final filtered = _canjes.where((c) {
      if (_filterCanjeEstado == 'TODOS') return true;
      return c['estado'].toString().toUpperCase() == _filterCanjeEstado;
    }).toList();

    return Column(
      children: [
        // Selector de filtro de estado
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['TODOS', 'PENDIENTE', 'ENTREGADO', 'CANCELADO'].map((est) {
                final selected = _filterCanjeEstado == est;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      est,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _filterCanjeEstado = est);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _loadingCanjes
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF10B981))))
              : RefreshIndicator(
                  onRefresh: _fetchCanjes,
                  color: const Color(0xFF10B981),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final estado = c['estado'].toString().toUpperCase();
                      final isPending = estado == 'PENDIENTE';

                      Color badgeColor;
                      switch (estado) {
                        case 'ENTREGADO':
                          badgeColor = const Color(0xFF10B981);
                          break;
                        case 'CANCELADO':
                          badgeColor = Colors.redAccent;
                          break;
                        default:
                          badgeColor = Colors.amber;
                      }

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                c['recompensaNombre'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    'Usuario: ${c['usuarioNombre'] ?? 'Cargando...'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Email: ${c['usuarioEmail'] ?? ''}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha: ${c['fecha']?.toString().split('T').first ?? ''}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-${c['puntosGastados'] ?? 0} pts',
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      estado,
                                      style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPending) ...[
                              const Divider(color: Colors.white10, height: 1),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _cambiarEstadoCanje(c['id'], 'CANCELADO'),
                                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                                      label: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _cambiarEstadoCanje(c['id'], 'ENTREGADO'),
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      label: const Text('Marcar Entregado'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
