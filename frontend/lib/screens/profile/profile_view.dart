part of 'profile_screen.dart';

class _ProfileView extends StatelessWidget {
  final _ProfileScreenState state;

  const _ProfileView({required this.state});

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      _buildProfileTab(context),
      const ReciclarScreen(),
      const CanjearScreen(),
      const ReciclajeHistorialScreen(),
      const CanjesHistorialScreen(),
    ];

    return PopScope(
      canPop: state._currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state._currentIndex != 0) {
          state.setState(() {
            state._currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: state._currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildPremiumNavBar(context),
      ),
    );
  }

  Widget _buildPremiumNavBar(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.person_rounded, label: 'Perfil'),
      _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Reciclar'),
      _NavItem(icon: Icons.card_giftcard_rounded, label: 'Canjear'),
      _NavItem(icon: Icons.history_rounded, label: 'H. Reciclaje'),
      _NavItem(icon: Icons.shopping_bag_rounded, label: 'H. Canjes'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = state._currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    state.setState(() => state._currentIndex = i);
                    if (i == 0) state._fetchProfile();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.emeraldGlow.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          color: isSelected
                              ? AppColors.emeraldGlow
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.emeraldGlow
                                : AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundGradient(
        child: SafeArea(
          child: state._isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.emeraldGlow),
                  ),
                )
              : state._hasError
                  ? _buildErrorWidget()
                  : CustomScrollView(
                      slivers: [
                        // Header AppBar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.sensors_rounded,
                                        color: AppColors.emeraldGlow, size: 22),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'EcoSmartBin',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: state._handleLogout,
                                  icon: const Icon(Icons.logout_rounded, size: 16),
                                  label: const Text('Salir'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    backgroundColor: AppColors.error.withOpacity(0.08),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    textStyle: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: isDesktop ? 600 : double.infinity),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                                child: Column(
                                  children: [
                                    // Identity Section
                                    _buildIdentitySection(),
                                    const SizedBox(height: 24),

                                    // Impact Card (EcoPuntos + progreso)
                                    _buildImpactCard(),
                                    const SizedBox(height: 16),

                                    // Admin Access (si aplica)
                                    if (state._profile?.role == 'admin') ...[
                                      _buildAdminAccessButton(context),
                                      const SizedBox(height: 16),
                                    ],

                                    // Personal Information
                                    _buildPersonalInfoSection(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildIdentitySection() {
    final nombre = state._profile?.nombreCompleto ?? '';
    return Column(
      children: [
        // Avatar con borde esmeralda
        Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.emeraldGlow,
                AppColors.emeraldGlow.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emeraldGlow.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: AppColors.emeraldGlow,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rango badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.emeraldGlow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.2)),
          ),
          child: const Text(
            'ECO-RECICLADOR',
            style: TextStyle(
              color: AppColors.emeraldGlow,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          nombre,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImpactCard() {
    final puntos = state._profile?.puntosEcologicos ?? 0;
    final progress = (puntos / 2000).clamp(0.0, 1.0);
    final ptsParaSubir = (2000 - puntos).clamp(0, 2000);

    return GlassCard(
      padding: const EdgeInsets.all(28),
      isActive: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BALANCE TOTAL',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$puntos',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          shadows: [
                            Shadow(
                              color: AppColors.emeraldGlow.withOpacity(0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PTS',
                        style: TextStyle(
                          color: AppColors.emeraldGlow,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Text(
                  'NIVEL 1',
                  style: TextStyle(
                    color: AppColors.emeraldGlow,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation(AppColors.emeraldGlow),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRÓXIMO RANGO',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$ptsParaSubir PTS PARA SUBIR',
                style: const TextStyle(
                  color: AppColors.emeraldGlow,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAccessButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/admin'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.emeraldGlow.withOpacity(0.1),
              AppColors.emeraldGlow.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.emeraldGlow.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.emeraldGlow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.emeraldGlow,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel de Administración',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gestión de dispositivos y métricas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final infos = [
      _InfoItem(
        icon: Icons.mail_outline_rounded,
        label: 'Correo Electrónico',
        value: state._profile?.email ?? '',
      ),
      _InfoItem(
        icon: Icons.badge_outlined,
        label: 'Cédula / ID',
        value: state._profile?.cedula ?? '',
      ),
      if (state._profile?.facultad != null &&
          state._profile!.facultad!.isNotEmpty)
        _InfoItem(
          icon: Icons.account_balance_rounded,
          label: 'Facultad',
          value: state._profile!.facultad!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'INFORMACIÓN PERSONAL',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
        ...infos.map((info) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildInfoRow(info),
            )),
      ],
    );
  }

  Widget _buildInfoRow(_InfoItem info) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(info.icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  info.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withOpacity(0.25),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar el perfil',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifica tu conexión e inténtalo de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: state._fetchProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGlow,
                  foregroundColor: AppColors.deepObsidian,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: state._handleLogout,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Ir al Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}
