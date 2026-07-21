import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

part 'admin_recompensas_view.dart';

class AdminRecompensasScreen extends StatefulWidget {
  const AdminRecompensasScreen({Key? key}) : super(key: key);

  @override
  State<AdminRecompensasScreen> createState() => _AdminRecompensasScreenState();
}

class _AdminRecompensasScreenState extends State<AdminRecompensasScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _recompensas = [];
  List<dynamic> _canjes = [];
  late TabController _tabController;

  // Filtros, búsqueda y ordenamiento de Canjes
  String _canjesFilterEstado = 'TODOS'; // 'TODOS', 'PENDIENTE', 'ENTREGADO', 'CANCELADO'
  String _canjesSearchQuery = '';
  String _canjesSortBy = 'fecha_desc'; // 'fecha_desc', 'fecha_asc', 'nombre_asc', 'nombre_desc'

  // Ordenamiento de Recompensas
  String _recompensasSortBy = 'nombre_asc'; // 'nombre_asc', 'nombre_desc', 'costo_asc', 'costo_desc'

  List<dynamic> get _canjesFiltrados {
    var list = _canjes.where((c) {
      // 1. Filtro por estado
      final estado = (c['estado'] ?? '').toString().toUpperCase();
      if (_canjesFilterEstado != 'TODOS' && estado != _canjesFilterEstado) {
        return false;
      }

      // 2. Búsqueda por texto (usuarioNombre, usuarioEmail, usuarioId, recompensaNombre)
      if (_canjesSearchQuery.trim().isNotEmpty) {
        final q = _canjesSearchQuery.trim().toLowerCase();
        final userNombre = (c['usuarioNombre'] ?? '').toString().toLowerCase();
        final userEmail = (c['usuarioEmail'] ?? '').toString().toLowerCase();
        final userId = (c['usuarioId'] ?? '').toString().toLowerCase();
        final recompensa = (c['recompensaNombre'] ?? '').toString().toLowerCase();
        final match = userNombre.contains(q) ||
            userEmail.contains(q) ||
            userId.contains(q) ||
            recompensa.contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();

    // 3. Ordenamiento
    list.sort((a, b) {
      switch (_canjesSortBy) {
        case 'nombre_asc':
          final nameA = (a['recompensaNombre'] ?? a['usuarioNombre'] ?? '').toString().toLowerCase();
          final nameB = (b['recompensaNombre'] ?? b['usuarioNombre'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        case 'nombre_desc':
          final nameA = (a['recompensaNombre'] ?? a['usuarioNombre'] ?? '').toString().toLowerCase();
          final nameB = (b['recompensaNombre'] ?? b['usuarioNombre'] ?? '').toString().toLowerCase();
          return nameB.compareTo(nameA);
        case 'fecha_asc':
          final dateA = a['fecha'] != null ? DateTime.tryParse(a['fecha'].toString()) ?? DateTime(1970) : DateTime(1970);
          final dateB = b['fecha'] != null ? DateTime.tryParse(b['fecha'].toString()) ?? DateTime(1970) : DateTime(1970);
          return dateA.compareTo(dateB);
        case 'fecha_desc':
        default:
          final dateA = a['fecha'] != null ? DateTime.tryParse(a['fecha'].toString()) ?? DateTime(1970) : DateTime(1970);
          final dateB = b['fecha'] != null ? DateTime.tryParse(b['fecha'].toString()) ?? DateTime(1970) : DateTime(1970);
          return dateB.compareTo(dateA);
      }
    });

    return list;
  }

  List<dynamic> get _recompensasOrdenadas {
    var list = List<dynamic>.from(_recompensas);
    list.sort((a, b) {
      switch (_recompensasSortBy) {
        case 'nombre_desc':
          final nameA = (a['nombre'] ?? '').toString().toLowerCase();
          final nameB = (b['nombre'] ?? '').toString().toLowerCase();
          return nameB.compareTo(nameA);
        case 'costo_asc':
          final costoA = (a['costoPuntos'] ?? 0) as int;
          final costoB = (b['costoPuntos'] ?? 0) as int;
          return costoA.compareTo(costoB);
        case 'costo_desc':
          final costoA = (a['costoPuntos'] ?? 0) as int;
          final costoB = (b['costoPuntos'] ?? 0) as int;
          return costoB.compareTo(costoA);
        case 'nombre_asc':
        default:
          final nameA = (a['nombre'] ?? '').toString().toLowerCase();
          final nameB = (b['nombre'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
      }
    });
    return list;
  }

  // Formulario de recompensa
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _costoController = TextEditingController();
  final _stockController = TextEditingController();
  final _imagenUrlController = TextEditingController();
  bool _activa = true;
  int? _editingRecompensaId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final recompensas = await ApiService.getTodasRecompensas();
    final canjes = await ApiService.getTodosCanjes();
    if (mounted) {
      setState(() {
        _recompensas = recompensas;
        _canjes = canjes;
        _isLoading = false;
      });
    }
  }

  Future<void> _crearRecompensa() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'costoPuntos': int.parse(_costoController.text.trim()),
      'stock': int.parse(_stockController.text.trim()),
      'imagenUrl': _imagenUrlController.text.trim().isNotEmpty
          ? _imagenUrlController.text.trim()
          : null,
      'activa': _activa,
    };

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creando recompensa...')),
    );

    final res = await ApiService.crearRecompensa(data);

    if (mounted) {
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recompensa creada exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _limpiarFormulario();
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res['message']}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _actualizarRecompensa() async {
    if (_editingRecompensaId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'costoPuntos': int.parse(_costoController.text.trim()),
      'stock': int.parse(_stockController.text.trim()),
      'imagenUrl': _imagenUrlController.text.trim().isNotEmpty
          ? _imagenUrlController.text.trim()
          : null,
      'activa': _activa,
    };

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Actualizando recompensa...')),
    );

    final res = await ApiService.actualizarRecompensa(
      _editingRecompensaId!,
      data,
    );

    if (mounted) {
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recompensa actualizada exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _limpiarFormulario();
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res['message']}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _toggleActivaRecompensa(Map<String, dynamic> recompensa) async {
    final id = recompensa['id'] as int;
    final currentActiva = recompensa['activa'] ?? true;

    if (currentActiva) {
      // Desactivar
      final res = await ApiService.desactivarRecompensa(id);
      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recompensa desactivada'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
          _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${res['message']}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // Activar: usamos actualizar con activa=true
      final data = {
        'nombre': recompensa['nombre'],
        'descripcion': recompensa['descripcion'],
        'costoPuntos': recompensa['costoPuntos'],
        'stock': recompensa['stock'],
        'imagenUrl': recompensa['imagenUrl'],
        'activa': true,
      };
      final res = await ApiService.actualizarRecompensa(id, data);
      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recompensa activada exitosamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${res['message']}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _cambiarEstadoCanje(int canjeId, String nuevoEstado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          nuevoEstado == 'ENTREGADO'
              ? '¿Marcar como Entregado?'
              : '¿Cancelar este Canje?',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          nuevoEstado == 'ENTREGADO'
              ? 'Se confirmará la entrega de esta recompensa al usuario.'
              : 'Se cancelará el canje y se devolverán los puntos al usuario.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Volver',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado == 'ENTREGADO'
                  ? AppColors.emeraldGlow
                  : AppColors.error.withOpacity(0.12),
              foregroundColor: nuevoEstado == 'ENTREGADO'
                  ? AppColors.deepObsidian
                  : AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              nuevoEstado == 'ENTREGADO' ? 'Confirmar Entrega' : 'Cancelar Canje',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Actualizando estado del canje...')),
    );

    final res = await ApiService.cambiarEstadoCanje(canjeId, nuevoEstado);

    if (mounted) {
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nuevoEstado == 'ENTREGADO'
                ? 'Canje marcado como entregado ✓'
                : 'Canje cancelado — puntos devueltos'),
            backgroundColor: nuevoEstado == 'ENTREGADO'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
          ),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res['message']}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _mostrarModalCreacion() {
    _editingRecompensaId = null;
    _limpiarFormulario();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetForm(isEditing: false),
    );
  }

  void _mostrarModalEdicion(Map<String, dynamic> recompensa) {
    _editingRecompensaId = recompensa['id'] as int;
    _nombreController.text = recompensa['nombre'] ?? '';
    _descripcionController.text = recompensa['descripcion'] ?? '';
    _costoController.text = (recompensa['costoPuntos'] ?? 0).toString();
    _stockController.text = (recompensa['stock'] ?? 0).toString();
    _imagenUrlController.text = recompensa['imagenUrl'] ?? '';
    _activa = recompensa['activa'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetForm(isEditing: true),
    );
  }

  Widget _buildBottomSheetForm({required bool isEditing}) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 12,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.5),
            ),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isEditing ? 'Editar Recompensa' : 'Nueva Recompensa',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nombreController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Nombre de la recompensa'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Descripción'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costoController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration('Costo (puntos)'),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requerido';
                            if (int.tryParse(val) == null) return 'Número inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration('Stock'),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requerido';
                            if (int.tryParse(val) == null) return 'Número inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imagenUrlController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('URL de imagen (opcional)'),
                  ),
                  // Image preview
                  if (_imagenUrlController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imagenUrlController.text.trim(),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: AppColors.textSecondary, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setModalState(() {});
                    },
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.emeraldGlow, size: 18),
                    label: Text(
                      'Previsualizar imagen',
                      style: GoogleFonts.poppins(
                        color: AppColors.emeraldGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(
                      'Recompensa Activa',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Si se desactiva, no será visible para los usuarios.',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    value: _activa,
                    activeColor: AppColors.emeraldGlow,
                    onChanged: (val) {
                      setModalState(() {
                        _activa = val;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: isEditing ? _actualizarRecompensa : _crearRecompensa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGlow,
                      foregroundColor: AppColors.deepObsidian,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEditing ? 'GUARDAR CAMBIOS' : 'CREAR RECOMPENSA',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.7),
        fontSize: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.emeraldGlow, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _costoController.clear();
    _stockController.clear();
    _imagenUrlController.clear();
    _activa = true;
    _editingRecompensaId = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    _stockController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/admin');
          }
        }
      },
      child: _AdminRecompensasView(state: this),
    );
  }
}
