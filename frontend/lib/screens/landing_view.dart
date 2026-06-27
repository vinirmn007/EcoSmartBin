part of 'landing_screen.dart';

class _LandingView extends StatelessWidget {
  final _LandingScreenState state;

  const _LandingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF0D1527), // Slate 950
            ],
          ),
        ),
        child: Column(
          children: [
            // Responsive Navbar
            state._buildNavbar(context, isDesktop),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: state._scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Section
                    state._buildHeroSection(context, isDesktop, isTablet),

                    // Stats Banner
                    state._buildStatsBanner(context, isDesktop),

                    // Features Section
                    state._buildFeaturesSection(context, isDesktop, isTablet),

                    // How It Works Section
                    state._buildHowItWorksSection(context, isDesktop),

                    // Call To Action Section
                    state._buildCTASection(context),

                    // Footer
                    state._buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
