import 'package:flutter/material.dart';
import 'package:flutter_application_1/db_service.dart';
import 'package:flutter_application_1/theme_controller.dart';

// Form dedicata alla creazione di nuove entrate.
class EntrateFormPage extends StatefulWidget {
  const EntrateFormPage({super.key});

  @override
  State<EntrateFormPage> createState() => _EntrateFormPageState();
}

class _EntrateFormPageState extends State<EntrateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _prezzoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _prezzoController.dispose();
    super.dispose();
  }

  Future<void> _salvaEntrata() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final error = await DbService.createEntrata(
      nome: _nomeController.text.trim(),
      prezzo: int.parse(_prezzoController.text.trim()),
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrata salvata con successo')),
    );

    _nomeController.clear();
    _prezzoController.clear();
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
        title: const Text('Nuova entrata'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      Icon(Icons.savings, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Registra una nuova entrata',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome entrata',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci il nome dell\'entrata';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _prezzoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prezzo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci il prezzo';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Inserisci un numero intero valido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _salvaEntrata,
                        icon: const Icon(Icons.save),
                        label: const Text('Salva entrata'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A9D8F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
