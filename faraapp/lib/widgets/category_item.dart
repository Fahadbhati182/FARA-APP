import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap; // 👈 Add this

  const CategoryItem({
    super.key,
    required this.title,
    this.onTap, // 👈 Add this
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 👈 Wrap Column with GestureDetector
      onTap: onTap,
      child: Column( // 👈 Column is now inside GestureDetector
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.fastfood, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}