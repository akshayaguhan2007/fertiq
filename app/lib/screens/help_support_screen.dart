import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_strings.dart';
import '../theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kBgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: kTextDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(t.helpSupport,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: kPrimary,
          unselectedLabelColor: kTextGrey,
          indicatorColor: kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact'),
            Tab(text: 'Report Bug'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _FaqTab(),
          _ContactTab(),
          _BugReportTab(),
        ],
      ),
    );
  }
}

// ── FAQ Tab ───────────────────────────────────────────────────────────────────

class _FaqTab extends StatefulWidget {
  const _FaqTab();
  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  int? _open;
  String _query = '';

  List<({String q, String a, int idx})> get _filtered {
    final q = _query.toLowerCase();
    return List.generate(_faqs.length, (i) => (q: _faqs[i].$1, a: _faqs[i].$2, idx: i))
        .where((f) => q.isEmpty || f.q.toLowerCase().contains(q) || f.a.toLowerCase().contains(q))
        .toList();
  }

  static const _faqs = [
    (
      'How do I connect my soil sensor?',
      'Go to Sensors from the dashboard or profile menu. Make sure your Raspberry Pi is on the same network and enter its IP address. The app will start polling every 30 seconds automatically.',
    ),
    (
      'How are carbon credits calculated?',
      'Carbon credits are calculated using satellite NDVI data from Sentinel-2 combined with your soil sensor readings. The AI model estimates biomass and CO₂ sequestration per hectare.',
    ),
    (
      'How do I sell my carbon credits?',
      'Tap "Sell →" on the dashboard banner or go to Carbon Credits from the profile menu. You\'ll see your eligible credits and can proceed to payment.',
    ),
    (
      'Why is my satellite data not loading?',
      'Satellite data requires an active internet connection and a valid farm boundary. Make sure you\'ve drawn your farm boundary under "Draw Farm Boundary" in the profile menu.',
    ),
    (
      'How do I draw my farm boundary?',
      'Go to Profile → Draw Farm Boundary. Tap on the map to add boundary points (minimum 3). Once done, tap Save Boundary.',
    ),
    (
      'What does the health score mean?',
      'The health score (0–100) is a composite of NDVI, soil moisture, nitrogen levels, and pH. Above 70 is Healthy, 40–70 is Moderate, below 40 is Stressed.',
    ),
    (
      'Can I use the app offline?',
      'Basic features like viewing cached reports and sensor history work offline. Satellite analysis, carbon credit calculations, and payments require an internet connection.',
    ),
    (
      'How do I change the app language?',
      'Go to Profile and use the EN / TA toggle to switch between English and Tamil.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SearchBar(onChanged: (v) => setState(() { _query = v; _open = null; })),
        const SizedBox(height: 16),
        if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text('No results for "$_query"',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
            ),
          )
        else
          ...List.generate(_filtered.length, (i) {
            final faq    = _filtered[i];
            final isOpen = _open == faq.idx;
            return GestureDetector(
              onTap: () => setState(() => _open = isOpen ? null : faq.idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kBgWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isOpen ? kPrimary : kBorder),
                  boxShadow: isOpen ? kShadowSm : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Expanded(
                          child: Text(faq.q,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen ? kPrimary : kTextDark)),
                        ),
                        Icon(
                          isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: isOpen ? kPrimary : kTextGrey,
                          size: 20,
                        ),
                      ]),
                    ),
                    if (isOpen)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(faq.a,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: kTextMid, height: 1.5)),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: kBgWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: kTextGrey, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextDark),
              decoration: InputDecoration(
                hintText: 'Search FAQs…',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey),
                border: InputBorder.none,
              ),
            ),
          ),
        ]),
      );
}

// ── Contact Tab ───────────────────────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  static Future<void> _openGuide(BuildContext context) async {
    final uri = Uri.parse('https://cropplus.app/docs');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open guide. Visit cropplus.app/docs')));
    }
  }

  static void _showEmailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _EmailComposeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Support hours banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, color: kPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Support Hours',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: kPrimary)),
                Text('Mon – Sat, 9 AM – 6 PM IST',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextMid)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Email
        _ContactCard(
          icon: Icons.mail_outline_rounded,
          color: kAccentBlue,
          title: 'Email Us',
          subtitle: 'support@cropplus.app',
          actionLabel: 'Send Email',
          onTap: () => _showEmailSheet(context),
        ),
        const SizedBox(height: 12),

        // User guide
        _ContactCard(
          icon: Icons.menu_book_outlined,
          color: kAccentGold,
          title: 'User Guide',
          subtitle: 'Step-by-step tutorials and docs',
          actionLabel: 'Open Guide',
          onTap: () => _openGuide(context),
        ),
        const SizedBox(height: 20),

        Center(
          child: Text('CROP+ v1.0.0  ·  support@cropplus.app',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
        ),
      ],
    );
  }
}

// ── Email Compose Sheet ───────────────────────────────────────────────────────

class _EmailComposeSheet extends StatefulWidget {
  const _EmailComposeSheet();
  @override
  State<_EmailComposeSheet> createState() => _EmailComposeSheetState();
}

class _EmailComposeSheetState extends State<_EmailComposeSheet> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl    = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool _sending      = false;

  static const _subjects = [
    'General Inquiry',
    'Carbon Credits Issue',
    'Sensor Problem',
    'Payment Issue',
    'Feature Request',
    'Other',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final subject = Uri.encodeComponent(_subjectCtrl.text.trim());
    final body    = Uri.encodeComponent(_bodyCtrl.text.trim());
    final subjectText = _subjectCtrl.text;
    final bodyText    = _bodyCtrl.text;
    final uri = Uri.parse(
        'mailto:support@cropplus.app?subject=$subject&body=$body');
    final launched = await launchUrl(uri);
    if (!mounted) return;
    setState(() => _sending = false);
    if (launched) {
      Navigator.of(context).pop();
    } else {
      await Clipboard.setData(ClipboardData(
          text: 'To: support@cropplus.app\nSubject: $subjectText\n\n$bodyText'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email app not found — message copied to clipboard')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: kBorder, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Send Email',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
          Text('To: support@cropplus.app',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
          const SizedBox(height: 16),

          // Subject quick-pick chips
          Text('Subject',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _subjects[i];
                final selected = _subjectCtrl.text == s;
                return GestureDetector(
                  onTap: () => setState(() => _subjectCtrl.text = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? kPrimary : kBgWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? kPrimary : kBorder),
                    ),
                    child: Text(s,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : kTextMid)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Subject text field
          TextFormField(
            controller: _subjectCtrl,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextDark),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
            decoration: _inputDeco('e.g. Carbon Credits Issue'),
          ),
          const SizedBox(height: 14),

          Text('Message',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bodyCtrl,
            maxLines: 4,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextDark),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Please describe your issue (min 10 chars)'
                : null,
            decoration: _inputDeco('Describe your issue…'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Send Email',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey),
        filled: true,
        fillColor: kBgWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kRed)),
      );
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, actionLabel;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
              Text(subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
              child: Text(actionLabel,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      );
}

// ── Bug Report Tab ────────────────────────────────────────────────────────────

class _BugReportTab extends StatefulWidget {
  const _BugReportTab();
  @override
  State<_BugReportTab> createState() => _BugReportTabState();
}

class _BugReportTabState extends State<_BugReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _category = 'Sensor';
  bool _submitted  = false;
  bool _loading    = false;

  static const _categories = ['Sensor', 'Satellite', 'Carbon Credits', 'Payment', 'Login', 'Other'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate submit
    if (mounted) setState(() { _loading = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SuccessView(onReset: () => setState(() {
        _submitted = false;
        _titleCtrl.clear();
        _descCtrl.clear();
        _category = 'Sensor';
      }));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kAccentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kAccentGold.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: kAccentGold, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Your report helps us fix issues faster. We\'ll respond within 24 hours.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextMid, height: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          _Label('Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((c) {
              final selected = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? kPrimary : kBgWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? kPrimary : kBorder),
                  ),
                  child: Text(c,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : kTextMid)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _Label('Bug Title'),
          const SizedBox(height: 8),
          _Field(
            controller: _titleCtrl,
            hint: 'e.g. Sensor data not updating',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 16),

          _Label('Description'),
          const SizedBox(height: 8),
          _Field(
            controller: _descCtrl,
            hint: 'Describe what happened, steps to reproduce, and what you expected…',
            maxLines: 5,
            validator: (v) => (v == null || v.trim().length < 20)
                ? 'Please describe the issue (min 20 chars)'
                : null,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Submit Report',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey),
          filled: true,
          fillColor: kBgWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kRed)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kRed)),
        ),
      );
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onReset;
  const _SuccessView({required this.onReset});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded, color: kPrimary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Report Submitted!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
            const SizedBox(height: 8),
            Text('Thank you for helping us improve CROP+.\nWe\'ll get back to you within 24 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: kPrimary, borderRadius: BorderRadius.circular(12)),
                child: Text('Submit Another',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      );
}
