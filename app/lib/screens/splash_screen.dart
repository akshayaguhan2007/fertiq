import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/premium_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _page = 0;
  final _ctrl = PageController();

  static const _pages = [
    _Page(
      'Monitor Your Farm',
      'Real-time crop health, satellite data & soil sensors — all in one place.',
      'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&q=85',
      [Color(0xFF0A3D2E), Color(0xFF1B6B3A)],
      Icons.satellite_alt_rounded,
    ),
    _Page(
      'Earn Carbon Credits',
      'Turn sustainable farming into certified carbon credits and sell them globally.',
      'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800&q=85',
      [Color(0xFF1A237E), Color(0xFF1565C0)],
      Icons.eco_rounded,
    ),
    _Page(
      'AI-Powered Insights',
      'Smart fertilizer plans, climate alerts and crop analysis — instantly.',
      'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&q=85',
      [Color(0xFF4A148C), Color(0xFF7B1FA2)],
      Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A3D2E),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top image section ───────────────────────────────
            SizedBox(
              height: size.height * 0.52,
              child: Stack(
                children: [
                  // Swipeable background images
                  PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _BgImage(url: _pages[i].imageUrl),
                  ),

                  // Gradient overlay — fades image into bottom content
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Particles
                  Positioned.fill(
                    child: ParticleBackground(
                      color: Colors.white,
                      count: 18,
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Logo + Skip row pinned to top of image
                  Positioned(
                    top: 16, left: 20, right: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text('CROP+',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text('Skip',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
                  ),
                ],
              ),
            ),

            // ── Bottom content section ──────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      page.gradient.first,
                      page.gradient.last,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon badge
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Icon(page.icon, color: Colors.white, size: 26),
                      ).animate(key: ValueKey('icon$_page'))
                          .fadeIn(duration: 350.ms)
                          .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1)),

                      const SizedBox(height: 16),

                      // Title
                      Text(page.title,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontSize: 28,
                              fontWeight: FontWeight.w800, height: 1.2))
                          .animate(key: ValueKey('title$_page'))
                          .fadeIn(duration: 350.ms, delay: 60.ms)
                          .slideX(begin: 0.12, end: 0),

                      const SizedBox(height: 10),

                      // Subtitle
                      Text(page.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14, height: 1.55))
                          .animate(key: ValueKey('sub$_page'))
                          .fadeIn(duration: 350.ms, delay: 120.ms)
                          .slideX(begin: 0.12, end: 0),

                      const Spacer(),

                      // Dots + Next button
                      Row(
                        children: [
                          // Dot indicators
                          Row(
                            children: List.generate(_pages.length, (i) =>
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                height: 6,
                                width: _page == i ? 28 : 6,
                                decoration: BoxDecoration(
                                  color: _page == i
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Next / Get Started
                          TapScale(
                            onTap: _next,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _page < _pages.length - 1 ? 'Next' : 'Get Started',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: page.gradient.last, fontSize: 15,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: page.gradient.last, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BgImage extends StatelessWidget {
  final String url;
  const _BgImage({required this.url});

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A3D2E), Color(0xFF1B6B3A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        errorWidget: (_, _, _) => Container(color: const Color(0xFF0A3D2E)),
      );
}

class _Page {
  final String title, subtitle, imageUrl;
  final List<Color> gradient;
  final IconData icon;
  const _Page(this.title, this.subtitle, this.imageUrl, this.gradient, this.icon);
}
