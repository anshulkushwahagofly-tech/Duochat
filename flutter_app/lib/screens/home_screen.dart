import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';
import 'status_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  List<dynamic> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SocketService().connect();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final res = await ApiService().getChats();
      setState(() {
        _chats = res.data['chats'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildChatsTab(), const StatusScreen(), const CallsScreen()];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(gradient: DuoColors.brandGradient, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('DuoChat', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: pages[_tabIndex],
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.chat_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.donut_large_outlined), selectedIcon: Icon(Icons.donut_large_rounded), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call_rounded), label: 'Calls'),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_chats.isEmpty) {
      return Center(
        child: Text('No chats yet — tap + to start one', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      );
    }
    return ListView.separated(
      itemCount: _chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
      itemBuilder: (context, i) {
        final chat = _chats[i];
        final isGroup = chat['isGroup'] == true;
        final other = isGroup ? null : (chat['participants'] as List).firstWhere((p) => true, orElse: () => null);
        final title = isGroup ? chat['groupName'] : (other?['name'] ?? other?['phoneNumber'] ?? 'Unknown');
        final avatarUrl = isGroup ? chat['groupAvatarUrl'] : other?['avatarUrl'];
        final lastMsg = chat['lastMessage'];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: DuoColors.surfaceDark2,
            backgroundImage: (avatarUrl != null && avatarUrl != '') ? CachedNetworkImageProvider(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl == '')
                ? Icon(isGroup ? Icons.groups_rounded : Icons.person_rounded, color: DuoColors.textDimDark)
                : null,
          ),
          title: Text(title ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            lastMsg != null ? (lastMsg['isDeleted'] == true ? 'This message was deleted' : (lastMsg['text'] ?? '📎 Media')) : 'Say hi 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (chat['lastMessageAt'] != null)
                Text(timeago.format(DateTime.parse(chat['lastMessageAt']), locale: 'en_short'),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 6),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat['_id'], title: title ?? 'Chat', avatarUrl: avatarUrl, isGroup: isGroup)),
          ),
        );
      },
    );
  }
}
