import 'package:flutter/material.dart';
import 'package:flutter_application_1/db_service.dart';
import 'package:flutter_application_1/theme_controller.dart';

// Form per registrare una nuova spesa associandola a una categoria esistente.
class SpeseFormPage extends StatefulWidget {
  const SpeseFormPage({super.key});

  @override
  State<SpeseFormPage> createState() => _SpeseFormPageState();
}

class _SpeseFormPageState extends State<SpeseFormPage> {

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _prezzoController = TextEditingController();
  
  List<CategoriaItem> _categorie = <CategoriaItem>[];
  List<SpesaItem> _ultimeSpese = <SpesaItem>[];
  int? _categoriaSelezionataId;
  int? _spesaInModificaId;
  bool _loadingCategorie = true;
  bool _loadingSpese = true;
  DateTime? _giorno;

  @override
  void initState() {
    super.initState();
    // Carica subito le categorie, necessarie per compilare la spesa.
    _caricaCategorie();
    _caricaSpese();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _prezzoController.dispose();
    super.dispose();
  }

  Future<void> _caricaCategorie() async {
    setState(() {
      _loadingCategorie = true;
    });

    final categorie = await DbService.fetchCategorie();

    if (!mounted) {
      return;
    }

    setState(() {
      _categorie = categorie;
      // Se la categoria prima selezionata non esiste più, resettiamo la selezione.
      final containsSelected = _categorie.any(
        (c) => c.idcategoria == _categoriaSelezionataId,
      );
      if (!containsSelected) {
        _categoriaSelezionataId = null;
      }
      _loadingCategorie = false;
    });
  }

  Future<void> _caricaSpese() async {
    setState(() {
      _loadingSpese = true;
    });

    final spese = await DbService.fetchUltimeSpese(limit: 100);

    if (!mounted) {
      return;
    }

    setState(() {
      _ultimeSpese = spese;
      _loadingSpese = false;
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateUi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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

  Future<void> _salvaSpesa() async {
    // Validazione locale del form prima della chiamata API.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categorie.isEmpty || _categoriaSelezionataId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi prima almeno una categoria')),
      );
      return;
    }

    if (_giorno == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona una data')));
      return;
    }

    final nome = _nomeController.text.trim();
    final giorno = _formatDate(_giorno!);
    final prezzo = int.parse(_prezzoController.text.trim());

    final error = _spesaInModificaId == null
        ? await DbService.createSpesa(
            nome: nome,
            giorno: giorno,
            prezzo: prezzo,
            idcategoria: _categoriaSelezionataId!,
          )
        : await DbService.updateSpesa(
            idspese: _spesaInModificaId!,
            nome: nome,
            giorno: giorno,
            prezzo: prezzo,
            idcategoria: _categoriaSelezionataId!,
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

    final wasEditing = _spesaInModificaId != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasEditing
              ? 'Spesa aggiornata con successo'
              : 'Spesa salvata con successo',
        ),
      ),
    );

    _resetForm();
    _caricaSpese();
  }

  void _resetForm() {
    _nomeController.clear();
    _prezzoController.clear();
    setState(() {
      _giorno = null;
      _categoriaSelezionataId = null;
      _spesaInModificaId = null;
    });
  }

  void _impostaModifica(SpesaItem spesa) {
    _nomeController.text = spesa.nome;
    _prezzoController.text = spesa.prezzo.toString();
    setState(() {
      _spesaInModificaId = spesa.idspese;
      _giorno = DateTime(spesa.giorno.year, spesa.giorno.month, spesa.giorno.day);
      _categoriaSelezionataId = spesa.idcategoria;
    });
  }

  Future<bool> _confermaEliminazioneSpesa(SpesaItem spesa) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Conferma cancellazione'),
          content: Text('Vuoi eliminare la spesa "${spesa.nome}"?'),
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

  Future<void> _eliminaSpesa(SpesaItem spesa) async {
    final confermata = await _confermaEliminazioneSpesa(spesa);
    if (!confermata) {
      return;
    }

    final error = await DbService.deleteSpesa(spesa.idspese);
    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $error')));
      return;
    }

    if (_spesaInModificaId == spesa.idspese) {
      _resetForm();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Spesa eliminata')));
    _caricaSpese();
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
    final warnBg = isDark ? const Color(0xFF3F2E16) : const Color(0xFFFFF4E5);
    final warnBorder = isDark
        ? const Color(0xFF6E4F20)
        : const Color(0xFFFFD8A8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova spesa'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _caricaSpese,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna spese',
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
                          'Registra una nuova spesa',
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
                          labelText: 'Nome spesa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci il nome della spesa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_loadingCategorie)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_categorie.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: warnBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: warnBorder),
                          ),
                          child: const Text(
                            'Nessuna categoria disponibile. Inseriscine una dalla pagina categorie e poi premi Aggiorna categorie.',
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _categoriaSelezionataId,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categorie
                              .map(
                                (categoria) => DropdownMenuItem<int>(
                                  value: categoria.idcategoria,
                                  child: Text(categoria.nome),
                                ),
                              )
                              .toList(),
                          onChanged: _categorie.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _categoriaSelezionataId = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Seleziona una categoria';
                            }
                            return null;
                          },
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _caricaCategorie,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Aggiorna categorie'),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                : _formatDate(_giorno!),
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
                      if (_spesaInModificaId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.close),
                            label: const Text('Annulla modifica'),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _salvaSpesa,
                        icon: Icon(
                          _spesaInModificaId == null ? Icons.save : Icons.edit,
                        ),
                        label: Text(
                          _spesaInModificaId == null
                              ? 'Salva spesa'
                              : 'Aggiorna spesa',
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
                        'Spese registrate',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingSpese)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_ultimeSpese.isEmpty)
                        const Text('Nessuna spesa trovata.')
                      else
                        ..._ultimeSpese.map(
                          (spesa) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () => _impostaModifica(spesa),
                              title: Text(
                                spesa.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${spesa.categoriaNome} • ${_formatDateUi(spesa.giorno)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'EUR ${spesa.prezzo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Elimina spesa',
                                    onPressed: () => _eliminaSpesa(spesa),
                                  ),
                                ],
                              ),
                              selected: _spesaInModificaId == spesa.idspese,
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              leading: const Icon(Icons.receipt_long),
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
