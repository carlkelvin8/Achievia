import 'package:flutter/material.dart';

class ReusableField extends StatelessWidget {
  final FormFieldValidator? validator;
  final Widget? suffixIcon;
  final Widget? prefix;
  final bool? isObscure;
  final String? hintText;
  final TextEditingController controller;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final BorderRadius? borderRadius;
  const ReusableField({
    super.key,
    this.validator,
    this.prefix,
    this.isObscure,
    this.suffixIcon,
    this.hintText,
    required this.controller,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      controller: controller,
      obscureText: isObscure ?? false,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        suffixIcon: suffixIcon,
        prefixIcon: prefix,
        hintText: hintText,
        errorText: errorText,
        hintStyle: TextStyle(color: Colors.grey),

        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 248, 17, 0)),
        ),
        focusColor: Colors.black,
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        enabledBorder: errorText != null
            ? OutlineInputBorder(
                borderSide: BorderSide(color: Colors.redAccent),
              )
            : OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDBDEE4)),
              ),
        focusedBorder: errorText != null
            ? OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 248, 17, 0)),
              )
            : OutlineInputBorder(
                borderRadius:
                    borderRadius ?? BorderRadius.all(Radius.circular(0)),
                borderSide: BorderSide(color: Colors.black),
              ),
      ),
    );
  }
}
