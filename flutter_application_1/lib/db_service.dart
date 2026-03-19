import 'package:http/http.dart' as http;
import 'dart:convert';

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

// Servizio per comunicare con il backend API Node.js/Express
class DbService {
  // URL base del backend.
  // Nota: su emulatori Android in genere si usa 10.0.2.2 al posto di localhost.


  //static const String _baseUrl = 'http://10.0.2.2:3002/api';
  static const String _baseUrl = 'http://localhost:3002/api'; // web/desktop


  // Metodo helper per fare richieste POST
  static Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
    ) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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
      final response = await http.get(url);

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
    required String userId,
    required String password,
  }) async {
    try {
      final response = await _postRequest('/login', {
        'userId': userId,
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
            final giorno = DateTime.tryParse(giornoRaw);
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
          // Manteniamo solo le righe completamente parseabili.
          .whereType<SpesaItem>()
          .toList();
    } catch (e) {
      print('Errore caricamento ultime spese: $e');
      return <SpesaItem>[];
    }
  }
}



