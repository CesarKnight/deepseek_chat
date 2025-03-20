import 'package:deepseek_chat/consts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';

import 'package:dash_chat_2/dash_chat_2.dart';

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

  final ChatUser _deepseekUser = ChatUser(
    id: '2',
    firstName: 'DeepSeek',
  );

  List<ChatMessage> _messages = <ChatMessage>[];
  List<Message> _messagesHistory = <Message>[];
  
  // TODO: Add a list of messages to store the chat history
  // TODO: Implement a model for the messages
  // TODO: Implement a http client to request the chat response from the API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Deepseek Chat',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
        icon: Icon(Icons.assistant),
        onPressed: () {
          // Add your onPressed code here!
        },
          ),
        ],
      ),
      body: DashChat(
        currentUser: _currentUser, 
        messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Colors.lightBlue,
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m){
          getChatResponse(m);
        }, messages: _messages),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async{
    setState(() {
      _messages.insert(0, m);
      _messagesHistory.add(Message(
        role: "user",
        content: m.text,
      ));
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
          _messagesHistory.add(Message(
            role: "assistant",
            content: assistantMessage,
          ));
        });
      } else {
        print('Failed to get response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }

  }
}