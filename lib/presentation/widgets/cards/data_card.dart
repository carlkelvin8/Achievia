import 'package:flutter/material.dart';

class DataCard extends StatelessWidget {
  final String dataNum;
  final String subject;
  const DataCard({super.key, required this.dataNum, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(subject),
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor
          ),
          child: Text(dataNum),
        )
      ],
    );
  }
}