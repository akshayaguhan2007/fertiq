import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/farmer.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/app_strings.dart';
import '../theme.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Farmer?>(
      stream: FirestoreService.instance.farmerStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final farmer = snap.data;
        if (farmer == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_outline_rounded, size: 64, color: kTextGrey),
                const SizedBox(height: 16),
                Text('Profile not found',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark)),
                const SizedBox(height: 8),
                Text('Please complete your profile to continue',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Set Up Profile'),
                ),
              ]),
            ),
          );
        }
        return _ProfileBody(farmer: farmer);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Farmer farmer;
  const _ProfileBody({required this.farmer});

  void _showNotifications(BuildContext context, AppStrings t) =>
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _NotificationsSheet(t: t),
      );

  void _showHelpSupport(BuildContext context, AppStrings t) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const HelpSupportScreen()));

  void _shareApp(BuildContext context, AppStrings t) {
    Clipboard.setData(const ClipboardData(text: 'https://cropplus.app/download'));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.linkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return StreamBuilder<List<CarbonCredit>>(
      stream: FirestoreService.instance.carbonCreditsStream(),
      builder: (context, credSnap) {
        final credits = credSnap.data ?? [];
        final earned = credits
            .where((c) => c.status == 'sold')
            .fold(0.0, (s, c) => s + (c.salePrice ?? 0));
        final totalCarbon = credits
            .where((c) => c.status == 'eligible')
            .fold(0.0, (s, c) => s + c.amount);

        return StreamBuilder<List<Farm>>(
          stream: FirestoreService.instance.farmsStream(),
          builder: (context, farmSnap) {
            final farms = farmSnap.data ?? [];
            final farm  = farms.isNotEmpty ? farms.first : null;

            return Scaffold(
              backgroundColor: kBgPage,
              body: SingleChildScrollView(
                child: Column(children: [
                  _ProfileHeader(farmer: farmer, earned: earned),
                  const SizedBox(height: 8),
                  _StatsRow(farm: farm, earned: earned, totalCarbon: totalCarbon, t: t),
                  const SizedBox(height: 16),
                  if (farm != null) _FarmCard(farm: farm, t: t),
                  const SizedBox(height: 8),
                  ProfileMenuRow(icon: Icons.agriculture_outlined, text: t.myFarms, press: () => context.go('/dashboard')),
                  ProfileMenuRow(icon: Icons.map_outlined, text: t.drawFarmBoundary, press: () => context.go('/boundary')),
                  ProfileMenuRow(icon: Icons.eco_outlined, text: t.carbonCredits, press: () => context.go('/carbon')),
                  ProfileMenuRow(icon: Icons.sensors_outlined, text: t.sensorSettings, press: () => context.go('/sensors')),
                  _LanguageTile(),
                  ProfileMenuRow(icon: Icons.notifications_outlined, text: t.notifications, press: () => _showNotifications(context, t)),
                  ProfileMenuRow(icon: Icons.help_outline_rounded, text: t.helpSupport, press: () => _showHelpSupport(context, t)),
                  ProfileMenuRow(icon: Icons.share_outlined, text: t.shareApp, press: () => _shareApp(context, t)),
                  ProfileMenuRow(
                    icon: Icons.logout_rounded,
                    text: t.logout,
                    press: () async {
                      await AuthService.instance.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    iconColor: kRed,
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Farmer farmer;
  final double earned;
  const _ProfileHeader({required this.farmer, required this.earned});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Background farming image
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=600&q=80',
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(color: kPrimaryLight),
              errorWidget: (ctx, url, err) => Container(color: kPrimaryLight),
            ),
          ),
          // Gradient overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
              ),
            ),
          ),
          // Safe area + back button row
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  ),
                ]),
              ),
              const SizedBox(height: 30),
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: kShadowMd,
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: kPrimary,
                  child: Text(farmer.name[0],
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              Text(farmer.name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${farmer.village}, ${farmer.district}',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
              Text('Member since ${DateFormat('MMM yyyy').format(farmer.joinDate)}',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11)),
            ]),
          ),
        ],
      );
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Farm? farm;
  final double earned;
  final double totalCarbon;
  final AppStrings t;
  const _StatsRow({required this.farm, required this.earned, required this.totalCarbon, required this.t});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kBgWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: Row(children: [
          _StatCell(farm != null ? '1' : '0', t.farms, kPrimary),
          _Divider(),
          _StatCell(farm != null ? '${farm!.area} ha' : '0 ha', t.area, kAccentBlue),
          _Divider(),
          _StatCell('${totalCarbon.toStringAsFixed(1)}t', t.carbon, kGreenSoft),
          _Divider(),
          _StatCell('₹${earned.round()}', t.earned, kAccentGold),
        ]),
      );
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCell(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
        ]),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: kBorder);
}

// ── Farm card ─────────────────────────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final AppStrings t;
  const _FarmCard({required this.farm, required this.t});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: kBgWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(children: [
            // Farm image banner
            SizedBox(
              height: 100,
              child: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=600&q=80',
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: kPrimaryLight),
                  errorWidget: (_, _, _) => Container(color: kPrimaryLight),
                ),
                Container(color: kPrimary.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.agriculture_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('${farm.name}  ·  ${farm.area} ha',                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    StatusBadge(t.active, kGreenSoft),
                  ]),
                ),
              ]),
            ),
            // Farm details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                _FarmDetail(t.farmCrop, farm.crops.join(', ')),
                _FarmDetail(t.farmStage, '-'),
                _FarmDetail(t.farmHealth, '0%'),
              ]),
            ),
          ]),
        ),
      );
}

class _FarmDetail extends StatelessWidget {
  final String label, value;
  const _FarmDetail(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary)),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
        ]),
      );
}

// ── Language toggle tile ──────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t    = AppStrings.of(context);
    final prov = LangProvider.of(context);
    final isTA = prov.lang == 'ta';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.language_outlined, color: kPrimary, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(t.language,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark))),
          // Toggle chips
          GestureDetector(
            onTap: () => prov.setLang('en'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !isTA ? kPrimary : kBgCard,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                border: Border.all(color: kPrimary),
              ),
              child: Text('EN',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: !isTA ? Colors.white : kPrimary)),
            ),
          ),
          GestureDetector(
            onTap: () => prov.setLang('ta'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isTA ? kPrimary : kBgCard,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                border: Border.all(color: kPrimary),
              ),
              child: Text('TA',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isTA ? Colors.white : kPrimary)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Notifications Sheet ───────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  final AppStrings t;
  const _NotificationsSheet({required this.t});

  static const _items = [
    (Icons.eco_rounded,           kPrimary,    'Carbon credits ready',   'You have 12.5 t eligible for sale'),
    (Icons.warning_amber_rounded, kAccentGold, 'Low soil moisture',      'Field A moisture dropped to 28%'),
    (Icons.cloud_outlined,        kAccentBlue, 'Rain forecast',          'Heavy rain expected in 2 days'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(t.notifications, style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
              StatusBadge('${_items.length}', kPrimary),
            ]),
          ),
          const SizedBox(height: 8),
          ..._items.map((n) => ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: n.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(n.$1, color: n.$2, size: 20),
                ),
                title: Text(n.$3, style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
                subtitle: Text(n.$4, style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: kTextGrey)),
              )),
          const SizedBox(height: 16),
        ],
      );
}
