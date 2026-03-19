import 'package:flutter/material.dart';
import 'db_service.dart';
import 'theme_controller.dart';

// Questa è la pagina di registrazione per creare un nuovo account.
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Controller per tutti i campi del modulo di registrazione
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Chiave per la validazione del modulo
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Pulizia dei controller per liberare memoria
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Metodo chiamato alla pressione del tasto "Registrati"
  void _register() async {
    if (_formKey.currentState!.validate()) {
      // Mostra messaggio di attesa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrazione in corso...')),
      );

      // Invia i dati al backend che si occupa di validazione e salvataggio.
      final errorMessage = await DbService.registerUser(
        userId: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (errorMessage == null) {
        // Registrazione riuscita: torna alla pagina di login
        if (mounted) Navigator.pop(context);
      } else {
        // Mostra il messaggio di errore specifico ricevuto dal server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
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
        title: const Text('Registrazione'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
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
                          Icon(Icons.person_add_alt_1, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Crea il tuo account',
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
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome utente (Plus)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Inserisci il nome utente';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                              if (value.length < 6) {
                                return 'La password deve essere di almeno 6 caratteri';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Conferma Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Conferma la password';
                              }
                              if (value != _passwordController.text) {
                                return 'Le password non coincidono';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _register,
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('Registrati'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2A9D8F),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Hai già un account? Accedi'),
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
