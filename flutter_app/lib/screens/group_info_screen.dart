import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GroupInfoScreen extends StatelessWidget {
  final String chatId;
  final String groupName;

  const GroupInfoScreen({super.key, required this.chatId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: DuoColors.brandGradient),
                child: Center(
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.groups_rounded, size: 52, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(groupName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Group · 12 members', style: TextStyle(color: DuoColors.textDimDark)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionIcon(Icons.call_rounded, 'Voice'),
                      _actionIcon(Icons.videocam_rounded, 'Video'),
                      _actionIcon(Icons.person_add_alt_rounded, 'Add'),
                      _actionIcon(Icons.notifications_off_outlined, 'Mute'),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('Invite link', style: TextStyle(color: DuoColors.textDimDark, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: DuoColors.surfaceDark2, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Expanded(child: Text('duochat.app/invite/xyz123', style: TextStyle(color: DuoColors.cyan))),
                        IconButton(icon: const Icon(Icons.copy_rounded, size: 18), onPressed: () {}),
                      ],
                    ),
                  ),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('12 Members', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: const Text('Add')),
                    ],
                  ),
                  ..._demoMembers.map(
                    (m) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(backgroundColor: DuoColors.surfaceDark2, child: Icon(Icons.person_rounded)),
                      title: Text(m['name']!),
                      trailing: m['role'] == 'admin' ? const Text('Admin', style: TextStyle(color: DuoColors.cyan, fontSize: 12)) : null,
                    ),
                  ),
                  const Divider(height: 40),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                    title: const Text('Exit group', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _demoMembers = [
    {'name': 'You', 'role': 'admin'},
    {'name': 'Aisha Khan', 'role': 'member'},
    {'name': 'Rahul Verma', 'role': 'member'},
  ];

  Widget _actionIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 24, backgroundColor: DuoColors.surfaceDark2, child: Icon(icon, color: DuoColors.violet)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
