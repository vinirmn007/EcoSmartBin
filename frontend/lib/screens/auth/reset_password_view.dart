part of 'reset_password_screen.dart';

class _ResetPasswordView extends StatelessWidget {
  final _ResetPasswordScreenState state;

  const _ResetPasswordView({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: BackgroundGradient(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 420 : double.infinity,
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: state._success 
                    ? _buildSuccessWidget(context) 
                    : (state._token == null 
                        ? _buildMissingTokenWidget(context) 
                        : _buildFormWidget(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormWidget(BuildContext context) {
    return Form(
      key: state._formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.emeraldGlow.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.emeraldGlow.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: AppColors.emeraldGlow,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          Text(
            'Nueva Contraseña',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu nueva contraseña para recuperar el acceso a tu cuenta.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Error Message if any
          if (state._errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state._errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Password Input
          PremiumTextField(
            controller: state._passwordController,
            hintText: 'Nueva Contraseña',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: state._obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                state._obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                state.setState(() => state._obscurePassword = !state._obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa una nueva contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Input
          PremiumTextField(
            controller: state._confirmPasswordController,
            hintText: 'Confirmar Contraseña',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: state._obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                state._obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                state.setState(() => state._obscureConfirmPassword = !state._obscureConfirmPassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirma tu contraseña';
              }
              if (value != state._passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Action Button
          PremiumButton(
            text: 'RESTABLECER CONTRASEÑA',
            isLoading: state._isLoading,
            onPressed: state._handleReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.emeraldGlow.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emeraldGlow.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.emeraldGlow,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          '¡Contraseña restablecida!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu contraseña ha sido actualizada con éxito. Ya puedes iniciar sesión con tus nuevas credenciales.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),

        PremiumButton(
          text: 'INICIAR SESIÓN',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }

  Widget _buildMissingTokenWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.error.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.link_off_rounded,
              color: AppColors.error,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Token no válido',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'El enlace para restablecer tu contraseña no es válido o ha expirado. Por favor, solicita uno nuevo.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),

        PremiumButton(
          text: 'VOLVER AL LOGIN',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }
}
