import 'package:deepseek_chat/presentation/views/chat_file_screen.dart';
import 'package:deepseek_chat/presentation/views/chat_list_screen.dart';
import 'package:deepseek_chat/presentation/viewModels/chat_list_viewmodel.dart';
import 'package:deepseek_chat/presentation/viewModels/chat_viewmodel.dart';
import 'package:deepseek_chat/presentation/views/chats_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'routes.dart';

class SlideTransitionPage extends CustomTransitionPage<void> {
  SlideTransitionPage({
    required Widget child,
    required bool slideFromRight,
    String? routeName,
  }) : super(
          key: routeName != null ? ValueKey(routeName) : null,
          child: child,
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            var begin = Offset(slideFromRight ? 1.0 : -1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

GoRouter router() => GoRouter(
  initialLocation: Routes.chat,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: Routes.chat,
      name: 'chat',
      pageBuilder: (context, state) {
        final viewModel = context.read<ChatViewModel>();
        viewModel.resetChat();
        return SlideTransitionPage(
          slideFromRight: true,  // Entra desde la derecha
          routeName: 'chat',
          child: ChatScreen(
            viewModel: viewModel,
          ),
        );
      },
    ),
    GoRoute(
      path: Routes.chatList,
      name: 'chatList',
      pageBuilder: (context, state) {
        return SlideTransitionPage(
          slideFromRight: false,  // Entra desde la izquierda
          routeName: 'chatList',
          child: ChatListScreen(viewModel: context.read<ChatListViewModel>()),
        );
      },
    ),
    GoRoute(
      path: Routes.chatWithId,
      name: 'chatWithId',
      pageBuilder: (context, state) {
        final chatId = state.pathParameters['id']!;
        final viewModel = context.read<ChatViewModel>();
        viewModel.loadChat.execute(chatId);

        return SlideTransitionPage(
          slideFromRight: true,  // Entra desde la derecha
          routeName: 'chatWithId-$chatId',
          child: ChatScreen(viewModel: viewModel),
        );
      },
    ),
    //chatFiles
    GoRoute(
  path: '${Routes.chatFiles}/:id',
  name: 'chatFiles',
  pageBuilder: (context, state) {
    final chatId = state.pathParameters['id']!;
    final chatViewModel = context.read<ChatViewModel>();

    // Intentar obtener el título del chat si existe
    String? chatTitle;
    if (chatViewModel.currentChatId == chatId) {
      // Si estamos en el mismo chat, podemos usar la información actual
      chatTitle = "Chat actual"; // O algún otro título que tengas
    }

    return SlideTransitionPage(
      slideFromRight: true,
      routeName: 'chatFiles-$chatId',
      child: ChatFilesScreen(
        chatId: chatId,
        chatTitle: chatTitle,
      ),
    );
  },
),
  ],
);