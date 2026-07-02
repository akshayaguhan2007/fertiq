import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colours ───────────────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF1B6B3A);
const kPrimaryLight = Color(0xFFE8F5ED);
const kPrimaryMid   = Color(0xFF2E9E58);
const kAccentGold   = Color(0xFFF59E0B);
const kAccentBlue   = Color(0xFF2563EB);
const kAccentRed    = Color(0xFFEF4444);

const kBgWhite   = Color(0xFFFFFFFF);
const kBgPage    = Color(0xFFF5F6F9);
const kBgCard    = Color(0xFFF5F6F9);
const kBorder    = Color(0xFFE8E8E8);
const kTextDark  = Color(0xFF212121);
const kTextMid   = Color(0xFF616161);
const kTextGrey  = Color(0xFF9E9E9E);
const kTextLight = Color(0xFFBDBDBD);

// Legacy aliases kept so existing screens compile
const kGreen      = kPrimary;
const kGreenLight = kPrimaryMid;
const kGreenSoft  = Color(0xFF4CAF50);
const kGreenTint  = kPrimaryLight;
const kAmber      = kAccentGold;
const kRed        = kAccentRed;
const kBlue       = kAccentBlue;
const kPurple     = Color(0xFFA855F7);
const kCanvas     = kBgPage;
const kSurface    = kBgWhite;
const kSurface1   = kBgWhite;
const kSurface2   = kBgCard;
const kSurface3   = Color(0xFFEEEEEE);
const kGreenDim   = Color(0xFF166534);
const kGreenGlow  = Color(0x201B6B3A);
const kAmberTint  = Color(0xFFFFFBEB);
const kRedTint    = Color(0xFFFEF2F2);
const kBlueTint   = Color(0xFFEFF6FF);
const kBg         = kBgPage;
const kTextPrimary   = kTextDark;
const kTextSecondary = Color(0xFF86EFAC);
const kTextMuted     = kTextGrey;
const kTextDim       = kTextLight;
const kCardBg        = kBgCard;

// Shadows
const kShadowSm = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 8,  offset: Offset(0, 2)),
];
const kShadowMd = [
  BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x08000000), blurRadius: 4,  offset: Offset(0, 1)),
];
const kGlowGreen = [
  BoxShadow(color: Color(0x301B6B3A), blurRadius: 20, offset: Offset(0, 6)),
];

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData appTheme() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: kBgWhite,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final base = GoogleFonts.plusJakartaSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      secondary: kPrimaryMid,
      surface: kBgWhite,
      error: kAccentRed,
    ),
    scaffoldBackgroundColor: kBgPage,
    textTheme: base.copyWith(
      displayLarge:   base.displayLarge?.copyWith(color: kTextDark, fontWeight: FontWeight.w800),
      headlineMedium: base.headlineMedium?.copyWith(color: kTextDark, fontWeight: FontWeight.w700, fontSize: 22),
      titleLarge:     base.titleLarge?.copyWith(color: kTextDark, fontWeight: FontWeight.w700, fontSize: 17),
      titleMedium:    base.titleMedium?.copyWith(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge:      base.bodyLarge?.copyWith(color: kTextMid, fontSize: 15),
      bodyMedium:     base.bodyMedium?.copyWith(color: kTextMid, fontSize: 14),
      bodySmall:      base.bodySmall?.copyWith(color: kTextGrey, fontSize: 12),
      labelLarge:     base.labelLarge?.copyWith(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 13),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBgWhite,
      foregroundColor: kTextDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(color: kTextDark, fontSize: 16, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: kTextDark, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 52),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: const BorderSide(color: kPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 52),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: kBgWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 2)),
      filled: true, fillColor: kBgWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.plusJakartaSans(color: kTextGrey, fontSize: 14),
      hintStyle: GoogleFonts.plusJakartaSans(color: kTextLight, fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kBgCard,
      selectedColor: kPrimaryLight,
      checkmarkColor: kPrimary,
      side: const BorderSide(color: kBorder),
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kBgWhite,
      elevation: 0,
      height: 64,
      indicatorColor: kPrimaryLight,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final sel = s.contains(WidgetState.selected);
        return GoogleFonts.plusJakartaSans(fontSize: 10,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? kPrimary : kTextGrey);
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final sel = s.contains(WidgetState.selected);
        return IconThemeData(color: sel ? kPrimary : kTextGrey, size: 22);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: kPrimary,
      labelColor: kPrimary,
      unselectedLabelColor: kTextGrey,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
      dividerColor: kBorder,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kTextDark,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kPrimary),
  );
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

/// White rounded container — matches TopRoundedContainer from shop app
class TopRoundedContainer extends StatelessWidget {
  final Color color;
  final Widget child;
  const TopRoundedContainer({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: child,
      );
}

/// Section header row with "See All" trailing — matches shop app SectionTitle
class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? press;
  const SectionTitle(this.title, {super.key, this.press});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
          GestureDetector(
            onTap: press,
            child: Text('See All', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary)),
          ),
        ],
      );
}

/// Status pill badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

/// Icon button with counter badge — matches shop app IconBtnWithCounter
class IconBtnWithCounter extends StatelessWidget {
  final IconData icon;
  final int numOfItem;
  final VoidCallback press;
  const IconBtnWithCounter({
    super.key, required this.icon, this.numOfItem = 0, required this.press,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: press,
        borderRadius: BorderRadius.circular(50),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              height: 44, width: 44,
              decoration: BoxDecoration(
                color: kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kPrimary, size: 20),
            ),
            if (numOfItem > 0)
              Positioned(
                top: -3, right: -3,
                child: Container(
                  height: 18, width: 18,
                  decoration: const BoxDecoration(color: kAccentRed, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$numOfItem', style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Profile menu row — matches shop app ProfileMenu
class ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? press;
  final Color? iconColor;
  const ProfileMenuRow({super.key, required this.icon, required this.text, this.press, this.iconColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: InkWell(
          onTap: press,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Icon(icon, color: iconColor ?? kPrimary, size: 22),
              const SizedBox(width: 16),
              Expanded(child: Text(text,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark))),
              const Icon(Icons.arrow_forward_ios_rounded, color: kTextGrey, size: 14),
            ]),
          ),
        ),
      );
}

/// Glass/surface card helper
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? radius;
  final List<BoxShadow>? shadow;
  final Color? color;
  final bool glow;
  const GlassCard({super.key, required this.child, this.padding, this.radius, this.shadow, this.color, this.glow = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? kBgWhite,
          borderRadius: radius ?? BorderRadius.circular(20),
          border: Border.all(color: glow ? kPrimary.withValues(alpha: 0.3) : kBorder),
          boxShadow: glow ? kGlowGreen : (shadow ?? kShadowSm),
        ),
        child: child,
      );
}

/// Divider with label
class LabelDivider extends StatelessWidget {
  final String label;
  const LabelDivider(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider(color: kBorder)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey))),
        const Expanded(child: Divider(color: kBorder)),
      ]);
}

/// Section label alias
class SectionLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const SectionLabel(this.text, {super.key, this.trailing, this.onTrailingTap});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
          if (trailing != null)
            GestureDetector(onTap: onTrailingTap,
              child: Text(trailing!, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary))),
        ],
      );
}
