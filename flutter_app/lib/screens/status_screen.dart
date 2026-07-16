import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<dynamic> _feed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getStatusFeed();
      setState(() {
        _feed = res.data['feed'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addStatus() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final uploadRes = await ApiService().uploadFile(picked.path, 'status');
    await ApiService().postStatus({'type': 'image', 'mediaUrl': uploadRes.data['url']});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: Stack(
            children: [
              const CircleAvatar(radius: 26, backgroundColor: DuoColors.surfaceDark2, child: Icon(Icons.person_rounded)),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _addStatus,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: DuoColors.cyan, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 14, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          title: const Text('My Status', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Tap to add status update'),
          onTap: _addStatus,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Recent updates', style: TextStyle(color: DuoColors.textDimDark, fontSize: 13)),
        ),
        ..._feed.map((entry) {
          final user = entry['user'];
          final statuses = entry['statuses'] as List;
          final allViewed = statuses.every((s) => (s['viewers'] as List).isNotEmpty);
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: allViewed ? null : DuoColors.brandGradient,
                border: allViewed ? Border.all(color: DuoColors.textDimDark, width: 2) : null,
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: DuoColors.surfaceDark2,
                backgroundImage: user['avatarUrl'] != null && user['avatarUrl'] != '' ? CachedNetworkImageProvider(user['avatarUrl']) : null,
              ),
            ),
            title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${statuses.length} update${statuses.length > 1 ? 's' : ''}'),
          );
        }),
      ],
    );
  }
}
