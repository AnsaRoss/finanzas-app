import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.labelText,
    required this.keyboardType,
    required this.textInputAction,
    required this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.controller,
    this.suffixIcon,
    super.key,
  });

  final String labelText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final bool obscureText;
  final bool enabled;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
