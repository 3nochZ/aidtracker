import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@ngo.org'); 
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _rememberMe = false;
  
  // controls the eye icon toggle state
  bool _obscurePassword = true; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().login(
      _emailController.text.trim(), 
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );
    
    if (!success) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;
    // Trigger initial sync and load data
    try {
      final dataProvider = context.read<DataProvider>();
      await dataProvider.loadData();
      final currentUserId = context.read<AuthProvider>().currentUser?.id;
      await dataProvider.syncPendingData(currentUserId: currentUserId);
    } catch (e) {
      debugPrint("[initial sync on login failed]: $e");
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AID TRACKER.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 2)),
              const SizedBox(height: 48),
              const Text('WELCOME BACK.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('SIGN IN TO YOUR\nACCOUNT.', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: 1)),
              const SizedBox(height: 16),
              const Text('Start tracking distributions in a few simple steps.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword, // bind obscuring status to state
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword; // flip the boolean
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Theme(
                data: ThemeData(unselectedWidgetColor: AppTheme.textSecondary),
                child: CheckboxListTile(
                  title: const Text('Remember me (save for offline access)', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: _rememberMe,
                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  checkColor: AppTheme.backgroundColor,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.textSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.backgroundColor, strokeWidth: 2))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
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