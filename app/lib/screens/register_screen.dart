import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/app_strings.dart';
import '../services/firestore_service.dart';
import '../main.dart' show setProfileChecked;
import '../theme.dart';

const _cropOptions = [
  'Wheat', 'Rice', 'Maize', 'Cotton', 'Sugarcane',
  'Soybean', 'Groundnut', 'Pulses', 'Vegetables', 'Other',
];
const _languages = [
  ('en', 'English'), ('ta', 'தமிழ்'), ('hi', 'हिन्दी'), ('mr', 'मराठी'),
  ('gu', 'ગુજરાતી'), ('pa', 'ਪੰਜਾਬੀ'), ('te', 'తెలుగు'),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _distCtrl    = TextEditingController();
  final _sizeCtrl    = TextEditingController();
  final Set<String> _crops = {};
  String _lang    = 'en';
  bool   _loading = false;

  String get _phone => AuthService.instance.email ?? '';

  bool get _ta => _lang == 'ta';
  String _s(String en, String ta) => _ta ? ta : en;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s('Select at least one crop', 'குறைந்தது ஒரு பயிரை தேர்ந்தெடுக்கவும்'))));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirestoreService.instance.saveProfile(
        name:              _nameCtrl.text.trim(),
        phone:             _phone,
        village:           _villageCtrl.text.trim(),
        district:          _distCtrl.text.trim(),
        farmSize:          double.tryParse(_sizeCtrl.text) ?? 0,
        crops:             _crops.toList(),
        preferredLanguage: _lang,
      );
      if (mounted) LangProvider.of(context).setLang(_lang);
      setProfileChecked(true);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${_s('Error', 'பிழை')}: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _villageCtrl.dispose();
    _distCtrl.dispose(); _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_s('Create Your Profile', 'உங்கள் சுயவிவரம் உருவாக்கு')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            setProfileChecked(true);
            context.go('/dashboard');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _submit,
        backgroundColor: kGreen,
        icon: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check, color: Colors.white),
        label: Text(_s('Save', 'சேமி'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 32, backgroundColor: kGreen,
                  child: const Icon(Icons.person, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(_phone,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: kTextGrey, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(_nameCtrl, _s('Full Name', 'முழு பெயர்'), Icons.person_outline,
                      validator: (v) => v!.isEmpty ? _s('Required', 'தேவை') : null)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_villageCtrl, _s('Village', 'கிராமம்'), Icons.location_on_outlined,
                      validator: (v) => v!.isEmpty ? _s('Required', 'தேவை') : null)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(_distCtrl, _s('District', 'மாவட்டம்'), Icons.map_outlined,
                      validator: (v) => v!.isEmpty ? _s('Required', 'தேவை') : null)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_sizeCtrl, _s('Size (ha)', 'அளவு (எக்.)'), Icons.crop_square_outlined,
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      validator: (v) => v!.isEmpty ? _s('Required', 'தேவை') : null)),
                ],
              ),
              const SizedBox(height: 16),
              Text(_s('Primary Crops', 'முதன்மை பயிர்கள்'),
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, color: kTextDark)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: _cropOptions.map((crop) {
                  final sel = _crops.contains(crop);
                  return FilterChip(
                    label: Text(crop),
                    selected: sel,
                    selectedColor: kGreen.withValues(alpha: 0.15),
                    checkmarkColor: kGreen,
                    onSelected: (_) => setState(() =>
                        sel ? _crops.remove(crop) : _crops.add(crop)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _lang,
                decoration: InputDecoration(
                  labelText: _s('Preferred Language', 'விருப்பமான மொழி'),
                  prefixIcon: const Icon(Icons.language, color: kGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _languages
                    .map((l) => DropdownMenuItem(value: l.$1, child: Text(l.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _lang = v!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl, String label, IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: Icon(icon, color: kGreen, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
