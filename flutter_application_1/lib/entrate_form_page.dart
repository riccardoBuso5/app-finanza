import 'package:flutter/material.dart';
import 'package:flutter_application_1/db_service.dart';
import 'package:flutter_application_1/theme_controller.dart';

// Form per registrare una nuova entrata associandola a una categoria esistente.
class EntrateFormPage extends StatefulWidget {
  const EntrateFormPage({super.key});

  @override
  State<EntrateFormPage> createState() => _EntrateFormPageState();
}

class _EntrateFormPageState extends State<EntrateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _prezzoController = TextEditingController();

  DateTime? _giorno;
  List<EntrataItem> _ultimeEntrate = <EntrataItem>[];
  int? _entrataInModificaId;
  bool _loadingEntrate = true;

  @override
  void initState() {
    super.initState();
    _caricaEntrate();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _prezzoController.dispose();
    super.dispose();
  }

  String _formatDateForApi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateForUi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _caricaEntrate() async {
    setState(() {
      _loadingEntrate = true;
    });

    final entrate = await DbService.fetchUltimeEntrate(limit: 100);

    if (!mounted) {
      return;
    }

    setState(() {
      _ultimeEntrate = entrate;
      _loadingEntrate = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _giorno ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );

    if (selected != null) {
      setState(() {
        _giorno = selected;
      });
    }
  }

  Future<void> _salvaEntrata() async {
    // Validazione locale del form prima della chiamata API.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_giorno == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona una data')));
      return;
    }

    final nome = _nomeController.text.trim();
    final giorno = _formatDateForApi(_giorno!);
    final prezzo = int.parse(_prezzoController.text.trim());

    final error = _entrataInModificaId == null
        ? await DbService.createEntrata(
            nome: nome,
            giorno: giorno,
            prezzo: prezzo,
          )
        : await DbService.updateEntrata(
            identrate: _entrataInModificaId!,
            nome: nome,
            giorno: giorno,
            prezzo: prezzo,
          );

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $error')));
      return;
    }

    final wasEditing = _entrataInModificaId != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasEditing
              ? 'Entrata aggiornata con successo'
              : 'Entrata salvata con successo',
        ),
      ),
    );

    _resetForm();
    _caricaEntrate();
  }

  void _resetForm() {
    _nomeController.clear();
    _prezzoController.clear();
    setState(() {
      _giorno = null;
      _entrataInModificaId = null;
    });
  }

  void _impostaModifica(EntrataItem entrata) {
    _nomeController.text = entrata.nome;
    _prezzoController.text = entrata.prezzo.toString();
    setState(() {
      _entrataInModificaId = entrata.identrate;
      _giorno = entrata.data == null
          ? DateTime.now()
          : DateTime(entrata.data!.year, entrata.data!.month, entrata.data!.day);
    });
  }

  Future<bool> _confermaEliminazioneEntrata(EntrataItem entrata) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Conferma cancellazione'),
          content: Text('Vuoi eliminare l\'entrata "${entrata.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _eliminaEntrata(EntrataItem entrata) async {
    final confermata = await _confermaEliminazioneEntrata(entrata);
    if (!confermata) {
      return;
    }

    final error = await DbService.deleteEntrata(entrata.identrate);
    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $error')));
      return;
    }

    if (_entrataInModificaId == entrata.identrate) {
      _resetForm();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entrata eliminata')));
    _caricaEntrate();
  }

  @override
  Widget build(BuildContext context) {
    const maxContentWidth = 760.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarColor = isDark
        ? const Color(0xFF0D2538)
        : const Color(0xFF114B5F);
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
            onPressed: _caricaEntrate,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna entrate',
          ),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
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
                      Icon(Icons.receipt_long, color: Colors.white),
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
                            return 'Inserisci il nome della entrata';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _giorno == null
                                ? 'Seleziona data'
                                : _formatDateForUi(_giorno!),
                          ),
                        ),
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
                      if (_entrataInModificaId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.close),
                            label: const Text('Annulla modifica'),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _salvaEntrata,
                        icon: Icon(
                          _entrataInModificaId == null ? Icons.save : Icons.edit,
                        ),
                        label: Text(
                          _entrataInModificaId == null
                              ? 'Salva entrata'
                              : 'Aggiorna entrata',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A9D8F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                      const Text(
                        'Entrate registrate',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingEntrate)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_ultimeEntrate.isEmpty)
                        const Text('Nessuna entrata trovata.')
                      else
                        ..._ultimeEntrate.map(
                          (entrata) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () => _impostaModifica(entrata),
                              title: Text(
                                entrata.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                entrata.data == null
                                    ? 'Entrata'
                                    : 'Entrata • ${_formatDateForUi(entrata.data!)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'EUR ${entrata.prezzo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Elimina entrata',
                                    onPressed: () => _eliminaEntrata(entrata),
                                  ),
                                ],
                              ),
                              selected: _entrataInModificaId == entrata.identrate,
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              leading: const Icon(Icons.savings),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
        ),
      ),
    );
  }
}
