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
        color: const Color.fromARGB(255, 17, 44, 131),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Spacer(),
          Card(
            child: GridView.builder(
              padding: EdgeInsets.all(8.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 2.0,
                crossAxisSpacing: 3.0,
              ),
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ),
    );
  }
}
