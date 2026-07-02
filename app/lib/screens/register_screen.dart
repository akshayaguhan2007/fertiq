import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../main.dart' show setProfileChecked;
import '../theme.dart';

const _cropOptions = [
  'Wheat', 'Rice', 'Maize', 'Cotton', 'Sugarcane',
  'Soybean', 'Groundnut', 'Pulses', 'Vegetables', 'Other',
];
const _languages = [
  ('en', 'English'), ('hi', 'हिन्दी'), ('mr', 'मराठी'),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one crop')));
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
      setProfileChecked(true); // tell router: profile now exists
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      appBar: AppBar(title: const Text('Create Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40, backgroundColor: kGreen,
                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 8),
              // Phone (read-only, pre-filled)
              Center(
                child: Text(_phone,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: kTextGrey, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 24),
              _field(_nameCtrl, 'Full Name', Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _field(_villageCtrl, 'Village / Town', Icons.location_on_outlined,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _field(_distCtrl, 'District', Icons.map_outlined,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _field(_sizeCtrl, 'Farm Size (hectares)', Icons.crop_square_outlined,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              Text('Primary Crops',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, color: kTextDark)),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _lang,
                decoration: InputDecoration(
                  labelText: 'Preferred Language',
                  prefixIcon: const Icon(Icons.language, color: kGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _languages
                    .map((l) => DropdownMenuItem(value: l.$1, child: Text(l.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _lang = v!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Start Monitoring My Farm'),
                ),
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
          prefixIcon: Icon(icon, color: kGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
