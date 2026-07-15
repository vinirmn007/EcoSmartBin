part of 'register_screen.dart';

class _RegisterView extends StatelessWidget {
  final _RegisterScreenState state;

  const _RegisterView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 500 : double.infinity,
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: state._formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Color(0xFF10B981),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Registro',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Únete a EcoSmartBin y empieza a sumar puntos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Alertas
                      if (state._errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state._errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '¡Registro Exitoso! Redirigiendo...',
                                  style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
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
                            child: TextFormField(
                              controller: state._nombresController,
                              style: const TextStyle(color: Color(0xFF0F172A)),
                              decoration: state._buildInputDecoration('Nombres', Icons.person_outline),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: state._apellidosController,
                              style: const TextStyle(color: Color(0xFF0F172A)),
                              decoration: state._buildInputDecoration('Apellidos', Icons.person_outline),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cédula
                      TextFormField(
                        controller: state._cedulaController,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        keyboardType: TextInputType.number,
                        decoration: state._buildInputDecoration('Cédula / ID', Icons.badge_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Por favor ingresa tu cédula';
                          if (v.trim().length < 5) return 'La cédula debe ser válida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: state._emailController,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        keyboardType: TextInputType.emailAddress,
                        decoration: state._buildInputDecoration('Correo Electrónico', Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Por favor ingresa tu correo';
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(value.trim())) return 'Correo electrónico inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: state._passwordController,
                        obscureText: state._obscurePassword,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: 'Contraseña (mín. 6 caracteres)',
                          labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF475569)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              state._obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF475569),
                            ),
                            onPressed: () {
                              state.setState(() => state._obscurePassword = !state._obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                          if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Facultad (Opcional)
                      TextFormField(
                        controller: state._facultadController,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: state._buildInputDecoration('Facultad (Opcional)', Icons.school_outlined),
                      ),
                      const SizedBox(height: 32),

                      // Register Button
                      ElevatedButton(
                        onPressed: state._isLoading ? null : state._handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: state._isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Registrar Cuenta',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Go back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes una cuenta? ',
                            style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Inicia Sesión',
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
        ),
      ),
    );
  }
}
