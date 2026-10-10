import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijama_center_pro/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await ref.read(authProvider.notifier).signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
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
    final currentLang = Localizations.localeOf(context).languageCode;
    final isAr = currentLang == 'ar';
    final isFr = currentLang == 'fr';

    final titleText = isAr ? 'إنشاء حساب موظف' : (isFr ? 'Créer un compte personnel' : 'Create Staff Account');
    final nameLabel = isAr ? 'الاسم الكامل' : (isFr ? 'Nom complet' : 'Full Name');
    final nameValidator = isAr ? 'الرجاء إدخال الاسم' : (isFr ? 'Veuillez entrer le nom' : 'Please enter name');
    final emailValidator = isAr ? 'الرجاء إدخال بريد إلكتروني صحيح' : (isFr ? 'Veuillez entrer un email valide' : 'Please enter a valid email');
    final passwordValidator = isAr ? 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل' : (isFr ? 'Le mot de passe doit contenir au moins 6 caractères' : 'Password must be at least 6 characters');
    final signUpBtn = isAr ? 'إنشاء حساب' : (isFr ? "S'inscrire" : 'Sign Up');
    final googleSignUpBtn = isAr ? 'إنشاء حساب بواسطة جوجل' : (isFr ? "S'inscrire avec Google" : 'Sign Up with Google');
    final alreadyHaveAcc = isAr ? 'لديك حساب بالفعل؟ ' : (isFr ? 'Vous avez déjà un compte? ' : 'Already have an account? ');
    final logInLink = l10n.login;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand Icon
              const Icon(
                Icons.health_and_safety_outlined,
                size: 70,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 26,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 30),

              // Signup Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: nameLabel,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return nameValidator;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) {
                              return emailValidator;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return passwordValidator;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Error Banner
                        if (state.errorMessage != null) ...[
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(color: AppColors.warningRed, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Buttons
                        state.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: _submit,
                                    child: Text(signUpBtn, style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Google Sign-In Button
                                  OutlinedButton.icon(
                                    onPressed: _loginWithGoogle,
                                    icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                                    label: Text(googleSignUpBtn),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Toggle Login
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(alreadyHaveAcc, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      GestureDetector(
                                        onTap: () => context.go('/login'),
                                        child: Text(
                                          logInLink,
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
