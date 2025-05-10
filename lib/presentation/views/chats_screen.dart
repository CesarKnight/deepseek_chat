import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../viewModels/chat_viewmodel.dart';
import '../../../../routing/routes.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.viewModel, this.chatId});

  final ChatViewModel viewModel;
  final String? chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = widget.viewModel.initChat(widget.chatId);
    widget.viewModel.sendMessage.addListener(_listener);
    _controller.addListener(() {
      widget.viewModel.setTyping(_controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    widget.viewModel.sendMessage.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  void _listener() {
    if (widget.viewModel.sendMessage.error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al enviar el mensaje'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () {
                widget.viewModel.sendMessage.clearResult();
              },
            ),
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Adjuntar archivos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, size: 30),
                          onPressed: () async {
                            Navigator.pop(context);
                            
                          },
                        ),
                        const Text('Cámara'),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.video_camera_back_outlined,
                            size: 30,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                        ),
                        const Text('Video'),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_outlined, size: 30),
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                        ),
                        const Text('Galería'),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.folder_outlined, size: 30),
                          onPressed: () {
                            Navigator.pop(context);
                            // Navegar a la pantalla de archivos
                            if (widget.viewModel.currentChatId != null) {
                              context.push(
                                '${Routes.chatFiles}/${widget.viewModel.currentChatId}',
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor envía un mensaje primero para crear un chat',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const Text('Archivos'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mostrar modal de grabación de voz
  void _showVoiceRecordingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Hablando...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 60,
                      child: Text(
                        widget.viewModel.recognizedText.isEmpty
                            ? 'Habla ahora'
                            : widget.viewModel.recognizedText,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AvatarGlow(
                      glowColor: Colors.blue,
                      // endRadius: 70,
                      duration: const Duration(milliseconds: 2000),
                      repeat: true,
                      // showTwoGlows: true,
                      glowCount: 2,
                      animate: widget.viewModel.isListening,
                      child: GestureDetector(
                        onTap: () async {
                          await widget.viewModel.toggleListening(_controller);
                          setState(() {}); // Actualizar el StatefulBuilder
                          if (!widget.viewModel.isListening) {
                            Navigator.pop(context);
                          }
                        },
                        child: Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  widget.viewModel.isListening
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                            child: Icon(
                              widget.viewModel.isListening
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        if (widget.viewModel.isListening) {
                          widget.viewModel.toggleListening(_controller);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'ASISTENTE LEGAL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.chatList),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error al cargar la conversación'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initFuture = widget.viewModel.initChat(widget.chatId);
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.viewModel,
                    widget.viewModel.sendMessage,
                  ]),
                  builder: (context, child) {
                    // Show loading indicator at the bottom if sending message
                    if (widget.viewModel.sendMessage.running) {
                      return Stack(
                        children: [
                          child!,
                          const Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      );
                    }
                    return child!;
                  },
                  child: DashChat(
                    currentUser: widget.viewModel.currentUser,
                    messages: widget.viewModel.messages,
                    onSend: (ChatMessage m) {
                      widget.viewModel.sendMessage.execute(m);
                    },
                    messageOptions: MessageOptions(
                      currentUserContainerColor: Colors.black,
                      containerColor: Colors.white,
                      messageTextBuilder: (message, _, __) {
                        return message.user.id ==
                                widget.viewModel.deepseekUser.id
                            ? MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                                code: TextStyle(
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.black87,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            )
                            : Text(
                              message.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            );
                      },
                      messageDecorationBuilder: (
                        ChatMessage message,
                        ChatMessage? previousMessage,
                        ChatMessage? nextMessage,
                      ) {
                        bool isUser =
                            message.user.id == widget.viewModel.currentUser.id;
                        return BoxDecoration(
                          color: isUser ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        );
                      },
                    ),
                    inputOptions: InputOptions(
                      textController: _controller,
                      showTraillingBeforeSend: true,
                      inputToolbarStyle: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      alwaysShowSend: false,
                      leading: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _showAttachmentOptions,
                          color: Colors.black87,
                        ),
                      ],
                      trailing: [
                        IconButton(
                          icon: Icon(
                            widget.viewModel.isTyping ? Icons.send : Icons.mic,
                          ),
                          onPressed: () {
                            if (widget.viewModel.isTyping) {
                              final message = ChatMessage(
                                text: _controller.text,
                                user: widget.viewModel.currentUser,
                                createdAt: DateTime.now(),
                              );
                              widget.viewModel.sendMessage.execute(message);
                              _controller.clear();
                            } else {
                              // Mostrar modal de grabación de voz
                              _showVoiceRecordingModal();
                            }
                          },
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
