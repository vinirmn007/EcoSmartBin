import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Eliminar Usuario?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acción es permanente y eliminará al usuario tanto del panel como de la autenticación de Supabase.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white55)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Editar Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nombresController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Nombres'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Los nombres son requeridos' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidosController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Apellidos'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Los apellidos son requeridos' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Correo Electrónico'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'El correo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cedulaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Cédula'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'La cédula es requerida' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _facultadController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Facultad (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _role,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
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
                    title: const Text('Usuario Activo', style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                      'Si se desactiva, el usuario no podrá iniciar sesión.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: _isActive,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setModalState(() {
                        _isActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _actualizarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16, color: Colors.white)),
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
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF10B981)),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFF0F172A),
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    _facultadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminUsuariosView(state: this);
  }
}
