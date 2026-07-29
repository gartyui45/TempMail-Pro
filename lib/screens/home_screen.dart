import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_model.dart';
import '../services/mail_service.dart';
import '../widgets/neon_background.dart';
import '../widgets/email_card.dart';
import 'email_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MailService _mailService = MailService();
  List<EmailMessage> _messages = [];
  bool _isLoading = true;
  bool _isCreating = false;
  Timer? _refreshTimer;
  String _statusText = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _statusText = 'Criando seu e-mail temporário...');

    // Tenta restaurar sessão anterior
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('temp_email');
    final savedPassword = prefs.getString('temp_password');

    bool loggedIn = false;

    if (savedEmail != null && savedPassword != null) {
      setState(() => _statusText = 'Restaurando sessão...');
      // Não podemos re-logar facilmente sem token, então criamos nova
    }

    // Cria nova conta
    final account = await _mailService.createAccount();
    if (account != null && mounted) {
      await prefs.setString('temp_email', account.email);
      await prefs.setString('temp_password', account.password);

      setState(() {
        _statusText = 'E-mail: ${account.email}';
        _isLoading = false;
      });

      // Busca mensagens
      await _fetchMessages();

      // Auto-refresh a cada 10 segundos
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchMessages();
      });
    } else if (mounted) {
      setState(() {
        _statusText = 'Erro ao criar conta. Toque para tentar novamente.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _mailService.getMessages();
      if (mounted) {
        setState(() {
          _messages = response.messages;
        });
      }
    } catch (_) {}
  }

  Future<void> _createNewAccount() async {
    if (_isCreating) return;

    _refreshTimer?.cancel();
    setState(() {
      _isCreating = true;
      _isLoading = true;
      _messages = [];
      _statusText = 'Gerando novo e-mail...';
    });

    // Deleta conta anterior se existir
    await _mailService.deleteAccount();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_email');
    await prefs.remove('temp_password');

    final account = await _mailService.createAccount();
    if (account != null && mounted) {
      await prefs.setString('temp_email', account.email);
      await prefs.setString('temp_password', account.password);

      setState(() {
        _statusText = 'E-mail: ${account.email}';
        _isLoading = false;
        _isCreating = false;
      });

      await _fetchMessages();

      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchMessages();
      });
    } else if (mounted) {
      setState(() {
        _statusText = 'Erro. Toque para tentar novamente.';
        _isLoading = false;
        _isCreating = false;
      });
    }
  }

  Future<void> _markAsRead(EmailMessage msg) async {
    await _mailService.markAsRead(msg.id);
    await _fetchMessages();
  }

  Future<void> _deleteMessage(EmailMessage msg) async {
    await _mailService.deleteMessage(msg.id);
    await _fetchMessages();
  }

  void _openMessage(EmailMessage msg) async {
    await _markAsRead(msg);
    if (!mounted) return;

    final fullMsg = await _mailService.getMessage(msg.id);
    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => EmailDetailScreen(
          message: fullMsg ?? msg,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NeonBackground(
        slowMotion: true,
        child: SafeArea(
          child: Column(
            children: [
              // Header premium
              _buildHeader(),
              // Info do e-mail atual
              _buildEmailBanner(),
              // Status / Loading
              if (_isLoading) _buildLoadingState(),
              // Lista de mensagens
              if (!_isLoading) _buildMessageList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Logo neon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0044FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.email_outlined, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TEMP MAIL',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'E-mail Descartável Premium',
                style: TextStyle(
                  color: Color(0xFF446688),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botão de recriar
          GestureDetector(
            onTap: _isCreating ? null : _createNewAccount,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                ),
                color: const Color(0xFF00D4FF).withOpacity(0.05),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF00D4FF),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailBanner() {
    final email = _mailService.currentEmail ?? '---';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF001A33),
              Color(0xFF000D1A),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF00D4FF).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withOpacity(0.06),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEU E-MAIL',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 9,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Copiar
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: email));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('E-mail copiado!'),
                    backgroundColor: Color(0xFF00D4FF),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF00D4FF).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF00D4FF),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'NENHUM E-MAIL AINDA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 14,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aguardando novas mensagens...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'CAIXA DE ENTRADA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF00D4FF).withOpacity(0.15),
                  ),
                  child: Text(
                    '${_messages.length}',
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                return Dismissible(
                  key: Key(msg.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.red.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                  ),
                  onDismissed: (_) => _deleteMessage(msg),
                  child: EmailCard(
                    message: msg,
                    onTap: () => _openMessage(msg),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
