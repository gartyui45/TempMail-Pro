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

  /// 🔥 Domínios ANTI-BLOCKLIST - Obscuros e desconhecidos
  /// Esses domínios passam despercebidos pelos sistemas de bloqueio
  static const List<String> _antiBlocklistDomains = [
    'cl-mail.com',
    'lxcode.site',
    'nxi.tn',
    'zippyletter.co',
    'mailrht.com',
    'dropmail.cc',
    'tempmail.dev',
    'neo-mail.co',
    'cyph.email',
    'xmailer.one',
    'prontobox.net',
    'quickinbox.co',
    'flash-mail.xyz',
    'vaultmail.cc',
    'silentbox.info',
    'cipherpost.net',
    'eclipso.space',
    'quantummail.me',
    'nexusmail.io',
    'aurorabox.co',
  ];

  /// Cache de domínios da API
  List<MailDomain> _cachedDomains = [];

  /// Busca domínios disponíveis (com cache)
  Future<List<String>> getDomains({bool forceRefresh = false}) async {
    if (_cachedDomains.isNotEmpty && !forceRefresh) {
      return _cachedDomains.map((d) => d.domain).toList();
    }

    try {
      final response = await http.get(
        Uri.parse(_domainUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hydra:member'] != null) {
          _cachedDomains = (data['hydra:member'] as List)
              .map((e) => MailDomain.fromJson(e))
              .toList();
          if (_cachedDomains.isNotEmpty) {
            return _cachedDomains.map((d) => d.domain).toList();
          }
        }
      }
    } catch (_) {}

    // Fallback para domínios anti-blocklist
    return List.from(_antiBlocklistDomains);
  }

  /// Cria uma conta de e-mail instantânea
  Future<MailAccount?> createAccount({String? domain}) async {
    try {
      List<String> domains = await getDomains();

      if (domain == null && domains.isNotEmpty) {
        // Tenta domínios aleatórios até conseguir
        domains.shuffle(Random());
        for (final d in domains) {
          final result = await _tryCreateAccount(d);
          if (result != null) return result;
        }
      }

      // Último recurso: domínios anti-blocklist
      final shuffled = List.from(_antiBlocklistDomains)..shuffle(Random());
      for (final d in shuffled) {
        final result = await _tryCreateAccount(d);
        if (result != null) return result;
      }
    } catch (e) {
      print('Erro ao criar conta: $e');
    }
    return null;
  }

  /// Tenta criar conta em um domínio específico
  Future<MailAccount?> _tryCreateAccount(String domain) async {
    try {
      final random = Random();
      final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final prefix = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      final suffix = random.nextInt(999999);
      final email = '$prefix$suffix@$domain';
      final password = List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();

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

        // Login automático
        await _login(email, password);

        return MailAccount(
          id: data['id'] ?? '',
          email: email,
          password: password,
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {}
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
    } catch (_) {}
    return false;
  }

  /// Busca mensagens INSTANTANEAMENTE
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

      // Token expirado? Tenta renovar
      if (response.statusCode == 401 && _currentEmail != null && _currentPassword != null) {
        await _login(_currentEmail!, _currentPassword!);
        return getMessages(page: page);
      }
    } catch (_) {}
    return EmailResponse(messages: []);
  }

  /// Busca mensagem por ID
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
    } catch (_) {}
    return null;
  }

  /// Marca como lida
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
    } catch (_) {
      return false;
    }
  }

  /// Deleta mensagem
  Future<bool> deleteMessage(String id) async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_messageUrl/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Deleta conta atual
  Future<bool> deleteAccount() async {
    if (_token == null || _accountId == null) return false;
    try {
      await http.delete(
        Uri.parse('$_accountUrl/$_accountId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      _token = null;
      _accountId = null;
      _currentEmail = null;
      _currentPassword = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isLoggedIn => _token != null;

  /// Gera string aleatória segura
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
