import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final status = message.status;

    log("MessageBubble build: isUser=$isUser, status=$status");
    IconData? statusIcon;
    Color? statusColor;

    if (message.isMine && status != null) {
      log('checkig');
      switch (status) {
        case 'sending':
          statusIcon = Icons.access_time;
          statusColor = AppColors.textTertiary;
          break;
        case 'sent':
          statusIcon = Icons.check;
          statusColor = AppColors.textTertiary;
          break;
        case 'delivered':
          statusIcon = Icons.done_all;
          statusColor = AppColors.textTertiary;
          break;
        case 'read':
          statusIcon = Icons.done_all;
          statusColor = AppColors.accentBlue;
          break;
        default:
          statusIcon = Icons.schedule;
          statusColor = AppColors.textTertiary;
      }
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.content));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Message copied',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: AppColors.cardColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // gradient: isUser ? AppColors.primaryColor : null,
            color: isUser ? AppColors.primaryColor : AppColors.cardColor,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: isUser ? const Radius.circular(4) : null,
              bottomLeft: !isUser ? const Radius.circular(4) : null,
            ),
            border:
                !isUser
                    ? Border.all(
                      color: AppColors.borderPrimary.withOpacity(0.2),
                    )
                    : null,
            boxShadow:
                isUser
                    ? [
                      BoxShadow(
                        color: AppColors.accentBlue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Right side - time and icon (auto width)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.timestamp.toLocal()),
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            isUser
                                ? AppColors.textPrimary.withOpacity(0.7)
                                : AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    if (statusIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(statusIcon, size: 16, color: statusColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}