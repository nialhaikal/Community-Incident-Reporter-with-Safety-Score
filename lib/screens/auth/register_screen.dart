import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/user.dart';
import '../../utils/ui_helpers.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _icCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _db = DatabaseHelper();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _generatedUsername = '';

  @override
  void initState() {
    super.initState();
    _refreshUsername();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _icCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _refreshUsername() {
    setState(
        () => _generatedUsername = DatabaseHelper.generateRandomUsername());
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (await _db.icNumberExists(_icCtrl.text.trim())) {
      if (!mounted) return;
      UiHelpers.showError(context, 'This IC Number is already registered.');
      setState(() => _loading = false);
      return;
    }

    // Resolve username collision in the unlikely case of a duplicate
    String username = _generatedUsername;
    while (await _db.usernameExists(username)) {
      username = DatabaseHelper.generateRandomUsername();
    }

    final user = User(
      icNumber: _icCtrl.text.trim(),
      realName: _nameCtrl.text.trim(),
      randomUsername: username,
      password: _passCtrl.text,
      role: 'user',
    );

    await _db.insertUser(user);

    if (!mounted) return;
    setState(() => _loading = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Registered!'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Your account has been created. Your public alias is:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.badge_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(username,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 10),
            const Text(
              'This alias protects your real identity from the public. '
              'Only authorised admins can see your real information.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Join SafeZone',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.primary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your real identity is protected — we generate an alias for you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [cs.primary, Colors.indigo.shade700]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  const Text('Your Public Alias',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _generatedUsername,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _refreshUsername,
                    icon: const Icon(Icons.refresh, color: Colors.white70,
                        size: 16),
                    label: const Text('Generate another',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name (Real)',
                  prefixIcon: Icon(Icons.person_rounded),
                  helperText: 'As per your identity document',
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3)
                        ? 'Enter your full name'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _icCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'IC Number',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                  helperText: 'e.g. 990101145678 — kept confidential',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 6) return 'Enter a valid IC number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Minimum 6 characters'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) =>
                    v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: const Text('Create Account',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
