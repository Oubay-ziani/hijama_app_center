import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijama_center_pro/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../settings/providers/settings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@hijama.com');
  final _passwordController = TextEditingController(text: 'admin123');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  void _loginWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const Size.square(24.0).longestSide != 0 ? const EdgeInsets.all(24.0) : EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Language Switcher Row at Top
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<String>(
                    value: currentLanguage,
                    underline: Container(),
                    icon: const Icon(Icons.language, color: AppColors.primaryGreen),
                    onChanged: (lang) {
                      if (lang != null) {
                        ref.read(languageProvider.notifier).setLanguage(lang);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Clinic Brand Logo Icon
              const Icon(
                Icons.health_and_safety_outlined,
                size: 80,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 40),

              // Login card container
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.login,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Error message banner
                        if (state.errorMessage != null) ...[
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(color: AppColors.warningRed, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit Button
                        state.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: _submit,
                                    child: Text(l10n.login, style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Separator OR
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Text(
                                          currentLanguage == 'ar' ? 'أو' : (currentLanguage == 'fr' ? 'OU' : 'OR'),
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Google Sign-In Button
                                  OutlinedButton.icon(
                                    onPressed: _loginWithGoogle,
                                    icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                                    label: Text(
                                      currentLanguage == 'ar'
                                          ? 'تسجيل الدخول بواسطة جوجل'
                                          : (currentLanguage == 'fr' ? 'Se connecter avec Google' : 'Sign In with Google'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Registration Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        currentLanguage == 'ar'
                                            ? 'ليس لديك حساب؟ '
                                            : (currentLanguage == 'fr' ? "Vous n'avez pas de compte? " : "Don't have an account? "),
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go('/register'),
                                        child: Text(
                                          currentLanguage == 'ar'
                                              ? 'إنشاء حساب'
                                              : (currentLanguage == 'fr' ? "S'inscrire" : 'Sign Up'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
