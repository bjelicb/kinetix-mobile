import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Widget for exercise search input field
class ExerciseSearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const ExerciseSearchBarWidget({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  State<ExerciseSearchBarWidget> createState() => _ExerciseSearchBarWidgetState();
}

class _ExerciseSearchBarWidgetState extends State<ExerciseSearchBarWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: widget.controller,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: widget.onClear,
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

