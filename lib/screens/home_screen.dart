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
  String _statusText = '🔥 Inicializando CypherMail...';
  int _emailCount = 0;
  String _lastEmail = '';

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
    setState(() => _statusText = '🔷 Gerando e-mail anti-blocklist...');
    await _createNewEmail();
  }

  Future<void> _createNewEmail() async {
    if (_isCreating) return;

    _refreshTimer?.cancel();
    setState(() {
      _isCreating = true;
      _isLoading = true;
      _statusText = '🌀 Gerando e-mail CypherMail...';
    });

    // Deleta conta anterior se existir
    await _mailService.deleteAccount();

    final prefs = await SharedPreferences.getInstance();

    final account = await _mailService.createAccount();
    if (account != null && mounted) {
      await prefs.setString('temp_email', account.email);
      await prefs.setString('temp_password', account.password);

      _emailCount++;
      _lastEmail = account.email;

      setState(() {
        _statusText = '✅ E-mail ativo: ${account.email}';
        _isLoading = false;
        _isCreating = false;
      });

      // Busca mensagens imediatamente
      await _fetchMessages();

      // Auto-refresh RÁPIDO a cada 5 segundos (instantâneo)
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _fetchMessages();
      });
    } else if (mounted) {
      setState(() {
        _statusText = '❌ Erro. Toque para tentar novamente.';
        _isLoading = false;
        _isCreating = false;
      });
    }
  }

  Future<void> _generateNewEmail() async {
    await _createNewEmail();
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
              _buildHeader(),
              if (_isLoading) _buildLoadingState(),
              if (!_isLoading) ...[
                _buildEmailBanner(),
                _buildMessageList(),
              ],
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
          // Logo neon 3D
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0044FF), Color(0xFF7000FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Text('🛡️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CYPHERMAIL',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Color(0xFF00D4FF),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              Text(
                'E-MAIL ANTI-BLOCKLIST PREMIUM',
                style: TextStyle(
                  color: Color(0xFF446688),
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botão NOVO E-MAIL
          GestureDetector(
            onTap: _isCreating ? null : _generateNewEmail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0044FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _isCreating ? '...' : 'NOVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            color: const Color(0xFF00D4FF).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D4FF).withOpacity(0.15),
                  ),
                  child: const Icon(Icons.email_rounded, color: Color(0xFF00D4FF), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'SEU E-MAIL ATIVO',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF00FF00).withOpacity(0.15),
                  ),
                  child: const Text(
                    '● ONLINE',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 E-mail copiado!'),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFF00D4FF),
                    Color(0xFF0044FF),
                    Color(0xFF7000FF),
                    Color(0xFF00D4FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🛡️', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.inbox_rounded, color: Color(0xFF00D4FF), size: 14),
                const SizedBox(width: 6),
                Text(
                  'CAIXA DE ENTRADA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                const Spacer(),
                Text(
                  '🔄 Auto 5s',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AGUARDANDO E-MAILS...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 13,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envie um e-mail para seu endereço',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.12),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Os códigos chegam automaticamente!',
                          style: TextStyle(
                            color: const Color(0xFF00D4FF).withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
