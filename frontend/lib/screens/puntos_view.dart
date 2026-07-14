part of 'puntos_screen.dart';

class _PuntosView extends StatelessWidget {
  final _PuntosScreenState state;

  const _PuntosView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EcoPuntos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: state._loadBalance,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1E293B),
        onRefresh: state._loadBalance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              _buildBalanceCard(),
              const SizedBox(height: 28),

              // Sección Servicios
              const Text(
                'Servicios de EcoPuntos',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Grid de opciones
              _buildDashboardOption(
                title: 'Registrar Reciclaje',
                description: 'Registra tus materiales reciclados para ganar EcoPuntos.',
                icon: Icons.eco_rounded,
                colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                onTap: () => Navigator.pushNamed(context, '/puntos/reciclar').then((_) => state._loadBalance()),
              ),
              const SizedBox(height: 14),

              _buildDashboardOption(
                title: 'Canjear Premios',
                description: 'Usa tus EcoPuntos acumulados para canjear recompensas.',
                icon: Icons.card_giftcard_rounded,
                colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                onTap: () => Navigator.pushNamed(context, '/puntos/canjear').then((_) => state._loadBalance()),
              ),
              const SizedBox(height: 14),

              _buildDashboardOption(
                title: 'Historial de Reciclaje',
                description: 'Consulta los puntos acumulados por tus depósitos anteriores.',
                icon: Icons.history_rounded,
                colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                onTap: () => Navigator.pushNamed(context, '/puntos/historial-reciclaje'),
              ),
              const SizedBox(height: 14),

              _buildDashboardOption(
                title: 'Historial de Canjes',
                description: 'Mira las recompensas que has reclamado.',
                icon: Icons.shopping_bag_rounded,
                colors: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                onTap: () => Navigator.pushNamed(context, '/puntos/historial-canjes'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Card de Balance
  Widget _buildBalanceCard() {
    final puntos = state._balance?['puntosEcologicos'] ?? 0;
    final nombre = state._balance?['nombres'] ?? '';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: state._loadingBalance
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isNotEmpty ? 'Hola, $nombre 👋' : 'Mis EcoPuntos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$puntos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'EcoPuntos acumulados',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Widget para opciones del Dashboard
  Widget _buildDashboardOption({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
