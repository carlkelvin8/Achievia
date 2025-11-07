import 'package:flutter/material.dart';

class CustomSearchWidget extends StatelessWidget {
  const CustomSearchWidget({
    super.key,
    this.onChanged,
    this.controller,
    this.onFilterTap,
  });

  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.0,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(22.0),
      ),
      child: Row(
        children: [
          // Search TextField taking most space
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 17.0,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22.0),
                  borderSide: BorderSide(color: Colors.blue, width: 1.0),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
            child: GestureDetector(
              onTap: () {
                // Handle plus tap, e.g., add new item
                print('Plus tapped');
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
            ),
          ),
          // Filter funnel button
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list,
                color: Colors.blue,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}