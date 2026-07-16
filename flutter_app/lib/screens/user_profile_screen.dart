import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String name;
  final String? avatarUrl;

  const UserProfileScreen({super.key, required this.userId, required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: DuoColors.brandGradient),
                child: Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white24,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? CachedNetworkImageProvider(avatarUrl!) : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty) ? const Icon(Icons.person_rounded, size: 64, color: Colors.white) : null,
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
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Online', style: TextStyle(color: DuoColors.online)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionIcon(context, Icons.call_rounded, 'Voice'),
                      _actionIcon(context, Icons.videocam_rounded, 'Video'),
                      _actionIcon(context, Icons.search_rounded, 'Search'),
                      _actionIcon(context, Icons.notifications_off_outlined, 'Mute'),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('About', style: TextStyle(color: DuoColors.textDimDark, fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text('Hey there! I am using DuoChat.'),
                  const Divider(height: 40),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
                    title: const Text('Block user', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {},
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.report_rounded, color: Colors.redAccent),
                    title: const Text('Report', style: TextStyle(color: Colors.redAccent)),
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

  Widget _actionIcon(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 24, backgroundColor: DuoColors.surfaceDark2, child: Icon(icon, color: DuoColors.violet)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
