import 'package:deepseek_chat/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import '../models/message.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser _currentUser = ChatUser(
    id: '1',
    firstName: 'Cesar',
    lastName: 'Caballero',
  );

  final ChatUser _deepseekUser = ChatUser(id: '2', firstName: 'DeepSeek');

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<Message> _messagesHistory = <Message>[
    Message(
      role: "system",
      content: "Please respond in Spanish language only.",
    ),
  ];

  // Controlador del campop de texto
  final TextEditingController _controller = TextEditingController();

  // Instancia de la clase SpeechToText
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  // Instancia de la clase TextToSpeech
  final FlutterTts _flutterTts = FlutterTts();
   bool _ttsEnabled = false;  // Add this lin

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _controller.text = '${result.recognizedWords}';
    });

    // Only send message if we have recognized words
    if (_speechToText.isNotListening) {
      // Create and send the chat message
      final message = ChatMessage(
        user: _currentUser,
        text: result.recognizedWords,
        createdAt: DateTime.now(),
      );
      
      // Stop listening and send the message
      _stopListening();
      getChatResponse(message);
      
      // Clear the text controller
      _controller.clear();
    }
  }

  void initTTS() async {
    await _flutterTts.setLanguage("es-US");
    await _flutterTts.setPitch(0.95);
    await _flutterTts.setSpeechRate(0.7);
  }
  
  @override
  void initState() {
    super.initState();
    initSpeech();
    initTTS();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _speechToText.isListening ? 'Escuchando...' : 'Deepseek Chat',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
        actions: [
          // Boton de Text a voz
          IconButton(
            icon: Icon(
              _ttsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _ttsEnabled = !_ttsEnabled;
                if (!_ttsEnabled) {
                  _flutterTts.stop();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _speechToText.isListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
            color: Colors.white,
            onPressed: () {
              _speechToText.isListening ? _stopListening() : _startListening();
            },
          ),
        ],
      ),
      body: DashChat(
        currentUser: _currentUser,
        inputOptions: InputOptions(
          alwaysShowSend: true,
          autocorrect: false,
          textController: _controller,
        ),
        messageOptions: MessageOptions(
          currentUserContainerColor: Colors.lightBlue,
          containerColor: Colors.white,
          messageTextBuilder: (message, _, __) {
            return message.user.id == _deepseekUser.id
                ? MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.black),
                    code: const TextStyle(
                      backgroundColor: Colors.black45,
                      color: Colors.white,
                    ),
                  ),
                )
                : Text(
                  message.text,
                  style: const TextStyle(color: Colors.white),
                );
          },
        ),
        onSend: (ChatMessage m) {
          getChatResponse(m);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _messagesHistory.add(Message(role: "user", content: m.text));
    });

    try {
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Authorization': 'Bearer $OPENROUTER_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': OPENROUTER_MODEL,
          'messages': _messagesHistory.map((msg) => msg.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final assistantMessage = data['choices'][0]['message']['content'];

        final botMessage = ChatMessage(
          user: _deepseekUser,
          text: assistantMessage,
          createdAt: DateTime.now(),
        );

        setState(() {
          _messages.insert(0, botMessage);
          _messagesHistory.add(
            Message(role: "assistant", content: assistantMessage),
          );
        });
        
        if (_ttsEnabled) {
            final plainTextMessage = assistantMessage.replaceAll(RegExp(r'[^\w\s]+'), '');
            await _flutterTts.speak(plainTextMessage);
        }
      } else {
        print('Failed to get response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
