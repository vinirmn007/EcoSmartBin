part of 'admin_screen.dart';

class _AdminView extends StatelessWidget {
  final _AdminScreenState state;

  const _AdminView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Panel de Administración',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdminCard(
                context,
                title: 'Gestión de Basureros',
                subtitle: 'Agregar, editar o eliminar contenedores inteligentes.',
                icon: Icons.delete_outline_rounded,
                onTap: () {
                  Navigator.pushNamed(context, '/admin/basureros');
                },
              ),
              const SizedBox(height: 16),
              _buildAdminCard(
                context,
                title: 'Gestión de Puntos',
                subtitle: 'Verificar clasificaciones pendientes y asignar puntos.',
                icon: Icons.stars_rounded,
                onTap: () {
                  // TODO: Navegar a la gestión de puntos
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gestión de puntos en desarrollo')),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAdminCard(
                context,
                title: 'Gestión de Usuarios',
                subtitle: 'Ver, editar o eliminar usuarios registrados en el sistema.',
                icon: Icons.people_alt_rounded,
                onTap: () {
                  Navigator.pushNamed(context, '/admin/usuarios');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
