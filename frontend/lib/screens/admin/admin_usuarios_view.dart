part of 'admin_usuarios_screen.dart';

class _AdminUsuariosView extends StatelessWidget {
  final _AdminUsuariosScreenState state;

  const _AdminUsuariosView({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Gestión de Usuarios',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundGradient(
        child: SafeArea(
          child: state._isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldGlow))
              : RefreshIndicator(
                  onRefresh: state._fetchUsuarios,
                  color: AppColors.emeraldGlow,
                  backgroundColor: AppColors.glassSurface,
                  child: state._usuarios.isEmpty
                      ? _buildEmptyState()
                      : Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 800 : double.infinity,
                            ),
                            child: isDesktop
                                ? GridView.builder(
                                    padding: const EdgeInsets.all(20),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.45,
                                    ),
                                    itemCount: state._usuarios.length,
                                    itemBuilder: (context, index) {
                                      final u = state._usuarios[index];
                                      return _buildUsuarioCard(context, u);
                                    },
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    itemCount: state._usuarios.length,
                                    itemBuilder: (context, index) {
                                      final u = state._usuarios[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildUsuarioCard(context, u),
                                      );
                                    },
                                  ),
                          ),
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(state.context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 80,
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay usuarios registrados.',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsuarioCard(BuildContext context, Map<String, dynamic> u) {
    final isActive = u['is_active'] ?? true;
    final role = u['role'] ?? 'user';
    final nombres = u['nombres'] ?? '';
    final apellidos = u['apellidos'] ?? '';
    final email = u['email'] ?? '';
    final puntos = u['puntos_ecologicos'] ?? 0;
    final roleColor = role == 'admin' ? AppColors.emeraldGlow : const Color(0xFF3B82F6);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  color: roleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nombres $apellidos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatusBadge(
                    text: isActive ? 'ACTIVO' : 'INACTIVO',
                    color: isActive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐️ $puntos pts',
                      style: GoogleFonts.poppins(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => state._mostrarModalEdicion(u),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => state._eliminarUsuario(u['id']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
