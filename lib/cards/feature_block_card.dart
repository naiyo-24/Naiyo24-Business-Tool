import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

/// A "Getting Started" feature block card matching the Naiyo Business Tool dashboard style.
///
/// Displays a circular icon badge, a bold title, a short description, and an
/// outlined action button that routes to the target screen when tapped.
class FeatureBlockCard extends StatefulWidget {
  const FeatureBlockCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.onCardTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onCardTap;

  @override
  State<FeatureBlockCard> createState() => _FeatureBlockCardState();
}

class _FeatureBlockCardState extends State<FeatureBlockCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onCardTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        splashColor: widget.iconColor.withValues(alpha: 0.05),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: _isHovered
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : AppColors.border,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon badge ────────────────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 26, color: widget.iconColor),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title ─────────────────────────────────────────────────────────
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Description ───────────────────────────────────────────────────
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Action button ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onAction,
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(const Size(0, 44)),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.lg,
                      ),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.button),
                      ),
                    ),
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: widget.iconColor, width: 1.5);
                      }
                      return const BorderSide(color: AppColors.border);
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return widget.iconColor.withValues(alpha: 0.06);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return widget.iconColor;
                      }
                      return AppColors.textSecondary;
                    }),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Text(
                    widget.actionLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
