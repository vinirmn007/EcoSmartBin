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
                  child: Column(
                    children: [
                      // Header controls: Search & Sort
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Column(
                          children: [
                            // Search input
                            TextField(
                              onChanged: (val) {
                                state.setState(() {
                                  state._searchQuery = val;
                                  state._currentPage = 1;
                                });
                              },
                              style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre, correo, cédula...',
                                hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emeraldGlow, size: 20),
                                suffixIcon: state._searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                                        onPressed: () {
                                          state.setState(() {
                                            state._searchQuery = '';
                                            state._currentPage = 1;
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.glassSurface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.glassBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.emeraldGlow),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Row: Result count & Sort dropdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state._usuariosFiltrados.length} usuarios',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: state._sortBy,
                                      dropdownColor: AppColors.background,
                                      icon: const Icon(Icons.sort_rounded, color: AppColors.emeraldGlow, size: 18),
                                      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
                                      items: const [
                                        DropdownMenuItem(value: 'fecha_desc', child: Text('Fecha (más reciente)')),
                                        DropdownMenuItem(value: 'fecha_asc', child: Text('Fecha (más antiguo)')),
                                        DropdownMenuItem(value: 'nombre_asc', child: Text('Nombre (A - Z)')),
                                        DropdownMenuItem(value: 'nombre_desc', child: Text('Nombre (Z - A)')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          state.setState(() {
                                            state._sortBy = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // List View or Empty
                      Expanded(
                        child: state._usuariosPaginados.isEmpty
                            ? _buildEmptyState()
                            : Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isDesktop ? 800 : double.infinity,
                                  ),
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    itemCount: state._usuariosPaginados.length,
                                    itemBuilder: (context, index) {
                                      final u = state._usuariosPaginados[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildUsuarioCard(context, u),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),

                      // Pagination Footer Controls
                      if (state._totalPages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.glassSurface,
                            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: state._currentPage > 1
                                    ? () => state.setState(() => state._currentPage--)
                                    : null,
                                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                label: const Text('Anterior'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.emeraldGlow,
                                  disabledForegroundColor: AppColors.textSecondary.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                'Página ${state._currentPage} de ${state._totalPages}',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: state._currentPage < state._totalPages
                                    ? () => state.setState(() => state._currentPage++)
                                    : null,
                                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                label: const Text('Siguiente'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.emeraldGlow,
                                  disabledForegroundColor: AppColors.textSecondary.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                      u['telefono'] != null && (u['telefono'] as String).isNotEmpty
                          ? '$email • ${u['telefono']}'
                          : email,
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
