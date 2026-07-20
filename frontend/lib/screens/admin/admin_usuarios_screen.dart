import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

part 'admin_usuarios_view.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  bool _isLoading = true;
  List<dynamic> _usuarios = [];

  // Controladores del formulario de edición
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _facultadController = TextEditingController();
  String _role = 'user';
  bool _isActive = true;
  String? _editingUserId;

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getUsuarios();
    if (mounted) {
      setState(() {
        _usuarios = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarUsuario() async {
    if (_editingUserId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombres': _nombresController.text.trim(),
      'apellidos': _apellidosController.text.trim(),
      'email': _emailController.text.trim(),
      'cedula': _cedulaController.text.trim(),
      'telefono': _telefonoController.text.trim().isNotEmpty 
          ? _telefonoController.text.trim() 
          : null,
      'facultad': _facultadController.text.trim().isNotEmpty 
          ? _facultadController.text.trim() 
          : null,
      'role': _role,
      'is_active': _isActive,
    };

    // Cerramos el modal primero
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Actualizando usuario...')),
    );

    final res = await ApiService.actualizarUsuario(_editingUserId!, data);

    if (mounted) {
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _fetchUsuarios();
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

  Future<void> _eliminarUsuario(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          '¿Eliminar Usuario?',
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Esta acción es permanente y eliminará al usuario tanto del panel como de la autenticación de Supabase.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.12),
              foregroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eliminando usuario...')),
      );

      final res = await ApiService.eliminarUsuario(userId);

      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado exitosamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _fetchUsuarios();
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

  void _mostrarModalEdicion(Map<String, dynamic> user) {
    _editingUserId = user['id'];
    _nombresController.text = user['nombres'] ?? '';
    _apellidosController.text = user['apellidos'] ?? '';
    _emailController.text = user['email'] ?? '';
    _cedulaController.text = user['cedula'] ?? '';
    _telefonoController.text = user['telefono'] ?? '';
    _facultadController.text = user['facultad'] ?? '';
    _role = user['role'] ?? 'user';
    _isActive = user['is_active'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetForm(),
    );
  }

  Widget _buildBottomSheetForm() {
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
                  // Pull handle indicator
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
                    'Editar Usuario',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nombresController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Nombres'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Los nombres son requeridos' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidosController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Apellidos'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Los apellidos son requeridos' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Correo Electrónico'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'El correo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cedulaController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Cédula'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'La cédula es requerida' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Teléfono (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _facultadController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Facultad (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _role,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Rol del Usuario'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Usuario Común')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          _role = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Usuario Activo', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Si se desactiva, el usuario no podrá iniciar sesión.',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    activeColor: AppColors.emeraldGlow,
                    onChanged: (val) {
                      setModalState(() {
                        _isActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _actualizarUsuario,
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
                      'GUARDAR CAMBIOS',
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
      labelStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
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

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _facultadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminUsuariosView(state: this);
  }
}
