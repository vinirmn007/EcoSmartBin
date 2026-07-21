part of 'admin_recompensas_screen.dart';

class _AdminRecompensasView extends StatelessWidget {
  final _AdminRecompensasScreenState state;

  const _AdminRecompensasView({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/admin');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'RECOMPENSAS',
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
              border:
                  Border.all(color: AppColors.emeraldGlow.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.emeraldGlow,
              size: 20,
            ),
          ),
        ],
        bottom: TabBar(
          controller: state._tabController,
          indicatorColor: AppColors.emeraldGlow,
          indicatorWeight: 3,
          labelColor: AppColors.emeraldGlow,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Text('Catálogo'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Canjes (${state._canjes.where((c) => c['estado'] == 'PENDIENTE').length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state._mostrarModalCreacion,
        backgroundColor: AppColors.emeraldGlow,
        foregroundColor: AppColors.deepObsidian,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nueva',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: BackgroundGradient(
        child: state._isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.emeraldGlow,
                ),
              )
            : TabBarView(
                controller: state._tabController,
                children: [
                  _buildRecompensasTab(context, isDesktop),
                  _buildCanjesTab(context, isDesktop),
                ],
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  TAB 1: CATÁLOGO DE RECOMPENSAS
  // ══════════════════════════════════════════════════

  Widget _buildRecompensasTab(BuildContext context, bool isDesktop) {
    if (state._recompensas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_rounded,
                color: AppColors.textSecondary.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              'No hay recompensas registradas',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para crear la primera',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Count metrics
    final activas = state._recompensas.where((r) => r['activa'] == true).length;
    final inactivas = state._recompensas.length - activas;

    return RefreshIndicator(
      onRefresh: state._fetchData,
      color: AppColors.emeraldGlow,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniMetric(
                        'TOTAL',
                        '${state._recompensas.length}',
                        Icons.inventory_2_outlined,
                        AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniMetric(
                        'ACTIVAS',
                        '$activas',
                        Icons.check_circle_outline_rounded,
                        AppColors.emeraldGlow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniMetric(
                        'INACTIVAS',
                        '$inactivas',
                        Icons.block_rounded,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section header & Sort
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CATÁLOGO DE RECOMPENSAS',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
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
                          value: state._recompensasSortBy,
                          dropdownColor: AppColors.background,
                          icon: const Icon(Icons.sort_rounded, color: AppColors.emeraldGlow, size: 18),
                          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'nombre_asc', child: Text('Nombre (A - Z)')),
                            DropdownMenuItem(value: 'nombre_desc', child: Text('Nombre (Z - A)')),
                            DropdownMenuItem(value: 'costo_asc', child: Text('Menor Costo')),
                            DropdownMenuItem(value: 'costo_desc', child: Text('Mayor Costo')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              state.setState(() => state._recompensasSortBy = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recompensas list
                ...state._recompensasOrdenadas.map((r) {
                  final recompensa = r as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecompensaCard(context, recompensa),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(
      String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecompensaCard(
      BuildContext context, Map<String, dynamic> recompensa) {
    final isActiva = recompensa['activa'] ?? true;
    final imagenUrl = recompensa['imagenUrl'] as String?;
    final stock = recompensa['stock'] ?? 0;
    final costo = recompensa['costoPuntos'] ?? 0;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Image banner
          if (imagenUrl != null && imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    imagenUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: Colors.white.withOpacity(0.03),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: AppColors.textSecondary, size: 32),
                      ),
                    ),
                  ),
                  // Status overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadge(
                      text: isActiva ? 'ACTIVA' : 'INACTIVA',
                      color: isActiva ? AppColors.emeraldGlow : AppColors.warning,
                    ),
                  ),
                ],
              ),
            )
          else
            // No image: show status badge in a small header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              alignment: Alignment.topRight,
              child: StatusBadge(
                text: isActiva ? 'ACTIVA' : 'INACTIVA',
                color: isActiva ? AppColors.emeraldGlow : AppColors.warning,
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recompensa['nombre'] ?? 'Sin nombre',
                  style: GoogleFonts.poppins(
                    color: isActiva
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (recompensa['descripcion'] != null &&
                    (recompensa['descripcion'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    recompensa['descripcion'],
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      Icons.eco_rounded,
                      '$costo pts',
                      AppColors.emeraldGlow,
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      Icons.inventory_outlined,
                      'Stock: $stock',
                      stock > 0
                          ? AppColors.textSecondary
                          : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            state._mostrarModalEdicion(recompensa),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          'Editar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.glassBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            state._toggleActivaRecompensa(recompensa),
                        icon: Icon(
                          isActiva
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isActiva ? 'Desactivar' : 'Activar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActiva
                              ? AppColors.warning.withOpacity(0.12)
                              : AppColors.emeraldGlow.withOpacity(0.12),
                          foregroundColor:
                              isActiva ? AppColors.warning : AppColors.emeraldGlow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  TAB 2: GESTIÓN DE CANJES
  // ══════════════════════════════════════════════════

  Widget _buildCanjesTab(BuildContext context, bool isDesktop) {
    if (state._canjes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                color: AppColors.textSecondary.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              'No hay canjes registrados',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los canjes aparecerán aquí cuando los usuarios\ncanjeen recompensas.',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Separate by status
    final pendientes =
        state._canjes.where((c) => c['estado'] == 'PENDIENTE').toList();
    final entregados =
        state._canjes.where((c) => c['estado'] == 'ENTREGADO').toList();
    final cancelados =
        state._canjes.where((c) => c['estado'] == 'CANCELADO').toList();

    return RefreshIndicator(
      onRefresh: state._fetchData,
      color: AppColors.emeraldGlow,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniMetric(
                        'PENDIENTES',
                        '${pendientes.length}',
                        Icons.hourglass_top_rounded,
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniMetric(
                        'ENTREGADOS',
                        '${entregados.length}',
                        Icons.check_circle_rounded,
                        AppColors.emeraldGlow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniMetric(
                        'CANCELADOS',
                        '${cancelados.length}',
                        Icons.cancel_rounded,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    state.setState(() {
                      state._canjesSearchQuery = val;
                    });
                  },
                  style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por usuario, correo o recompensa...',
                    hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emeraldGlow, size: 20),
                    suffixIcon: state._canjesSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              state.setState(() {
                                state._canjesSearchQuery = '';
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
                const SizedBox(height: 12),

                // Row: Filter Status Chips & Sort Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Filter Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('TODOS', 'Todos', state._canjesFilterEstado == 'TODOS', () {
                              state.setState(() => state._canjesFilterEstado = 'TODOS');
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('PENDIENTE', 'Pendientes', state._canjesFilterEstado == 'PENDIENTE', () {
                              state.setState(() => state._canjesFilterEstado = 'PENDIENTE');
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('ENTREGADO', 'Entregados', state._canjesFilterEstado == 'ENTREGADO', () {
                              state.setState(() => state._canjesFilterEstado = 'ENTREGADO');
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('CANCELADO', 'Cancelados', state._canjesFilterEstado == 'CANCELADO', () {
                              state.setState(() => state._canjesFilterEstado = 'CANCELADO');
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state._canjesSortBy,
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
                              state.setState(() => state._canjesSortBy = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Render list
                if (state._canjesFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No hay canjes que coincidan con los filtros.',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...state._canjesFiltrados.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCanjeCard(context, c as Map<String, dynamic>),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanjeCard(
      BuildContext context, Map<String, dynamic> canje) {
    final estado = canje['estado'] ?? 'PENDIENTE';
    final isPendiente = estado == 'PENDIENTE';

    Color estadoColor;
    IconData estadoIcon;
    switch (estado) {
      case 'ENTREGADO':
        estadoColor = AppColors.emeraldGlow;
        estadoIcon = Icons.check_circle_rounded;
        break;
      case 'CANCELADO':
        estadoColor = AppColors.error;
        estadoIcon = Icons.cancel_rounded;
        break;
      default:
        estadoColor = AppColors.warning;
        estadoIcon = Icons.hourglass_top_rounded;
    }

    // Parse fecha
    String fechaStr = '';
    final fechaRaw = canje['fecha'];
    if (fechaRaw != null) {
      try {
        final dt = DateTime.parse(fechaRaw.toString());
        fechaStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        fechaStr = fechaRaw.toString();
      }
    }

    final String? nombreUsuarioRaw = canje['usuarioNombre'];
    final String usuarioNombre = (nombreUsuarioRaw != null && nombreUsuarioRaw.trim().isNotEmpty)
        ? nombreUsuarioRaw.trim()
        : 'Usuario: ${_truncateId(canje['usuarioId'] ?? '')}';
    final String? usuarioEmail = canje['usuarioEmail'];
    final String? usuarioTelefono = canje['usuarioTelefono'];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(estadoIcon, color: estadoColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canje['recompensaNombre'] ?? 'Recompensa',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Canje #${canje['id']}',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(text: estado, color: estadoColor),
            ],
          ),
          const SizedBox(height: 12),

          // Info chips: Nombre, Correo, Teléfono, Puntos, Fecha
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.person_outline_rounded, usuarioNombre),
              if (usuarioEmail != null && usuarioEmail.trim().isNotEmpty)
                _buildInfoChip(Icons.email_outlined, usuarioEmail.trim()),
              if (usuarioTelefono != null && usuarioTelefono.trim().isNotEmpty)
                _buildInfoChip(Icons.phone_outlined, usuarioTelefono.trim()),
              _buildInfoChip(Icons.eco_rounded,
                  '${canje['puntosGastados'] ?? 0} pts'),
              if (fechaStr.isNotEmpty)
                _buildInfoChip(Icons.access_time_rounded, fechaStr),
            ],
          ),

          // Action buttons for pending
          if (isPendiente) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => state._cambiarEstadoCanje(
                        canje['id'] as int, 'ENTREGADO'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      'Entregar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGlow,
                      foregroundColor: AppColors.deepObsidian,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => state._cambiarEstadoCanje(
                        canje['id'] as int, 'CANCELADO'),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }

  Widget _buildFilterChip(String value, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldGlow : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.emeraldGlow : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? AppColors.deepObsidian : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
