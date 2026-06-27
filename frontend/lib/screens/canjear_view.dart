part of 'canjear_screen.dart';

class _CanjearView extends StatelessWidget {
  final _CanjearScreenState state;

  const _CanjearView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Canjear EcoPuntos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: state._loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // Resumen de puntos del usuario
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF047857), Color(0xFF065F46)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Tus EcoPuntos:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${state._userPoints}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state._recompensas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay recompensas disponibles en este momento.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              itemCount: state._recompensas.length,
                              itemBuilder: (context, index) {
                                final recompensa = state._recompensas[index];
                                final id = recompensa['id'] as int;
                                final nombre =
                                    recompensa['nombre'] as String? ?? '';
                                final desc =
                                    recompensa['descripcion'] as String? ?? '';
                                final costo =
                                    recompensa['costoPuntos'] as int? ?? 0;
                                final stock = recompensa['stock'] as int? ?? 0;
                                final imagenUrl =
                                    recompensa['imagenUrl'] as String? ?? '';
                                final canRedeem =
                                    state._userPoints >= costo && stock > 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Imagen (si hay url, sino mostramos un container decorado)
                                      Container(
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF334155),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          image:
                                              imagenUrl.isNotEmpty &&
                                                      imagenUrl.startsWith('http')
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        imagenUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                        ),
                                        child:
                                            imagenUrl.isEmpty ||
                                                    !imagenUrl.startsWith('http')
                                                ? Center(
                                                    child: Icon(
                                                      Icons.card_giftcard_rounded,
                                                      size: 50,
                                                      color: const Color(
                                                        0xFF10B981,
                                                      ).withOpacity(0.5),
                                                    ),
                                                  )
                                                : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    nombre,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF10B981,
                                                    ).withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$costo pts',
                                                    style: const TextStyle(
                                                      color: Color(0xFF34D399),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              desc,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.6,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Stock disponible: $stock',
                                                  style: TextStyle(
                                                    color: stock > 0
                                                        ? Colors.white
                                                            .withOpacity(0.4)
                                                        : Colors.redAccent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: canRedeem
                                                      ? () => state._handleCanje(
                                                            id,
                                                            nombre,
                                                            costo,
                                                          )
                                                      : null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF10B981),
                                                    foregroundColor:
                                                        Colors.white,
                                                    disabledBackgroundColor:
                                                        Colors.white
                                                            .withOpacity(0.05),
                                                    disabledForegroundColor:
                                                        Colors.white24,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Canjear',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                              },
                            ),
                    ),
                  ],
                ),
                if (state._submitting)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
