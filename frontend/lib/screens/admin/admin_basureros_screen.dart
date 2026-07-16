import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

part 'admin_basureros_view.dart';

class AdminBasurerosScreen extends StatefulWidget {
  const AdminBasurerosScreen({Key? key}) : super(key: key);

  @override
  State<AdminBasurerosScreen> createState() => _AdminBasurerosScreenState();
}

class _AdminBasurerosScreenState extends State<AdminBasurerosScreen> {
  bool _isLoading = true;
  List<dynamic> _basureros = [];

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();
  final _locController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String _estado = 'activo';

  @override
  void initState() {
    super.initState();
    _fetchBasureros();
  }

  Future<void> _fetchBasureros() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getBasureros();
    if (mounted) {
      setState(() {
        _basureros = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _crearBasurero() async {
    if (!_formKey.currentState!.validate()) return;

    final publicId = _idController.text.trim();
    final nombre = _nombreController.text.trim();
    final localizacion = _locController.text.trim();
    final latText = _latController.text.trim();
    final lngText = _lngController.text.trim();

    double? lat = latText.isNotEmpty ? double.tryParse(latText) : null;
    double? lng = lngText.isNotEmpty ? double.tryParse(lngText) : null;

    // Mostramos loading en el modal
    Navigator.pop(context); // Cerramos el modal primero
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creando basurero...')),
    );

    final res = await ApiService.crearBasurero(
      publicId: publicId,
      nombre: nombre,
      ubicacion: localizacion.isNotEmpty ? localizacion : null,
      latitud: lat,
      longitud: lng,
      estado: _estado,
    );

    if (mounted) {
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Basurero creado exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _idController.clear();
        _nombreController.clear();
        _locController.clear();
        _latController.clear();
        _lngController.clear();
        _estado = 'activo';
        _fetchBasureros();
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
                    'Nuevo Basurero Inteligente',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('ID Público (ej: EcoSmartBin-01)'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'El ID es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Nombre del basurero (ej: Piso 1)'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Ubicación Física (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration('Latitud (Opc.)'),
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              if (double.tryParse(val) == null) return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration('Longitud (Opc.)'),
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              if (double.tryParse(val) == null) return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _estado,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Estado Operativo'),
                    items: const [
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                      DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          _estado = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _crearBasurero,
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
                      'REGISTRAR BASURERO',
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
    _idController.dispose();
    _nombreController.dispose();
    _locController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminBasurerosView(state: this);
  }
}
