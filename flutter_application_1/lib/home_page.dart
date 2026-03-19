import 'package:flutter/material.dart';
import 'login_page.dart';
import 'spese_form_page.dart';
import 'categorie_form_page.dart';
import 'entrate_form_page.dart';
import 'db_service.dart';
import 'theme_controller.dart';

// Dashboard principale dopo il login.
class HomePage extends StatefulWidget {
  // Email utente passata dal login dopo autenticazione riuscita.
  // E' final perche non deve cambiare durante il ciclo di vita del widget.
  final String email;
  final String name;


  // Costruttore const:
  // - migliora le performance quando possibile
  // - richiede obbligatoriamente email tramite `required`
  const HomePage({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Stato locale: lista spese recenti e flag di caricamento.
  List<SpesaItem> _ultimeSpese = <SpesaItem>[];
  List<EntrataItem> _ultimeEntrate = <EntrataItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaUltimeSpese();
  }

  Future<void> _caricaUltimeSpese() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait<dynamic>([
      DbService.fetchUltimeSpese(limit: 15),
      DbService.fetchUltimeEntrate(limit: 15),
    ]);

    final spese = results[0] as List<SpesaItem>;
    final entrate = results[1] as List<EntrataItem>;

    if (!mounted) {
      return;
    }

    setState(() {
      _ultimeSpese = spese;
      _ultimeEntrate = entrate;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatPrice(int prezzo) {
    return 'EUR ${prezzo.toString()}';
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
    final titleColor = isDark ? Colors.white : const Color(0xFF1D3557);
    final amountColor = isDark ? const Color(0xFF7BDFF2) : const Color(0xFF114B5F);
    const maxSpeseWidth = 960.0;
    const maxLogoutWidth = 320.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Spese'),
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
          IconButton(
            onPressed: _caricaUltimeSpese,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna',
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
        child: RefreshIndicator(
          onRefresh: _caricaUltimeSpese,
          child: ListView(
            padding: const EdgeInsets.all(16),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ciao ${widget.name}, benvenuto!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Torniamo qui dopo il salvataggio e aggiorniamo la lista.
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SpeseFormPage()),
                        );
                        _caricaUltimeSpese();
                      },
                      icon: const Icon(Icons.add_card),
                      label: const Text('Nuova spesa'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF2A9D8F),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Torniamo qui dopo eventuali modifiche alle categorie.
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategorieFormPage()),
                        );
                        _caricaUltimeSpese();
                      },
                      icon: const Icon(Icons.category),
                      label: const Text('Categorie'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF457B9D),
                        foregroundColor: Colors.white,
                        
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EntrateFormPage()),
                    );
                  },
                  icon: const Icon(Icons.savings),
                  label: const Text('Nuova entrata'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxSpeseWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ultime spese',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D3557),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_ultimeSpese.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Nessuna spesa trovata.'),
                        )
                      else
                        ..._ultimeSpese.map(
                          (spesa) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                spesa.nome,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${spesa.categoriaNome} • ${_formatDate(spesa.giorno)}',
                              ),
                              trailing: Text(
                                _formatPrice(spesa.prezzo),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: amountColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ultime entrate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D3557),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_ultimeEntrate.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Nessuna entrata trovata.'),
                        )
                      else
                        ..._ultimeEntrate.map(
                          (entrata) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                entrata.nome,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text('Entrata'),
                              trailing: Text(
                                _formatPrice(entrata.prezzo),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: amountColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxLogoutWidth),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
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
