import 'package:flutter/material.dart';
import 'package:flutter_application_1/db_service.dart';
import 'package:flutter_application_1/theme_controller.dart';

// Form dedicata alla creazione di nuove categorie.
class CategorieFormPage extends StatefulWidget {
  const CategorieFormPage({super.key});

  @override
  State<CategorieFormPage> createState() => _CategorieFormPageState();
}

class _CategorieFormPageState extends State<CategorieFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nomeFocusNode = FocusNode();
  List<CategoriaItem> _categorie = <CategoriaItem>[];
  int? _categoriaInModificaId;
  bool _isLoadingCategorie = true;

  @override
  void initState() {
    super.initState();
    _caricaCategorie();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _caricaCategorie() async {
    setState(() {
      _isLoadingCategorie = true;
    });

    final categorie = await DbService.fetchCategorie();

    if (!mounted) {
      return;
    }

    setState(() {
      _categorie = categorie;
      _isLoadingCategorie = false;
    });
  }

  Future<void> _salvaCategoria() async {
    // Blocca l'invio se i campi non superano la validazione locale.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nome = _nomeController.text.trim();
    final error = _categoriaInModificaId == null
        ? await DbService.createCategoria(nome: nome)
        : await DbService.updateCategoria(
            idcategoria: _categoriaInModificaId!,
            nome: nome,
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

    final wasEditing = _categoriaInModificaId != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasEditing
              ? 'Categoria aggiornata con successo'
              : 'Categoria salvata con successo',
        ),
      ),
    );

    _resetForm();
    _caricaCategorie();
  }

  void _impostaModifica(CategoriaItem categoria) {
    _nomeController.text = categoria.nome;
    setState(() {
      _categoriaInModificaId = categoria.idcategoria;
    });
    FocusScope.of(context).requestFocus(_nomeFocusNode);
  }

  void _resetForm() {
    _nomeController.clear();
    setState(() {
      _categoriaInModificaId = null;
    });
  }

  Future<bool> _showDeleteConfirmDialog(CategoriaItem categoria) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancella categoria'),
          content: Text('Vuoi cancellare "${categoria.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB00020),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancella'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _cancellaCategoria(CategoriaItem categoria) async {
    final confirmed = await _showDeleteConfirmDialog(categoria);
    if (!confirmed) {
      return;
    }

    final error = await DbService.deleteCategoria(categoria.idcategoria);

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $error')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Categoria cancellata')));

    if (_categoriaInModificaId == categoria.idcategoria) {
      _resetForm();
    }

    _caricaCategorie();
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
        title: const Text('Nuova categoria'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _caricaCategorie,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna categorie',
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
                      Icon(Icons.category, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Crea una nuova categoria',
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
                        focusNode: _nomeFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Nome categoria',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci il nome della categoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_categoriaInModificaId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.close),
                            label: const Text('Annulla modifica'),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _salvaCategoria,
                        icon: Icon(
                          _categoriaInModificaId == null
                              ? Icons.save
                              : Icons.edit,
                        ),
                        label: Text(
                          _categoriaInModificaId == null
                              ? 'Salva categoria'
                              : 'Aggiorna categoria',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF457B9D),
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
                        'Categorie esistenti',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingCategorie)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_categorie.isEmpty)
                        const Text('Nessuna categoria trovata.')
                      else
                        ..._categorie.map(
                          (categoria) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _impostaModifica(categoria),
                                child: ListTile(
                                  title: Text(
                                    categoria.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected:
                                      _categoriaInModificaId == categoria.idcategoria,
                                  selectedTileColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.08),
                                  leading: const Icon(Icons.category),
                                  trailing: IconButton(
                                    onPressed: () => _cancellaCategoria(categoria),
                                    icon: const Icon(Icons.close),
                                    color: const Color(0xFFB00020),
                                    tooltip: 'Cancella questa categoria',
                                  ),
                                ),
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
