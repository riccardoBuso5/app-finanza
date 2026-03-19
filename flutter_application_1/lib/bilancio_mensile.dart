import 'package:flutter/material.dart';
import 'package:flutter_application_1/db_service.dart';
import 'package:flutter_application_1/theme_controller.dart';

enum PeriodoBilancio { oggi, ultimi7Giorni, questoMese, personalizzato }

class BilancioMensilePage extends StatefulWidget {
  const BilancioMensilePage({super.key});

  @override
  State<BilancioMensilePage> createState() => _BilancioMensilePageState();
}

class _BilancioMensilePageState extends State<BilancioMensilePage> {
  PeriodoBilancio _periodoSelezionato = PeriodoBilancio.ultimi7Giorni;
  String _categoriaSelezionata = 'Tutte';

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _toDate = DateTime.now();

  bool _isLoading = true;
  List<SpesaItem> _spesePeriodo = <SpesaItem>[];
  List<EntrataItem> _entratePeriodo = <EntrataItem>[];

  @override
  void initState() {
    super.initState();
    _applicaPresetDate(_periodoSelezionato, refresh: false);
    _caricaMovimenti();
  }

  Future<void> _caricaMovimenti() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait<dynamic>([
      DbService.fetchUltimeSpese(limit: 200),
      DbService.fetchUltimeEntrate(limit: 200),
    ]);

    final tutteSpese = results[0] as List<SpesaItem>;
    final tutteEntrate = results[1] as List<EntrataItem>;

    final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final to = DateTime(_toDate.year, _toDate.month, _toDate.day);

    bool isInRangeByDay(DateTime date) {
      final d = DateTime(
        date.toLocal().year,
        date.toLocal().month,
        date.toLocal().day,
      );
      return !d.isBefore(from) && !d.isAfter(to);
    }

    final filtrateSpese =
        tutteSpese.where((spesa) => isInRangeByDay(spesa.giorno)).toList()
          ..sort((a, b) => b.giorno.compareTo(a.giorno));

    final filtrateEntrate = tutteEntrate
        .where(
          (entrata) => entrata.data != null && isInRangeByDay(entrata.data!),
        )
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _spesePeriodo = filtrateSpese;
      _entratePeriodo = filtrateEntrate;
      final categorie = _categorieDisponibili;
      if (!categorie.contains(_categoriaSelezionata)) {
        _categoriaSelezionata = 'Tutte';
      }
      _isLoading = false;
    });
  }

  void _applicaPresetDate(PeriodoBilancio periodo, {bool refresh = true}) {
    final now = DateTime.now();

    switch (periodo) {
      case PeriodoBilancio.oggi:
        _fromDate = DateTime(now.year, now.month, now.day);
        _toDate = DateTime(now.year, now.month, now.day);
        break;
      case PeriodoBilancio.ultimi7Giorni:
        _fromDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        _toDate = DateTime(now.year, now.month, now.day);
        break;
      case PeriodoBilancio.questoMese:
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month, now.day);
        break;
      case PeriodoBilancio.personalizzato:
        break;
    }

    if (refresh) {
      _caricaMovimenti();
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    final newToDate = normalized.isAfter(_toDate)
        ? normalized
        : DateTime(_toDate.year, _toDate.month, _toDate.day);

    setState(() {
      _periodoSelezionato = PeriodoBilancio.personalizzato;
      _fromDate = normalized;
      _toDate = newToDate;
    });

    _caricaMovimenti();
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    final newFromDate = normalized.isBefore(_fromDate)
        ? normalized
        : DateTime(_fromDate.year, _fromDate.month, _fromDate.day);

    setState(() {
      _periodoSelezionato = PeriodoBilancio.personalizzato;
      _toDate = normalized;
      _fromDate = newFromDate;
    });

    _caricaMovimenti();
  }

  int get _totaleUscite =>
      _spesePeriodo.fold(0, (tot, item) => tot + item.prezzo);
  int get _totaleEntrate =>
      _entratePeriodo.fold(0, (tot, item) => tot + item.prezzo);
  int get _saldo => _totaleEntrate - _totaleUscite;

  List<String> get _categorieDisponibili {
    final categories =
        _spesePeriodo
            .map((spesa) => spesa.categoriaNome.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return <String>['Tutte', ...categories];
  }

  List<SpesaItem> get _spesePeriodoFiltrate {
    if (_categoriaSelezionata == 'Tutte') {
      return _spesePeriodo;
    }
    return _spesePeriodo
        .where((spesa) => spesa.categoriaNome == _categoriaSelezionata)
        .toList();
  }

  List<MapEntry<String, int>> get _spesePerCategoria {
    final grouped = <String, int>{};
    for (final spesa in _spesePeriodoFiltrate) {
      final key = spesa.categoriaNome.trim().isEmpty
          ? 'Senza categoria'
          : spesa.categoriaNome;
      grouped[key] = (grouped[key] ?? 0) + spesa.prezzo;
    }

    final entries = grouped.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatEuro(int valore) {
    return 'EUR $valore';
  }

  String _labelPeriodo(PeriodoBilancio periodo) {
    switch (periodo) {
      case PeriodoBilancio.oggi:
        return 'Oggi';
      case PeriodoBilancio.ultimi7Giorni:
        return 'Ultimi 7 giorni';
      case PeriodoBilancio.questoMese:
        return 'Questo mese';
      case PeriodoBilancio.personalizzato:
        return 'Personalizzato';
    }
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
    final danger = isDark ? const Color(0xFFFF8A80) : const Color(0xFFB00020);
    final success = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilancio'),
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
            onPressed: _caricaMovimenti,
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
          onRefresh: _caricaMovimenti,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
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
                            Icon(Icons.insights, color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Analisi bilancio per intervallo',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Periodo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<PeriodoBilancio>(
                              value: _periodoSelezionato,
                              items: PeriodoBilancio.values
                                  .map(
                                    (periodo) => DropdownMenuItem<PeriodoBilancio>(
                                      value: periodo,
                                      child: Text(_labelPeriodo(periodo)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _periodoSelezionato = value;
                                });
                                _applicaPresetDate(value);
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickFromDate,
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text('Da: ${_formatDate(_fromDate)}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickToDate,
                                    icon: const Icon(Icons.calendar_month),
                                    label: Text('A: ${_formatDate(_toDate)}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _categoriaSelezionata,
                              decoration: const InputDecoration(
                                labelText: 'Categoria spesa',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categorieDisponibili
                                  .map(
                                    (categoria) => DropdownMenuItem<String>(
                                      value: categoria,
                                      child: Text(categoria),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _categoriaSelezionata = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _SummaryCard(
                          title: 'Uscite totali periodo',
                          value: _formatEuro(_totaleUscite),
                          icon: Icons.trending_down,
                          color: danger,
                        ),
                        const SizedBox(height: 10),
                        _SummaryCard(
                          title: 'Entrate totali',
                          value: _formatEuro(_totaleEntrate),
                          icon: Icons.trending_up,
                          color: success,
                        ),
                        const SizedBox(height: 10),
                        _SummaryCard(
                          title: 'Saldo',
                          value: _formatEuro(_saldo),
                          icon: Icons.account_balance_wallet,
                          color: _saldo >= 0 ? success : danger,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Spese per categoria',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        if (_spesePerCategoria.isEmpty)
                          const _EmptyBox(
                            message: 'Nessuna spesa da raggruppare per categoria.',
                          )
                        else
                          ..._spesePerCategoria.map(
                            (entry) => Container(
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
                                leading: Icon(Icons.category_outlined, color: danger),
                                title: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                trailing: Text(
                                  _formatEuro(entry.value),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: danger,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          _categoriaSelezionata == 'Tutte'
                              ? 'Spese dal ${_formatDate(_fromDate)} al ${_formatDate(_toDate)}'
                              : 'Spese "$_categoriaSelezionata" dal ${_formatDate(_fromDate)} al ${_formatDate(_toDate)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_spesePeriodoFiltrate.isEmpty)
                          _EmptyBox(
                            message: 'Nessuna spesa trovata nel periodo selezionato.',
                          )
                        else
                          ..._spesePeriodoFiltrate.map(
                            (spesa) => _MovimentoTile(
                              title: spesa.nome,
                              subtitle:
                                  '${spesa.categoriaNome} • ${_formatDate(spesa.giorno)}',
                              amount: _formatEuro(spesa.prezzo),
                              amountColor: danger,
                              icon: Icons.remove_circle_outline,
                              surfaceColor: surfaceColor,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Entrate dal ${_formatDate(_fromDate)} al ${_formatDate(_toDate)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_entratePeriodo.isEmpty)
                          const _EmptyBox(message: 'Nessuna entrata trovata.')
                        else
                          ..._entratePeriodo.map(
                            (entrata) => _MovimentoTile(
                              title: entrata.nome,
                              subtitle: entrata.data == null
                                  ? 'Entrata'
                                  : 'Entrata • ${_formatDate(entrata.data!)}',
                              amount: _formatEuro(entrata.prezzo),
                              amountColor: success,
                              icon: Icons.add_circle_outline,
                              surfaceColor: surfaceColor,
                            ),
                          ),
                      ],
                    ],
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.18),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimentoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color surfaceColor;

  const _MovimentoTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        leading: Icon(icon, color: amountColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w700, color: amountColor),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
