import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';

class MailService {
  static const String _baseUrl = 'https://api.mail.tm';
  static const String _domainUrl = '$_baseUrl/domains';
  static const String _accountUrl = '$_baseUrl/accounts';
  static const String _tokenUrl = '$_baseUrl/token';
  static const String _messageUrl = '$_baseUrl/messages';

  String? _token;
  String? _accountId;
  String? _currentEmail;
  String? _currentPassword;

  String? get currentEmail => _currentEmail;
  String? get currentPassword => _currentPassword;

  /// Domínios personalizados obscure/anti-blocklist
  static const List<String> _customDomains = [
    'cl-mail.com',
    'lxcode.site',
    'nxi.tn',
    'zippyletter.co',
    'mailrht.com',
    'dropmail.cc',
    'tempmail.dev',
  ];

  /// Busca domínios disponíveis na API
  Future<List<MailDomain>> getDomains() async {
    try {
      final response = await http.get(
        Uri.parse(_domainUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hydra:member'] != null) {
          return (data['hydra:member'] as List)
              .map((e) => MailDomain.fromJson(e))
              .toList();
        }
      }
    } catch (_) {}

    // Fallback para domínios customizados
    return _customDomains
        .map((d) => MailDomain(
              id: d,
              domain: d,
              isActive: true,
              isPrivate: false,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  /// Cria uma conta de e-mail temporária
  Future<MailAccount?> createAccount({String? domain}) async {
    try {
      // Pega domínios disponíveis
      List<MailDomain> domains = await getDomains();

      if (domain == null && domains.isNotEmpty) {
        // Escolhe um domínio aleatório
        final random = Random();
        domain = domains[random.nextInt(domains.length)].domain;
      }

      if (domain == null || domain.isEmpty) {
        domain = _customDomains[Random().nextInt(_customDomains.length)];
      }

      // Gera e-mail aleatório
      final random = Random();
      final username =
          '${_generateRandomString(8)}${random.nextInt(9999)}';
      final email = '$username@$domain';
      final password = _generateRandomString(16);

      final response = await http.post(
        Uri.parse(_accountUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'address': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _currentEmail = email;
        _currentPassword = password;
        _accountId = data['id'];

        // Faz login para obter token
        await _login(email, password);

        return MailAccount(
          id: data['id'] ?? '',
          email: email,
          password: password,
          createdAt: DateTime.now(),
        );
      } else {
        // Tenta novamente com outro domínio se falhar
        if (domains.length > 1) {
          return createAccount(domain: domains[Random().nextInt(domains.length)].domain);
        }
      }
    } catch (e) {
      print('Erro ao criar conta: $e');
    }
    return null;
  }

  /// Login na API
  Future<bool> _login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'address': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _accountId = data['id'];
        return true;
      }
    } catch (e) {
      print('Erro no login: $e');
    }
    return false;
  }

  /// Busca mensagens da caixa de entrada
  Future<EmailResponse> getMessages({int page = 1}) async {
    if (_token == null) return EmailResponse(messages: []);

    try {
      final response = await http.get(
        Uri.parse('$_messageUrl?page=$page'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return EmailResponse.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar mensagens: $e');
    }
    return EmailResponse(messages: []);
  }

  /// Busca uma mensagem específica pelo ID
  Future<EmailMessage?> getMessage(String id) async {
    if (_token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_messageUrl/$id'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return EmailMessage.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Erro ao buscar mensagem: $e');
    }
    return null;
  }

  /// Marca mensagem como lida
  Future<bool> markAsRead(String id) async {
    if (_token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_messageUrl/$id'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/merge-patch+json',
        },
        body: json.encode({'seen': true}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Deleta uma mensagem
  Future<bool> deleteMessage(String id) async {
    if (_token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_messageUrl/$id'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Deleta a conta atual
  Future<bool> deleteAccount() async {
    if (_token == null || _accountId == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_accountUrl/$_accountId'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 204) {
        _token = null;
        _accountId = null;
        _currentEmail = null;
        _currentPassword = null;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Verifica se está logado
  bool get isLoggedIn => _token != null;

  /// Gera string aleatória
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
