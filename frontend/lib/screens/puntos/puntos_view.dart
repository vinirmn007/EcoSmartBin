part of 'puntos_screen.dart';

class _PuntosView extends StatelessWidget {
  final _PuntosScreenState state;

  const _PuntosView({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundGradient(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.emeraldGlow,
            backgroundColor: AppColors.glassSurface,
            onRefresh: state._loadBalance,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ── Header ──────────────────────────────────────────
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // ── EcoPoints Widget ────────────────────────────────
                        _buildEcoPointsWidget(),
                        const SizedBox(height: 20),

                        // ── Quick Actions Grid ───────────────────────────────
                        _buildQuickActions(context),
                        const SizedBox(height: 20),

                        // ── Stats Bento Grid ─────────────────────────────────
                        _buildStatsBento(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final nombre = state._balance?['nombres'] ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Control',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              nombre.isNotEmpty ? 'Hola, $nombre' : 'EcoSmartBin',
              style: const TextStyle(
                color: AppColors.emeraldGlow,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sensors_rounded, color: AppColors.emeraldGlow, size: 14),
              const SizedBox(width: 6),
              const Text(
                'Conectado',
                style: TextStyle(
                  color: AppColors.emeraldGlow,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.emeraldGlow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emeraldGlow.withOpacity(0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoPointsWidget() {
    final puntos = state._balance?['puntosEcologicos'] ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(28),
      isActive: true,
      child: state._loadingBalance
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.emeraldGlow),
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BALANCE TOTAL',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$puntos',
                      style: TextStyle(
                        color: AppColors.emeraldGlow,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        shadows: [
                          Shadow(
                            color: AppColors.emeraldGlow.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'EcoPuntos',
                      style: TextStyle(
                        color: AppColors.emeraldGlow.withOpacity(0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar hacia siguiente nivel
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Próximo Nivel',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${(puntos / 2000 * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (puntos / 2000).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(AppColors.emeraldGlow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Escanear',
        onTap: () => Navigator.pushNamed(context, '/puntos/reciclar').then((_) => state._loadBalance()),
      ),
      _QuickAction(
        icon: Icons.card_giftcard_rounded,
        label: 'Canjear',
        onTap: () => Navigator.pushNamed(context, '/puntos/canjear').then((_) => state._loadBalance()),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'Reciclaje',
        onTap: () => Navigator.pushNamed(context, '/puntos/historial-reciclaje'),
      ),
      _QuickAction(
        icon: Icons.shopping_bag_outlined,
        label: 'Canjes',
        onTap: () => Navigator.pushNamed(context, '/puntos/historial-canjes'),
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: action == actions.last ? 0 : 10,
            ),
            child: _buildActionButton(action),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: Icon(
                  action.icon,
                  color: AppColors.emeraldGlow,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBento() {
    final puntos = state._balance?['puntosEcologicos'] ?? 0;
    // Estimates: 1 ecopunto ≈ 0.012 kg CO2
    final co2 = (puntos * 0.012).toStringAsFixed(1);
    // Estimates: 500 puntos ~ 1 árbol
    final arboles = (puntos ~/ 500);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.co2_rounded,
            label: 'CO₂ Ahorrado',
            value: '$co2 kg',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.park_rounded,
            label: 'Árboles Plantados',
            value: '$arboles',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.emeraldGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.emeraldGlow, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
