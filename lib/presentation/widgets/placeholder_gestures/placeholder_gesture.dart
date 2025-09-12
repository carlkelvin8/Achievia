import 'package:flutter/material.dart';

class PlaceholderGesture extends StatelessWidget {
  const PlaceholderGesture({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.indigo),
          children: [
            TextSpan(
              text: 'Terms and conditions\n',
              style: const TextStyle(fontWeight: FontWeight.bold),
              // recognizer: TapGestureRecognizer()..onTap = () {
              //   // Navigate to Terms page
              // },
            ),
            const TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
