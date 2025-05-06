import 'package:deepseek_chat/presentation/viewModels/chat_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/chat_preview.dart';
import '../../../../routing/routes.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    required this.viewModel,
  });

  final ChatListViewModel viewModel;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadChatList.execute();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar conversaciones...',
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
            ),
            onChanged: widget.viewModel.filterChats,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.viewModel,
          widget.viewModel.loadChatList,
        ]),
        builder: (context, _) {
          if (widget.viewModel.loadChatList.running) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.loadChatList.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error al cargar las conversaciones'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => widget.viewModel.loadChatList.execute(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (widget.viewModel.filteredChats.isEmpty) {
            return const Center(
              child: Text('No hay conversaciones guardadas'),
            );
          }

          return ListView.builder(
            itemCount: widget.viewModel.filteredChats.length,
            itemBuilder: (context, index) {
              final chat = widget.viewModel.filteredChats[index];
              return _buildChatItem(chat);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(Routes.chat),
        tooltip: 'Nuevo chat',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChatItem(ChatPreview chat) {
    return Dismissible(
      key: Key(chat.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        widget.viewModel.deleteChat.execute(chat.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conversación eliminada'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => widget.viewModel.restoreChat.execute(chat.id),
            ),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          chat.lastMessage,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(chat.updatedAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${chat.messageCount} mensajes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => context.go('${Routes.chat}/${chat.id}'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}