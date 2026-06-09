import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../models/session.dart';
import 'setup_screen.dart';
import 'new_inspection_screen.dart';

class InspectionFlow extends StatefulWidget {
  const InspectionFlow({super.key, required this.state});

  final AppState state;

  @override
  State<InspectionFlow> createState() => _InspectionFlowState();
}

class _InspectionFlowState extends State<InspectionFlow> {
  InspectionType? _type;

  @override
  Widget build(BuildContext context) {
    if (_type == null) {
      return NewInspectionScreen(onSelect: (type) async {
        final session = InspectionSession(
          id: const Uuid().v4(),
          inspectionType: type,
          jobReference: '',
        );
        await widget.state.setActiveSession(session);
        setState(() => _type = type);
      });
    }
    return SetupScreen(state: widget.state);
  }
}