import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Modello categoria ricevuto dal backend.
class CategoriaItem {
  final int idcategoria;
  final String nome;

  const CategoriaItem({required this.idcategoria, required this.nome});
}

// Modello spesa usato nella dashboard/home.
class SpesaItem {
  final int idspese;
  final String nome;
  final DateTime giorno;
  final int prezzo;
  final int idcategoria;
  final String categoriaNome;

  const SpesaItem({
    required this.idspese,
    required this.nome,
    required this.giorno,
    required this.prezzo,
    required this.idcategoria,
    required this.categoriaNome,
  });
}

// Modello entrata usato nella dashboard/home.
class EntrataItem {
  final int identrate;
  final String nome;
  final int prezzo;
  final DateTime? data;

  const EntrataItem({
    required this.identrate,
    required this.nome,
    required this.prezzo,
    required this.data,
  });
}

// Servizio per comunicare con il backend API Node.js/Express
class DbService {
  static const String _apiBaseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String? _currentUserMail;
  static String? _currentUserId;
  
  /// Imposta userId e mail dell'utente corrente (entrambi opzionali, ma almeno uno consigliato)
  static void setCurrentUserId({String? userId, String? mail}) {
    final normalizedId = userId?.trim();
    final normalizedMail = mail?.trim();
    
    _currentUserId = (normalizedId != null && normalizedId.isNotEmpty)
        ? normalizedId
        : null;
    _currentUserMail = (normalizedMail != null && normalizedMail.isNotEmpty)
        ? normalizedMail
        : null;
  }


  static Map<String, String> _buildHeaders({bool includeContentType = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      headers['x-user-id'] = _currentUserId!;
    }
    if (_currentUserMail != null && _currentUserMail!.isNotEmpty) {
      headers['x-user-mail'] = _currentUserMail!;
    }

    return headers;
  }

  // URL base del backend.
  // Android emulator -> 10.0.2.2
  // Web/Desktop -> localhost
  static String get _baseUrl {

    if (_apiBaseUrlFromDefine.trim().isNotEmpty) {
      final raw = _apiBaseUrlFromDefine.trim().replaceAll(RegExp(r'/+$'), '');
      return raw.endsWith('/api') ? raw : '$raw/api';
    }

    if (kIsWeb) {
      return 'http://localhost:3002/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3002/api';
    }

    return 'http://localhost:3002/api';
  }


  // Metodo helper per fare richieste POST
  static Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
    ) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: _buildHeaders(includeContentType: true),
        body: jsonEncode(body),
      );

      Map<String, dynamic>? data;
      // Il backend dovrebbe sempre rispondere in JSON.
      // Se non succede, ritorniamo un errore esplicito e facile da diagnosticare.
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          final preview = response.body.length > 120
              ? '${response.body.substring(0, 120)}...'
              : response.body;
          throw Exception(
            'Risposta non JSON (status ${response.statusCode}): $preview',
          );
        }
      }

      // Se la risposta non è 200-299, è un errore
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data?['message'] ?? 'Errore HTTP ${response.statusCode}');
      }

      return data ?? <String, dynamic>{};
    } catch (e) {
      print('Errore durante la richiesta a $endpoint: $e');
      rethrow;
    }
  }

  // Metodo helper per fare richieste GET
  static Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final response = await http.get(url, headers: _buildHeaders());

      Map<String, dynamic>? data;
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          final preview = response.body.length > 120
              ? '${response.body.substring(0, 120)}...'
              : response.body;
          throw Exception(
            'Risposta non JSON (status ${response.statusCode}): $preview',
          );
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data?['message'] ?? 'Errore HTTP ${response.statusCode}');
      }

      return data ?? <String, dynamic>{};
    } catch (e) {
      print('Errore durante la richiesta a $endpoint: $e');
      rethrow;
    }
  }

  // Metodo helper per fare richieste DELETE
  static Future<Map<String, dynamic>> _deleteRequest(String endpoint) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final response = await http.delete(url, headers: _buildHeaders());

      Map<String, dynamic>? data;
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          final preview = response.body.length > 120
              ? '${response.body.substring(0, 120)}...'
              : response.body;
          throw Exception(
            'Risposta non JSON (status ${response.statusCode}): $preview',
          );
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data?['message'] ?? 'Errore HTTP ${response.statusCode}');
      }

      return data ?? <String, dynamic>{};
    } catch (e) {
      print('Errore durante la richiesta DELETE a $endpoint: $e');
      rethrow;
    }
  }

  // Metodo helper per fare richieste PUT
  static Future<Map<String, dynamic>> _putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final response = await http.put(
        url,
        headers: _buildHeaders(includeContentType: true),
        body: jsonEncode(body),
      );

      Map<String, dynamic>? data;
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          final preview = response.body.length > 120
              ? '${response.body.substring(0, 120)}...'
              : response.body;
          throw Exception(
            'Risposta non JSON (status ${response.statusCode}): $preview',
          );
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data?['message'] ?? 'Errore HTTP ${response.statusCode}');
      }

      return data ?? <String, dynamic>{};
    } catch (e) {
      print('Errore durante la richiesta PUT a $endpoint: $e');
      rethrow;
    }
  }

  // Registra un nuovo utente nel database.
  // Restituisce:
  // - null se la registrazione va a buon fine
  // - un messaggio di errore leggibile in caso contrario
  static Future<String?> registerUser({
    required String userId,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _postRequest('/register', {
        'userId': userId,
        'email': email,
        'password': password,
      });

      print('Registrazione riuscita: $response');
      return null; // null = successo
    } catch (e) {
      // Estrae il messaggio di errore dall\'eccezione
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante la registrazione: $message');
      return message; // restituisce il messaggio di errore
    }
  }

  // Autentica un utente (login)
  // Restituisce i dati utente se il login riesce, altrimenti null.
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _postRequest('/login', {
        'email': email,
        'password': password,
      });

      print('Login riuscito: $response');
      return response['user'] as Map<String, dynamic>; // restituisce solo i dati utente
    } catch (e) {
      // Estrae il messaggio di errore dall\'eccezione
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante il login: $message');
      return null; // null = login fallito
    }
  }

  // Inserisce una nuova spesa nel database.
  // Restituisce null se ok, oppure il messaggio di errore in caso di problemi.
  static Future<String?> createSpesa({
    required String nome,
    required String giorno,
    required int prezzo,
    required int idcategoria,
  }) async {
    try {
      final response = await _postRequest('/spese', {
        'nome': nome,
        'giorno': giorno,
        'prezzo': prezzo,
        'idcategoria': idcategoria,

      });

      print('Spesa salvata: $response');
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante il salvataggio della spesa: $message');
      return message;
    }
  }

  // Inserisce una nuova categoria nel database.
  // Restituisce null se ok, oppure il messaggio di errore in caso di problemi.
  static Future<String?> createCategoria({
    required String nome,
  }) async {
    try {
      final response = await _postRequest('/categorie', {
        'nome': nome,
      });

      print('Categoria salvata: $response');
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante il salvataggio della categoria: $message');
      return message;
    }
  }

  static Future<String?> updateCategoria({
    required int idcategoria,
    required String nome,
  }) async {
    try {
      await _putRequest('/categorie/$idcategoria', {
        'nome': nome,
      });
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante l\'aggiornamento della categoria: $message');
      return message;
    }
  }

  // Inserisce una nuova entrata nel database.
  // Restituisce null se ok, oppure il messaggio di errore in caso di problemi.
  static Future<String?> createEntrata({
    required String nome,
    String? giorno,
    required int prezzo,
  }) async {
    try {
      final body = <String, dynamic>{
        'nome': nome,
        'prezzo': prezzo,
      };

      if (giorno != null && giorno.trim().isNotEmpty) {
        body['giorno'] = giorno;
        body['data'] = giorno;
      }

      final response = await _postRequest('/entrate', body);

      print('Entrata salvata: $response');
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante il salvataggio dell\'entrata: $message');
      return message;
    }
  }

  static Future<String?> updateSpesa({
    required int idspese,
    required String nome,
    required String giorno,
    required int prezzo,
    required int idcategoria,
  }) async {
    try {
      await _putRequest('/spese/$idspese', {
        'nome': nome,
        'giorno': giorno,
        'prezzo': prezzo,
        'idcategoria': idcategoria,
      });
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante l\'aggiornamento della spesa: $message');
      return message;
    }
  }

  static Future<String?> updateEntrata({
    required int identrate,
    required String nome,
    required String giorno,
    required int prezzo,
  }) async {
    try {
      await _putRequest('/entrate/$identrate', {
        'nome': nome,
        'prezzo': prezzo,
        'giorno': giorno,
        'data': giorno,
      });
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante l\'aggiornamento dell\'entrata: $message');
      return message;
    }
  }

  // Restituisce la lista dei nomi categoria per il combobox nella pagina spese.
  static Future<List<CategoriaItem>> fetchCategorie() async {
    try {
      final response = await _getRequest('/categorie');
      final rawList = response['categorie'] as List<dynamic>? ?? <dynamic>[];
      return rawList
          .map((item) => item as Map<String, dynamic>)
          .map((item) {
            final nome = item['nome']?.toString() ?? '';
            final id = int.tryParse(item['idcategoria']?.toString() ?? '');
            if (nome.isEmpty || id == null || id <= 0) {
              return null;
            }
            return CategoriaItem(idcategoria: id, nome: nome);
          })
          .whereType<CategoriaItem>()
          // Filtra eventuali record incompleti/non validi.
          .toList();
    } catch (e) {
      print('Errore caricamento categorie: $e');
      return <CategoriaItem>[];
    }
  }

  static Future<List<SpesaItem>> fetchUltimeSpese({int limit = 10}) async {
    try {


      final response = await _getRequest('/spese?limit=$limit');
      final rawList = response['spese'] as List<dynamic>? ?? <dynamic>[];
      return rawList
          .map((item) => item as Map<String, dynamic>)
          .map((item) {
            final idspese = int.tryParse(item['idspese']?.toString() ?? '');
            final nome = item['nome']?.toString() ?? '';
            final giornoRaw = item['giorno']?.toString() ?? '';
            DateTime? giorno;
            if (giornoRaw.isNotEmpty) {
              final isoDatePrefix =
                  RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(giornoRaw)?.group(0);
              if (isoDatePrefix != null) {
                final parts = isoDatePrefix.split('-');
                giorno = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              } else {
                giorno = DateTime.tryParse(giornoRaw)?.toLocal();
              }
            }
            final prezzo = int.tryParse(item['prezzo']?.toString() ?? '');
            final idcategoria = int.tryParse(item['idcategoria']?.toString() ?? '');
            final categoriaNome = item['categoria_nome']?.toString() ?? 'N/A';

            if (idspese == null || nome.isEmpty || giorno == null || prezzo == null || idcategoria == null) {
              return null;
            }

            return SpesaItem(
              idspese: idspese,
              nome: nome,
              giorno: giorno,
              prezzo: prezzo,
              idcategoria: idcategoria,
              categoriaNome: categoriaNome,
            );
          })
          // Manteniamo solo le righe utili
          .whereType<SpesaItem>()
          .toList();
    } catch (e) {
      print('Errore caricamento ultime spese: $e');
      return <SpesaItem>[];
    }
  }

  static Future<List<EntrataItem>> fetchUltimeEntrate({int limit = 10}) async {
    try {
      final response = await _getRequest('/entrate?limit=$limit');
      final rawList = response['entrate'] as List<dynamic>? ?? <dynamic>[];
      return rawList
          .map((item) => item as Map<String, dynamic>)
          .map((item) {
            final identrate = int.tryParse(item['identrate']?.toString() ?? '');
            final nome = item['nome']?.toString() ?? '';
            final prezzo = int.tryParse(item['prezzo']?.toString() ?? '');
            final dataRaw = (item['data'] ?? item['giorno'])?.toString() ?? '';
            DateTime? data;
            if (dataRaw.isNotEmpty) {
              if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dataRaw)) {
                final parts = dataRaw.split('-');
                data = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              } else {
                data = DateTime.tryParse(dataRaw)?.toLocal();
              }
            }

            if (identrate == null || nome.isEmpty || prezzo == null) {
              return null;
            }

            return EntrataItem(
              identrate: identrate,
              nome: nome,
              prezzo: prezzo,
              data: data,
            );
          })
          .whereType<EntrataItem>()
          .toList();
    } catch (e) {
      print('Errore caricamento ultime entrate: $e');
      return <EntrataItem>[];
    }
  }

  static Future<String?> deleteSpesa(int idspese) async {
    try {
      await _deleteRequest('/spese/$idspese');
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante la cancellazione della spesa: $message');
      return message;
    }
  }

  static Future<String?> deleteEntrata(int identrate) async {
    try {
      await _deleteRequest('/entrate/$identrate');
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante la cancellazione dell\'entrata: $message');
      return message;
    }
  }

  static Future<String?> deleteCategoria(int idcategoria) async {
    try {
      await _deleteRequest('/categorie/$idcategoria');
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('Errore durante la cancellazione della categoria: $message');
      return message;
    }
  }
}



