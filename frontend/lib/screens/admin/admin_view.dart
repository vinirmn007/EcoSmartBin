part of 'admin_screen.dart';

class _AdminView extends StatelessWidget {
  final _AdminScreenState state;

  const _AdminView({required this.state});

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false),
        ),
        centerTitle: true,
        title: Text(
          'ECOSMARTBIN',
          style: GoogleFonts.poppins(
            color: AppColors.emeraldGlow,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.emeraldGlow,
              size: 20,
            ),
          ),
        ],
      ),
      body: BackgroundGradient(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: state._fetchMetrics,
            color: AppColors.emeraldGlow,
            backgroundColor: AppColors.glassSurface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Mode Badge and Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.indigoAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MODO: SUPER ADMIN',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                            children: const [
                              TextSpan(text: 'CENTRAL DE\n'),
                              TextSpan(
                                text: 'CONTROL',
                                style: TextStyle(color: AppColors.emeraldGlow),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 2. Grid/List of Options
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildAdminOptionCard(
                                  title: 'Gestión de\nBasureros',
                                  badgeText: '${state._basurerosActivos} ACTIVOS',
                                  badgeColor: AppColors.emeraldGlow,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.emeraldGlow.withOpacity(0.12),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  onTap: () => Navigator.pushNamed(context, '/admin/basureros'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAdminOptionCard(
                                  title: 'Gestión de\nUsuarios',
                                  badgeText: '${state._totalUsuarios} REGISTRADOS',
                                  badgeColor: Colors.indigoAccent,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.indigoAccent.withOpacity(0.12),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  onTap: () => Navigator.pushNamed(context, '/admin/usuarios'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAdminOptionCard(
                                  title: 'Gestión de\nRecompensas',
                                  badgeText: '${state._totalCanjes} CANJES',
                                  badgeColor: const Color(0xFFF59E0B),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF59E0B).withOpacity(0.12),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  onTap: () => Navigator.pushNamed(context, '/admin/recompensas'),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildAdminOptionCard(
                                title: 'Gestión de\nBasureros',
                                badgeText: '${state._basurerosActivos} ACTIVOS',
                                badgeColor: AppColors.emeraldGlow,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.emeraldGlow.withOpacity(0.12),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                onTap: () => Navigator.pushNamed(context, '/admin/basureros'),
                              ),
                              const SizedBox(height: 16),
                              _buildAdminOptionCard(
                                title: 'Gestión de\nUsuarios',
                                badgeText: '${state._totalUsuarios} REGISTRADOS',
                                badgeColor: Colors.indigoAccent,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigoAccent.withOpacity(0.12),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                onTap: () => Navigator.pushNamed(context, '/admin/usuarios'),
                              ),
                              const SizedBox(height: 16),
                              _buildAdminOptionCard(
                                title: 'Gestión de\nRecompensas',
                                badgeText: '${state._totalCanjes} CANJES',
                                badgeColor: const Color(0xFFF59E0B),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF59E0B).withOpacity(0.12),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                onTap: () => Navigator.pushNamed(context, '/admin/recompensas'),
                              ),
                            ],
                          ),
                    const SizedBox(height: 28),

                    // 3. Quick Metrics Bento
                    Text(
                      'MÉTRICAS RÁPIDAS',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isDesktop ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildBentoItem(
                          label: 'EFICIENCIA',
                          value: '${state._eficiencia.toStringAsFixed(0)}%',
                          valueColor: AppColors.emeraldGlow,
                          icon: Icons.trending_up_rounded,
                        ),
                        _buildBentoItem(
                          label: 'INACTIVOS / ALERTAS',
                          value: state._basurerosInactivos.toString().padLeft(2, '0'),
                          valueColor: state._basurerosInactivos > 0 ? AppColors.warning : AppColors.emeraldGlow,
                          icon: state._basurerosInactivos > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                        ),
                        _buildBentoItem(
                          label: 'USUARIOS',
                          value: '${state._totalUsuarios}',
                          valueColor: Colors.white,
                          icon: Icons.people_outline_rounded,
                        ),
                        _buildBentoItemProgress(
                          label: 'CARGA / OCUPACIÓN',
                          value: '${state._carga.toStringAsFixed(0)}%',
                          progress: (state._carga / 100).clamp(0.0, 1.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Resumen Explicativo de Métricas
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.emeraldGlow,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Guía de Métricas en Tiempo Real',
                                style: GoogleFonts.poppins(
                                  color: AppColors.emeraldGlow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildMetricHelpItem(
                            title: 'Eficiencia',
                            description: 'Porcentaje de basureros en estado activo y funcional dentro del sistema.',
                          ),
                          const SizedBox(height: 6),
                          _buildMetricHelpItem(
                            title: 'Inactivos / Alertas',
                            description: 'Cantidad de basureros deshabilitados o que requieren atención/mantenimiento.',
                          ),
                          const SizedBox(height: 6),
                          _buildMetricHelpItem(
                            title: 'Usuarios',
                            description: 'Total de usuarios registrados en la plataforma EcoSmartBin.',
                          ),
                          const SizedBox(height: 6),
                          _buildMetricHelpItem(
                            title: 'Carga / Ocupación',
                            description: 'Porcentaje de basureros que tienen una sesión activa de reciclaje en este instante.',
                          ),
                        ],
                      ),
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

  Widget _buildAdminOptionCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.glassBorder),
        gradient: gradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.poppins(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.deepObsidian,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoItem({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(icon, color: valueColor, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoItemProgress({
    required String label,
    required String value,
    required double progress,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: const AlwaysStoppedAnimation(AppColors.emeraldGlow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricHelpItem({required String title, required String description}) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 11, height: 1.3),
        children: [
          TextSpan(
            text: '• $title: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: description,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
