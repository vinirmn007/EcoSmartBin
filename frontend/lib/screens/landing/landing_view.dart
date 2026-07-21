part of 'landing_screen.dart';

class _LandingView extends StatelessWidget {
  final _LandingScreenState state;

  const _LandingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundGradient(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              // ── Navbar (fija en la cima) ──────────────────────────────
              state._buildNavbar(context, isDesktop),

              // ── Contenido scrollable ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: state._scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      state._buildHeroSection(context, isDesktop, isTablet),
                      state._buildEcoDashboard(context, isDesktop),
                      state._buildHowItWorksSection(context, isDesktop),
                      state._buildCTASection(context),
                      state._buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
