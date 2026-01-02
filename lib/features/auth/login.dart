// lib/features/auth/login.dart

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    closeKeyboard(context);

    final result = await AuthService.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    final result = await AuthService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (result.success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    final result = await AuthService.signInWithFacebook();

    setState(() => _isLoading = false);

    if (result.success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await AuthService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => closeKeyboard(context),
      child: Scaffold(
        body: ContainerStack(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                spacing: 16.h,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Log in Your Account',
                    textAlign: TextAlign.center,
                    style: AppStyles.kTextStyle16Black,
                  ),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: '| Enter Your Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  // Password Field
                  PasswordField(
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Icon(
                              _rememberMe
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: _rememberMe
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                              size: 25.r,
                            ),
                          ),
                          WidthSpace(8),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                      ),
                    ],
                  ),

                  // Login Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AppButton(
                    hintText: 'Log In',
                    onPressed: _signInWithEmail,
                  ),

                  SizedBox(height: height * 0.05),

                  Text(
                    'Or sign in with',
                    textAlign: TextAlign.center,
                    style: AppStyles.kTextStyle16Grey,
                  ),

                  // Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialButton(
                        AppStrings.google,
                        onTap: _signInWithGoogle,
                      ),
                      const SizedBox(width: 16),
                      _socialButton(
                        AppStrings.fb,
                        onTap: _signInWithFacebook,
                      ),
                      const SizedBox(width: 16),
                      _socialButton(
                        AppStrings.apple,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Apple Sign In coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),

                  // Sign Up Link
                  NotHaveAccount(
                    text: 'Sign Up',
                    screen: const SignUpScreen(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: SizedBox(
        width: 50.w,
        height: 50.h,
        child: AppImage.svgImage(icon),
      ),
    );
  }
}