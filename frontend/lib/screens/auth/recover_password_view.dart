part of 'recover_password_screen.dart';

class _RecoverPasswordView extends StatelessWidget {
  final _RecoverPasswordScreenState state;

  const _RecoverPasswordView({required this.state});

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
                child: state._success ? _buildSuccessWidget(context) : _buildFormWidget(context),
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
          // Security / Reset Icon
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
                Icons.lock_reset_rounded,
                color: AppColors.emeraldGlow,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          Text(
            '¿Olvidaste tu contraseña?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo electrónico y te enviaremos las instrucciones de recuperación.',
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

          // Email Input
          PremiumTextField(
            controller: state._emailController,
            hintText: 'Correo electrónico',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegExp.hasMatch(value.trim())) {
                return 'Ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Action Button
          PremiumButton(
            text: 'ENVIAR ENLACE',
            isLoading: state._isLoading,
            onPressed: state._handleRecovery,
          ),
          const SizedBox(height: 24),

          // Volver al Login
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Volver al Iniciar Sesión',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
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
              Icons.mark_email_read_rounded,
              color: AppColors.emeraldGlow,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          '¡Correo enviado!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
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
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
