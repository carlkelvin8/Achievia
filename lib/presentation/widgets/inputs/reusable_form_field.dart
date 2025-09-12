import 'package:flutter/material.dart';

class ReusableField extends StatelessWidget {
  final FormFieldValidator? validator;
  final Widget? suffixIcon;
  final Widget? icon;
  final bool? isObscure;
  final String? hintText;
  final TextEditingController controller;
  const ReusableField({
    super.key,
    this.validator,
    this.icon,
    this.isObscure,
    this.suffixIcon,
    this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      controller: controller,
      obscureText: isObscure ?? false,
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        suffixIcon: suffixIcon,
        prefixIcon: icon,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 248, 17, 0)),
        ),
        focusColor: Colors.black,
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}
