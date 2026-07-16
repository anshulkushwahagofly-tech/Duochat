import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  // In production this list is fetched from GET /api/calls (call-log endpoint,
  // recorded whenever a call:end signaling event completes on the backend).
  final List<Map<String, dynamic>> _demoCalls = const [
    {'name': 'Aisha Khan', 'type': 'video', 'direction': 'outgoing', 'time': 'Today, 10:24 AM'},
    {'name': 'Rahul Verma', 'type': 'voice', 'direction': 'incoming', 'time': 'Today, 9:02 AM'},
    {'name': 'Design Team', 'type': 'voice', 'direction': 'missed', 'time': 'Yesterday, 6:41 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _demoCalls.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
      itemBuilder: (context, i) {
        final call = _demoCalls[i];
        final isMissed = call['direction'] == 'missed';
        return ListTile(
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: DuoColors.surfaceDark2,
            child: const Icon(Icons.person_rounded),
          ),
          title: Text(call['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Icon(
                call['direction'] == 'incoming' ? Icons.call_received_rounded : Icons.call_made_rounded,
                size: 14,
                color: isMissed ? Colors.redAccent : DuoColors.online,
              ),
              const SizedBox(width: 4),
              Text(call['time'], style: TextStyle(color: isMissed ? Colors.redAccent : DuoColors.textDimDark, fontSize: 13)),
            ],
          ),
          trailing: Icon(call['type'] == 'video' ? Icons.videocam_rounded : Icons.call_rounded, color: DuoColors.violet),
        );
      },
    );
  }
}
