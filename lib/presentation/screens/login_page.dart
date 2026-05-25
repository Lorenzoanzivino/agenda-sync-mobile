import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_strings.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  final _dataNascitaController = TextEditingController();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _storage.read(key: 'saved_email');
    final savedPassword = await _storage.read(key: 'saved_password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppAtmospheres.authBg,
              surface: AppAtmospheres.authBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataNascitaController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      await _storage.write(key: 'saved_email', value: email);
      await _storage.write(key: 'saved_password', value: password);

      if (context.mounted) {
        context.read<AuthCubit>().login(email, password);
      }
    } else {
      final nome = _nomeController.text.trim();
      final dataNascita = _dataNascitaController.text;

      if (nome.isEmpty || dataNascita.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errCompilaTuttiCampi), backgroundColor: Colors.redAccent),
        );
        return;
      }

      await _storage.write(key: 'saved_email', value: email);
      await _storage.write(key: 'saved_password', value: password);

      if (context.mounted) {
        context.read<AuthCubit>().signup(nome, email, password, dataNascita);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppAtmospheres.authBg,
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildCircle(AppAtmospheres.authCircles[0], 300)),
          Positioned(bottom: -100, left: -50, child: _buildCircle(AppAtmospheres.authCircles[1], 250)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                    );
                  } else if (state is AuthAuthenticated) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  }
                },
                builder: (context, state) {
                  return _buildGlassForm(context, state);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassForm(BuildContext context, AuthState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isLogin ? AppStrings.appName : AppStrings.registerTitle, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              if (!_isLogin) ...[
                _buildTextField(_nomeController, AppStrings.labelNome, Icons.person, false),
                const SizedBox(height: 20),
              ],

              _buildTextField(_emailController, AppStrings.labelEmail, Icons.email, false),
              const SizedBox(height: 20),

              _buildTextField(_passwordController, AppStrings.labelPassword, Icons.lock, true),
              const SizedBox(height: 20),

              if (!_isLogin) ...[
                _buildDateField(context),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: state is AuthLoading ? null : () => _submitForm(context),
                  child: state is AuthLoading
                      ? const CircularProgressIndicator()
                      : Text(_isLogin ? AppStrings.btnAccedi : AppStrings.btnRegistrati, style: const TextStyle(color: AppAtmospheres.authBg, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? AppStrings.toRegister : AppStrings.toLogin,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextField(
      controller: _dataNascitaController,
      readOnly: true,
      onTap: () => _selectDate(context),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: AppStrings.labelDataNascitaHint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCircle(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)]),
      ),
    );
  }
}