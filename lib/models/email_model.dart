class MailDomain {
  final String id;
  final String domain;
  final bool isActive;
  final bool isPrivate;
  final DateTime createdAt;

  MailDomain({
    required this.id,
    required this.domain,
    this.isActive = true,
    this.isPrivate = false,
    required this.createdAt,
  });

  factory MailDomain.fromJson(Map<String, dynamic> json) {
    return MailDomain(
      id: json['id'] ?? '',
      domain: json['domain'] ?? '',
      isActive: json['isActive'] ?? true,
      isPrivate: json['isPrivate'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class MailAccount {
  final String id;
  final String email;
  final String password;
  final DateTime createdAt;

  MailAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  factory MailAccount.fromJson(Map<String, dynamic> json) {
    return MailAccount(
      id: json['id'] ?? '',
      email: json['address'] ?? json['email'] ?? '',
      password: json['password'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': email,
        'password': password,
        'createdAt': createdAt.toIso8601String(),
      };
}

class EmailMessage {
  final String id;
  final String subject;
  final String from;
  final String to;
  final String intro;
  final String body;
  final bool seen;
  final DateTime createdAt;

  EmailMessage({
    required this.id,
    required this.subject,
    required this.from,
    required this.to,
    this.intro = '',
    this.body = '',
    this.seen = false,
    required this.createdAt,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    String subject = json['subject'] ?? '(Sem assunto)';
    if (subject == '') subject = '(Sem assunto)';

    String from = json['from'] != null && json['from'] is Map
        ? '${json['from']['name'] ?? ''} <${json['from']['address'] ?? ''}>'
        : (json['from']?.toString() ?? 'Desconhecido');

    String to = json['to'] != null && json['to'] is List && json['to'].isNotEmpty
        ? (json['to'][0] is Map
            ? json['to'][0]['address'] ?? ''
            : json['to'][0].toString())
        : (json['recipient']?.toString() ?? '');

    String intro = json['intro'] ?? '';

    String body = '';
    if (json['html'] != null && json['html'].isNotEmpty) {
      body = json['html'];
    } else if (json['text'] != null) {
      body = json['text'];
    } else if (json['body'] != null) {
      body = json['body'].toString();
    }

    return EmailMessage(
      id: json['id'] ?? '',
      subject: subject,
      from: from,
      to: to,
      intro: intro,
      body: body,
      seen: json['seen'] ?? json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['date'] != null
              ? DateTime.parse(json['date'])
              : DateTime.now()),
    );
  }
}

class EmailResponse {
  final List<EmailMessage> messages;
  final int total;
  final int page;
  final int pageCount;

  EmailResponse({
    required this.messages,
    this.total = 0,
    this.page = 1,
    this.pageCount = 1,
  });

  factory EmailResponse.fromJson(Map<String, dynamic> json) {
    List<EmailMessage> msgs = [];
    if (json['hydra:member'] != null) {
      msgs = (json['hydra:member'] as List)
          .map((e) => EmailMessage.fromJson(e))
          .toList();
    } else if (json['messages'] != null) {
      msgs = (json['messages'] as List)
          .map((e) => EmailMessage.fromJson(e))
          .toList();
    }

    return EmailResponse(
      messages: msgs,
      total: json['total'] ?? json['hydra:totalItems'] ?? msgs.length,
      page: json['page'] ?? 1,
      pageCount: json['pageCount'] ?? 1,
    );
  }
}
