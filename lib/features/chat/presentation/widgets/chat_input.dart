import 'package:flutter/material.dart';
import 'package:hey_buddy/core/config/theme/app_colors.dart';
import 'package:hey_buddy/core/config/theme/app_text_styles.dart';

class ModernInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onAddTap;

  const ModernInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onAddTap,
  });

  void _handleSend(BuildContext context) {
    if (controller.text.trim().isEmpty) return;

    onSend();
    controller.clear();

    // ✅ Keyboard close
    focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          border: Border(
            top: BorderSide(color: AppColors.borderPrimary.withOpacity(0.08)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.add_rounded,
                onTap: onAddTap,
                isPrimary: false,
              ),
              const SizedBox(width: 8),

              /// Input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.borderPrimary.withOpacity(0.15),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textQuaternary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// Send (reactive without setState)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) {
                  final canSend = value.text.trim().isNotEmpty;

                  return _ActionButton(
                    icon: Icons.send_rounded,
                    isPrimary: canSend,
                    onTap: canSend ? () => _handleSend(context) : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Action Button
/// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color:
            isPrimary
                ? AppColors.primaryGradient.colors.first
                : AppColors.cardColor,
        shape: const CircleBorder(),
        elevation: isPrimary ? 4 : 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: 20,
            color: isPrimary ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
