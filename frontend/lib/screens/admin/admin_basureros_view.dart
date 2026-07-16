part of 'admin_basureros_screen.dart';

class _AdminBasurerosView extends StatelessWidget {
  final _AdminBasurerosScreenState state;

  const _AdminBasurerosView({required this.state});

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
          'Gestión de Basureros',
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
                  onRefresh: state._fetchBasureros,
                  color: AppColors.emeraldGlow,
                  backgroundColor: AppColors.glassSurface,
                  child: state._basureros.isEmpty
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
                                    itemCount: state._basureros.length,
                                    itemBuilder: (context, index) {
                                      final b = state._basureros[index];
                                      final isActive = b['is_active'] ?? true;
                                      final status = b['status'] ?? 'libre';
                                      return _buildBasureroCard(b, isActive, status);
                                    },
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    itemCount: state._basureros.length,
                                    itemBuilder: (context, index) {
                                      final b = state._basureros[index];
                                      final isActive = b['is_active'] ?? true;
                                      final status = b['status'] ?? 'libre';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildBasureroCard(b, isActive, status),
                                      );
                                    },
                                  ),
                          ),
                        ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state._mostrarModalCreacion,
        backgroundColor: AppColors.emeraldGlow,
        icon: const Icon(Icons.add_rounded, color: AppColors.deepObsidian),
        label: Text(
          'NUEVO BASURERO',
          style: GoogleFonts.poppins(
            color: AppColors.deepObsidian,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 12,
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
                Icons.delete_outline_rounded,
                size: 80,
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay basureros registrados.',
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

  Widget _buildBasureroCard(Map<String, dynamic> b, bool isActive, String status) {
    final statusColor = status == 'libre' ? const Color(0xFF3B82F6) : AppColors.warning;

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
                  color: isActive
                      ? (status == 'libre' ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12))
                      : AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: isActive
                      ? (status == 'libre' ? AppColors.success : AppColors.warning)
                      : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['nombre'] ?? 'Desconocido',
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
                      'ID: ${b['public_id'] ?? ''}',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b['ubicacion'] ?? 'Sin ubicación física',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (b['latitud'] != null && b['longitud'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Lat: ${b['latitud']}, Lng: ${b['longitud']}',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusBadge(
                text: isActive ? 'ACTIVO' : 'INACTIVO',
                color: isActive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                text: status.toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
