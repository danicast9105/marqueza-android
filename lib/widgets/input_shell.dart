import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class InputShell extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const InputShell({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<InputShell> createState() => _InputShellState();
}

class _InputShellState extends State<InputShell> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 7),

        //
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: _focused ? AppColors.cardBg : AppColors.inputBg,
            border: Border.all(
              color: _focused ? AppColors.borderFocus : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(widget.icon, size: 19, color: AppColors.textMuted),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }
}
