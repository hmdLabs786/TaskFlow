import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) => provider.setSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Sort & Filter Options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Date'),
                selected: true,
                onSelected: (_) => provider.setSortBy('Date'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Priority'),
                selected: false,
                onSelected: (_) => provider.setSortBy('Priority'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Due Date'),
                selected: false,
                onSelected: (_) => provider.setSortBy('Due Date'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}