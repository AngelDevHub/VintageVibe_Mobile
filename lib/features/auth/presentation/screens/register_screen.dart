import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).register(
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Únete a\nVintageVibe',
                    style: AppTypography.displayMedium.copyWith(color: AppColors.primaryDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu correo';
                      if (!value.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      errorMaxLines: 2,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                      final pass = value;
                      final hasMinLength = pass.length >= 8;
                      final hasUpper = pass.contains(RegExp(r'[A-Z]'));
                      final hasLower = pass.contains(RegExp(r'[a-z]'));
                      final hasDigits = pass.contains(RegExp(r'[0-9]'));
                      final hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));
                      if (!hasMinLength || !hasUpper || !hasLower || !hasDigits || !hasSpecial) {
                        return 'Cumple con todos los requisitos marcados con palomita';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Lista dinámica de requisitos con palomitas en tiempo real
                  _buildPasswordChecklist(_passwordController.text),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Text('Crear Cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChecklist(String password) {
    final hasMinLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));

    final int metCount = [hasMinLength, hasUpper, hasLower, hasDigits, hasSpecial]
        .where((m) => m)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Seguridad de la contraseña',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              Text(
                '$metCount de 5 cumplidos',
                style: AppTypography.caption.copyWith(
                  color: metCount == 5 ? const Color(0xFF2E7D32) : AppColors.gray,
                  fontWeight: metCount == 5 ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metCount / 5.0,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                metCount == 5
                    ? const Color(0xFF2E7D32)
                    : (metCount >= 3 ? Colors.amber.shade700 : AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildRequirementRow('Mínimo 8 caracteres', hasMinLength),
          const SizedBox(height: 4),
          _buildRequirementRow('Una letra mayúscula (A-Z)', hasUpper),
          const SizedBox(height: 4),
          _buildRequirementRow('Una letra minúscula (a-z)', hasLower),
          const SizedBox(height: 4),
          _buildRequirementRow('Al menos un número (0-9)', hasDigits),
          const SizedBox(height: 4),
          _buildRequirementRow('Un carácter especial (!@#\$%^&*)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
          size: 16,
          color: isMet ? const Color(0xFF2E7D32) : AppColors.gray.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: isMet ? AppColors.dark : AppColors.gray,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
