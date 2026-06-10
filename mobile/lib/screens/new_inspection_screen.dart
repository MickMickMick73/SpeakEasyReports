import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';

class NewInspectionScreen extends StatelessWidget {
  const NewInspectionScreen({super.key, required this.onSelect});

  final ValueChanged<InspectionType> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Job type')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: InspectionType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelect(type),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border, width: 2),
                  ),
                  child: Text(
                    inspectionTypeLabel(type),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}