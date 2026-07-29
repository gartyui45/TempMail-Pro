import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/email_model.dart';

class EmailCard extends StatelessWidget {
  final EmailMessage message;
  final VoidCallback onTap;

  const EmailCard({
    super.key,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);
    final dateStr = DateFormat('dd/MM').format(message.createdAt);

    String fromDisplay = message.from;
    if (fromDisplay.length > 30) {
      fromDisplay = '${fromDisplay.substring(0, 27)}...';
    }

    String subjectDisplay = message.subject;
    if (subjectDisplay.length > 40) {
      subjectDisplay = '${subjectDisplay.substring(0, 37)}...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: message.seen
                  ? [
                      const Color(0xFF0D1B2A).withOpacity(0.7),
                      const Color(0xFF0A0E27).withOpacity(0.7),
                    ]
                  : [
                      const Color(0xFF002244).withOpacity(0.6),
                      const Color(0xFF001133).withOpacity(0.6),
                    ],
            ),
            border: Border.all(
              color: message.seen
                  ? const Color(0xFF00D4FF).withOpacity(0.1)
                  : const Color(0xFF00D4FF).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: message.seen
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFF00D4FF),
                        Color(0xFF0044FF),
                        Color(0xFF00D4FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (message.from.isNotEmpty
                              ? message.from[0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fromDisplay,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14,
                                fontWeight: message.seen
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subjectDisplay,
                        style: TextStyle(
                          color: const Color(0xFF00D4FF).withOpacity(0.9),
                          fontSize: 15,
                          fontWeight:
                              message.seen ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                      if (message.intro.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          message.intro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!message.seen)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00D4FF),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00D4FF),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
