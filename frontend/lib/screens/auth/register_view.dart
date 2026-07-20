part of 'register_screen.dart';

class _RegisterView extends StatelessWidget {
  final _RegisterScreenState state;

  const _RegisterView({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ),
      body: BackgroundGradient(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 500 : double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Branding Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGlow,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emeraldGlow.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: AppColors.deepObsidian,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'EcoSmartBin',
                        style: GoogleFonts.poppins(
                          color: AppColors.emeraldGlow,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Crear una cuenta',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Únete al reciclaje inteligente hoy mismo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Glass Card conteniendo el formulario
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: state._formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Alertas
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
                            const SizedBox(height: 16),
                          ],

                          if (state._successMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGlow.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle_outline_rounded, color: AppColors.emeraldGlow, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '¡Registro exitoso! Redirigiendo...',
                                      style: TextStyle(color: AppColors.emeraldGlow, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Fila de Nombres y Apellidos
                          Row(
                            children: [
                              Expanded(
                                child: PremiumTextField(
                                  controller: state._nombresController,
                                  hintText: 'Nombres',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: PremiumTextField(
                                  controller: state._apellidosController,
                                  hintText: 'Apellidos',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Fila de Cédula y Facultad
                          Row(
                            children: [
                              Expanded(
                                child: PremiumTextField(
                                  controller: state._cedulaController,
                                  hintText: 'Cédula / ID',
                                  prefixIcon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Requerido';
                                    if (v.trim().length < 5) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: PremiumTextField(
                                  controller: state._facultadController,
                                  hintText: 'Facultad (Opc.)',
                                  prefixIcon: Icons.school_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Teléfono
                          PremiumTextField(
                            controller: state._telefonoController,
                            hintText: 'Número de teléfono',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Por favor ingresa tu teléfono';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          PremiumTextField(
                            controller: state._emailController,
                            hintText: 'Correo electrónico',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Por favor ingresa tu correo';
                              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(value.trim())) return 'Correo electrónico inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          PremiumTextField(
                            controller: state._passwordController,
                            hintText: 'Contraseña (mín. 6 caracteres)',
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
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                              if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Botón de Registro
                          PremiumButton(
                            text: 'CREAR CUENTA',
                            isLoading: state._isLoading,
                            onPressed: state._handleRegister,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Footer Links
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.emeraldGlow,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
