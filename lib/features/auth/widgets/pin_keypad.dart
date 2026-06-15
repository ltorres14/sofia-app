import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const buttons = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    final responsive = AppResponsive.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.spacingSm;
        final buttonHeight = responsive.keypadButtonSize;
        final digitFontSize = (buttonHeight * 0.34).clamp(22, 30).toDouble();

        return IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: buttons.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 1,
                    mainAxisExtent: buttonHeight,
                  ),
                  itemBuilder: (context, index) {
                    return FilledButton(
                      onPressed: () => onDigit(buttons[index]),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(buttonHeight, buttonHeight),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        buttons[index],
                        style: TextStyle(fontSize: digitFontSize),
                      ),
                    );
                  },
                ),
                SizedBox(width: spacing),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.clear_all_rounded,
                        label: 'Limpiar',
                        height: responsive.buttonHeight.toDouble(),
                        onPressed: onClear,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: SizedBox(
                        height: responsive.buttonHeight.toDouble(),
                        child: FilledButton(
                          onPressed: () => onDigit('0'),
                          child: Text(
                            '0',
                            style: TextStyle(fontSize: digitFontSize),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.backspace_rounded,
                        label: 'Borrar',
                        height: responsive.buttonHeight,
                        onPressed: onBackspace,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.height,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    );
  }
}
