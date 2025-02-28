import 'package:flutter/material.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';
import 'package:open_player/utils/extensions.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final Widget? sideWidget;
  final bool isSelected;
  final VoidCallback onSelected;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.sideWidget,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = context.themeCubit.state.isDarkMode;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha:0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            

            sideWidget??nothing
          ],
        ),
      ),
    );
  }
}
