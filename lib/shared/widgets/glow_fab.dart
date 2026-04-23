import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class GlowFAB extends StatefulWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onTextTap;

  const GlowFAB({
    super.key,
    required this.onCameraTap,
    required this.onVoiceTap,
    required this.onTextTap,
  });

  @override
  State<GlowFAB> createState() => _GlowFABState();
}

class _GlowFABState extends State<GlowFAB> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56 + 160.0,
      height: 56,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_isOpen) ...[
            _buildOption(
              index: 0,
              label: 'Camera',
              icon: Icons.camera_alt,
              color: AppColors.calories,
              onTap: widget.onCameraTap,
            ),
            _buildOption(
              index: 1,
              label: 'Voice',
              icon: Icons.mic,
              color: AppColors.protein,
              onTap: widget.onVoiceTap,
            ),
            _buildOption(
              index: 2,
              label: 'Text',
              icon: Icons.edit_note,
              color: AppColors.carbs,
              onTap: widget.onTextTap,
            ),
          ],
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: _isOpen ? 8 : 20,
                      spreadRadius: _isOpen ? 0 : 4,
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: _isOpen ? 0.125 : 0,
                  child: Icon(
                    _isOpen ? Icons.close : Icons.add,
                    color: AppColors.textOnPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Positioned(
      right: 56 + 8.0 + (index * 52.0),
      child: FadeTransition(
        opacity: _scaleAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () {
              _toggle();
              onTap();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
