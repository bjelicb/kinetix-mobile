import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/haptic_feedback.dart';

class CustomNumpad extends StatefulWidget {
  final Function(String) onValueChanged;
  final Function()? onConfirm;
  final String initialValue;
  final bool allowDecimal;

  const CustomNumpad({
    super.key,
    required this.onValueChanged,
    this.onConfirm,
    this.initialValue = '',
    this.allowDecimal = true,
  });

  @override
  State<CustomNumpad> createState() => _CustomNumpadState();
}

class _CustomNumpadState extends State<CustomNumpad> with SingleTickerProviderStateMixin {
  String _value = '';
  String? _pressedButton;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _animationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    AppHaptic.selection();
    setState(() {
      _value += number;
    });
    widget.onValueChanged(_value);
  }

  void _onDecimalTap() {
    if (!widget.allowDecimal || _value.contains('.')) return;
    AppHaptic.selection();
    setState(() {
      _value += '.';
    });
    widget.onValueChanged(_value);
  }

  void _onBackspace() {
    if (_value.isEmpty) return;
    AppHaptic.light();
    setState(() {
      _value = _value.substring(0, _value.length - 1);
    });
    widget.onValueChanged(_value);
  }

  void _onClear() {
    AppHaptic.medium();
    setState(() {
      _value = '';
    });
    widget.onValueChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Value Display
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _value.isEmpty ? '0' : _value,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_value.isNotEmpty)
                    IconButton(
                      onPressed: _onClear,
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),

            // NOVO: Quick-select buttons (show when initialValue is "0" or empty)
            if (widget.initialValue == '0' || widget.initialValue.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Select',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...([
                          5,
                          10,
                          15,
                          20,
                          25,
                          30,
                          35,
                          40,
                          45,
                          50,
                        ].map((weight) => _buildQuickSelectButton(weight.toString()))),
                        _buildCustomButton(),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // Numpad Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  _buildBottomRow(),
                ],
              ),
            ),

            // Confirm Button
            if (widget.onConfirm != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _value.isNotEmpty ? widget.onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(children: numbers.map((number) => Expanded(child: _buildNumberButton(number))).toList());
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(child: widget.allowDecimal ? _buildNumberButton('.') : const SizedBox()),
        Expanded(child: _buildNumberButton('0')),
        Expanded(child: _buildBackspaceButton()),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    final isPressed = _pressedButton == number;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressedButton = number;
          });
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressedButton = null;
          });
          number == '.' ? _onDecimalTap() : _onNumberTap(number);
        },
        onTapCancel: () {
          setState(() {
            _pressedButton = null;
          });
        },
        onLongPress: number == '0' ? _onClear : null,
        child: AnimatedScale(
          scale: isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: isPressed ? AppGradients.primary : AppGradients.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPressed ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                width: isPressed ? 2 : 1,
              ),
              boxShadow: isPressed
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)]
                  : null,
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isPressed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(String value) {
    return GestureDetector(
      onTap: () {
        AppHaptic.selection();
        setState(() {
          _value = value;
        });
        widget.onValueChanged(_value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCustomButton() {
    return GestureDetector(
      onTap: () {
        AppHaptic.selection();
        setState(() {
          _value = '';
        });
        widget.onValueChanged(_value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1),
        ),
        child: Text(
          'Custom',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    final isPressed = _pressedButton == 'backspace';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressedButton = 'backspace';
          });
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressedButton = null;
          });
          _onBackspace();
        },
        onTapCancel: () {
          setState(() {
            _pressedButton = null;
          });
        },
        onLongPress: _onClear,
        child: AnimatedScale(
          scale: isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: AppGradients.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isPressed
                  ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)]
                  : null,
            ),
            child: const Icon(Icons.backspace_rounded, color: AppColors.textPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}
