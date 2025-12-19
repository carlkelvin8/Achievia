// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';


class UnansweredCard extends StatelessWidget {
  final int itemCount;
  final Widget? Function(BuildContext, int) itemBuilder;
  const UnansweredCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.only(left: 2, right: 2),
        child: Card(
          child: GridView.builder(
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 2.0,
              crossAxisSpacing: 2.0
            ), 
            itemBuilder: itemBuilder
            ),
      ),
      )
    );
  }
}
