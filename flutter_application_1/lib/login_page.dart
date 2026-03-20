import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_page.dart';
import 'db_service.dart';
import 'home_page.dart';
import 'theme_controller.dart';

// Questa è la pagina di login dell'applicazione.
// Gestisce l'autenticazione dell'utente tramite email e password.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller per gestire i dati inseriti nei campi di testo
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Opzioni/UI state per la gestione delle credenziali salvate localmente.
  bool _ricordami = true;
  bool _isLoadingSavedCredentials = true;
  
  // Chiave globale per identificare e validare il modulo (Form)
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Carica credenziali eventualmente salvate all'avvio della schermata.
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedRemember = prefs.getBool('remember_me') ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      _ricordami = savedRemember;
      if (savedRemember) {
        _emailController.text = savedEmail ?? '';
      }
      _isLoadingSavedCredentials = false;
    });

    // Hardening: rimuove eventuali password in chiaro salvate da versioni precedenti.
    await prefs.remove('saved_password');
  }

  Future<void> _saveCredentialsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (_ricordami) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.remove('saved_password');
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  // È importante rilasciare le risorse dei controller quando il widget viene rimosso
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Metodo chiamato quando si preme il pulsante "Accedi"
  Future<void> _login() async {
    // Controlla se tutti i campi del modulo sono validi
    if (_formKey.currentState!.validate()) {
      // Mostra messaggio di attesa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tentativo di login in corso...')),
      );

      // Chiama il backend per autenticare l'utente.
      final user = await DbService.loginUser(
        email: _emailController.text,
        password: _passwordController.text
      );

 
      if (mounted) {
        if (user != null) {
          final userId = user['userId']?.toString().trim().isNotEmpty == true
              ? user['userId'].toString().trim()
              : (user['nome']?.toString().trim() ?? '');

          DbService.setCurrentUserId(userId);
          await _saveCredentialsIfNeeded();

          final nomeRaw = user['nome']?.toString().trim();
          final nome = (nomeRaw != null && nomeRaw.isNotEmpty) ? nomeRaw : 'Utente';

              
          final email = user['email']?.toString().trim().isNotEmpty == true
              ? user['email'].toString()
              : _emailController.text.trim();

          // Login riuscito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Benvenuto $nome!')),
          );
          print('Utente loggato: $nome ($email)');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                email: email,
                name: nome,
              ),
            ),
          );
        } else {
          DbService.setCurrentUserId(null);
          // Login fallito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email o password non validi')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF0D2538) : const Color(0xFF114B5F);
    final bgTop = isDark ? const Color(0xFF0F1720) : const Color(0xFFF5F7FA);
    final bgBottom = isDark ? const Color(0xFF1A2330) : const Color(0xFFE8EEF2);
    final heroA = isDark ? const Color(0xFF0E7490) : const Color(0xFF114B5F);
    final heroB = isDark ? const Color(0xFF155E75) : const Color(0xFF1A759F);
    final surfaceColor = isDark ? const Color(0xFF1C2733) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => appThemeController.toggle(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Tema',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isLoadingSavedCredentials
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [heroA, heroB],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_open, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Accedi al tuo account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Inserisci la tua email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Inserisci una email valida';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Inserisci la password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: _ricordami,
                                  onChanged: (value) {
                                    setState(() {
                                      _ricordami = value ?? false;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Ricordami'),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _login,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Accedi'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFF2A9D8F),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegistrationPage()),
                                    );
                                  },
                                  child: const Text('Non hai un account? Registrati'),
                                ),
                              ],
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
