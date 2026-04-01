import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  final namaC = TextEditingController();
  final kelasC = TextEditingController();
  final nisnC = TextEditingController();
  final alamatC = TextEditingController();
  final noHpC = TextEditingController();

  @override
  void dispose() {
    emailC.dispose();
    passwordC.dispose();
    namaC.dispose();
    kelasC.dispose();
    nisnC.dispose();
    alamatC.dispose();
    noHpC.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      // 1. Daftar ke Supabase Auth
      final response = await supabase.auth.signUp(
        email: emailC.text.trim(),
        password: passwordC.text.trim(),
      );

      final user = response.user;
      if (user == null) throw Exception('Registrasi gagal');

      // 2. Insert data profil ke tabel profiles
      await supabase.from('profiles').insert({
        'id': user.id,
        'nama': namaC.text.trim(),
        'kelas': kelasC.text.trim(),
        'nisn': nisnC.text.trim(),
        'alamat': alamatC.text.trim(),
        'no_telepon': noHpC.text.trim(),
        'role': 'member', // default role
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
      );

      // 3. Kembali ke halaman login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal daftar: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF05070D), Color(0xFF0B1630), Color(0xFF071A3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1626),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [cs.primary, cs.primaryContainer],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.person_add_outlined,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daftar Anggota',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 4),
                                  Text('Buat akun baru untuk meminjam buku.',
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Email
                        TextFormField(
                          controller: emailC,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (!v.contains('@')) return 'Email tidak valid';
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Email', Icons.email_outlined),
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextFormField(
                          controller: passwordC,
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (v.length < 6) return 'Minimal 6 karakter';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          decoration: _dec(
                            'Password',
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        const Text('Data Profil',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 12),

                        // Nama
                        TextFormField(
                          controller: namaC,
                          validator: _req,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Nama Lengkap', Icons.person_outline),
                        ),
                        const SizedBox(height: 12),

                        // Kelas
                        TextFormField(
                          controller: kelasC,
                          validator: _req,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Kelas', Icons.class_outlined),
                        ),
                        const SizedBox(height: 12),

                        // NISN
                        TextFormField(
                          controller: nisnC,
                          validator: _req,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('NISN', Icons.badge_outlined),
                        ),
                        const SizedBox(height: 12),

                        // Alamat
                        TextFormField(
                          controller: alamatC,
                          validator: _req,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Alamat', Icons.home_outlined),
                        ),
                        const SizedBox(height: 12),

                        // No Telepon
                        TextFormField(
                          controller: noHpC,
                          validator: _req,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: _dec('No Telepon', Icons.phone_outlined),
                        ),
                        const SizedBox(height: 18),

                        // Tombol Daftar
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('DAFTAR'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol balik ke login
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          ),
                          child: const Text('Sudah punya akun? Login',
                              style: TextStyle(color: Colors.white54)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}