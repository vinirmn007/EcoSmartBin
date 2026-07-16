import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_text_field.dart';

part 'reset_password_view.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String? refreshToken;

  const ResetPasswordScreen({super.key, this.token, this.refreshToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _token;
  String? _refreshToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _refreshToken = widget.refreshToken;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_token == null) {
      setState(
        () => _errorMessage =
            'No se encontró un token válido. Solicita un nuevo enlace.',
      );
      return;
    }
    if (_refreshToken == null) {
      setState(
        () => _errorMessage =
            'No se encontró el refresh token. Solicita un nuevo enlace de recuperación.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newPassword = _passwordController.text;
    final result = await ApiService.resetPassword(newPassword, _token!, _refreshToken!);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _success = true);
      } else {
        setState(() => _errorMessage = result['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ResetPasswordView(state: this);
  }
}
