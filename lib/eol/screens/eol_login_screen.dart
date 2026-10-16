import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/eol_brand.dart';
import '../services/eol_auth_service.dart';
import '../theme/eol_theme.dart';
import '../widgets/gloved_button.dart';
import 'eol_setup_screen.dart';

class EolLoginScreen extends StatefulWidget {
  const EolLoginScreen({super.key});

  @override
  State<EolLoginScreen> createState() => _EolLoginScreenState();
}

class _EolLoginScreenState extends State<EolLoginScreen> {
  bool _isSignUpMode = false;
  bool _obscurePassword = true;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _assemblerIdController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  EolBrand _selectedBrand = EolBrand.supportedBrands.first;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _assemblerIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<EolAuthService>();
    bool success = false;

    if (_isSignUpMode) {
      success = await authService.registerAssembler(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        assemblerId: _assemblerIdController.text.trim(),
        brand: _selectedBrand,
      );
    } else {
      success = await authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (!mounted) return;

    if (authService.needsProfileSetup) {
      _showProfileCompletionDialog(context, authService);
      return;
    }

    if (success && authService.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EolSetupScreen()),
      );
    }
  }

  void _showProfileCompletionDialog(BuildContext context, EolAuthService authService) {
    final nameCtrl = TextEditingController(text: authService.pendingFirebaseUser?.displayName ?? '');
    final asmCtrl = TextEditingController();
    EolBrand dialogBrand = _selectedBrand;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text(
            'Complete Assembler Profile',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your account was authenticated. Please link your factory operator details to continue.',
                  style: TextStyle(fontSize: 13, color: EolTheme.textMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: asmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assembler ID (e.g. OP-101)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select OEM Brand / Manufacturer *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EolBrand>(
                  initialValue: dialogBrand,
                  items: EolBrand.supportedBrands.map((b) {
                    return DropdownMenuItem(value: b, child: Text(b.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => dialogBrand = val);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dlgCtx).pop();
                authService.logout();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final nav = Navigator.of(context);
                Navigator.of(dlgCtx).pop();
                final done = await authService.completeProfile(
                  fullName: nameCtrl.text.trim(),
                  assemblerId: asmCtrl.text.trim(),
                  brand: dialogBrand,
                );
                if (done && mounted) {
                  nav.pushReplacement(
                    MaterialPageRoute(builder: (_) => const EolSetupScreen()),
                  );
                }
              },
              child: const Text('Save & Enter Station'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<EolAuthService>();

    return Scaffold(
      backgroundColor: EolTheme.canvasBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Logo & Branding
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: EolTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(EolTheme.borderRadius),
                          border: Border.all(color: EolTheme.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/powerpedal_logo.png',
                              height: 44,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.bolt_rounded,
                                size: 44,
                                color: EolTheme.powerpedalBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'FACTORY END-OF-LINE STATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: EolTheme.powerpedalBlueDark,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auth Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mode Switcher Tabs
                            Container(
                              decoration: BoxDecoration(
                                color: EolTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: EolTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isSignUpMode = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_isSignUpMode
                                              ? EolTheme.powerpedalBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Sign In',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: !_isSignUpMode
                                                ? Colors.white
                                                : EolTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isSignUpMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _isSignUpMode
                                              ? EolTheme.powerpedalBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Create New User',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _isSignUpMode
                                                ? Colors.white
                                                : EolTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              _isSignUpMode
                                  ? 'Register Line Assembler'
                                  : 'Production Assembler Sign In',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: EolTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUpMode
                                  ? 'Create your credentials to map your identity to your OEM brand in Firebase.'
                                  : 'Enter your registered factory credentials to unlock your brand station.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: EolTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Fields specific to Sign-Up
                            if (_isSignUpMode) ...[
                              TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name *',
                                  hintText: 'e.g. Ramesh Patil',
                                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: EolTheme.surfaceSubtle,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _assemblerIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Assembler / Employee ID',
                                  hintText: 'e.g. OP-204 (Auto-generated if blank)',
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: EolTheme.surfaceSubtle,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Brand Selector (Chips)
                              const Text(
                                'Select Your OEM Brand / Manufacturer *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: EolTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: EolBrand.supportedBrands.map((brand) {
                                  final isSelected = brand.id == _selectedBrand.id;
                                  return ChoiceChip(
                                    label: Text(brand.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedBrand = brand);
                                      }
                                    },
                                    selectedColor: EolTheme.powerpedalBlueLight,
                                    backgroundColor: EolTheme.surfaceSubtle,
                                    side: BorderSide(
                                      color: isSelected
                                          ? EolTheme.powerpedalBlue
                                          : EolTheme.borderSubtle,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: isSelected
                                          ? EolTheme.powerpedalBlueDark
                                          : EolTheme.textSecondary,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Assembler Email *',
                                hintText: 'assembler@factory.com',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: EolTheme.surfaceSubtle,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                hintText: 'Minimum 6 characters',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: EolTheme.surfaceSubtle,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Password is required';
                                }
                                if (val.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Error Display
                            if (authService.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: EolTheme.statusFaultBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: EolTheme.statusFault.withAlpha(50)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        size: 18, color: EolTheme.statusFault),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authService.errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: EolTheme.statusFault,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Action Button
                            GlovedButton(
                              label: _isSignUpMode
                                  ? 'Create Assembler Account'
                                  : 'Sign In to Station',
                              icon: _isSignUpMode
                                  ? Icons.person_add_rounded
                                  : Icons.login_rounded,
                              isLoading: authService.isLoading,
                              onPressed: _handleSubmit,
                            ),
                            const SizedBox(height: 16),

                            // Switch Mode Toggle Text
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                  });
                                },
                                child: Text(
                                  _isSignUpMode
                                      ? 'Already registered? Sign In'
                                      : 'Need a new account? Create User Account',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: EolTheme.powerpedalBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
