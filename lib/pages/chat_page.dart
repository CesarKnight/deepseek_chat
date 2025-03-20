import 'package:deepseek_chat/consts.dart';
import 'package:flutter/material.dart';

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
  
  // TODO: Add a list of messages to store the chat history
  // TODO: Implement a model for the messages
  // TODO: Implement a http client to request the chat response from the API
  // List<Message> _messagesHistory = <Message>[];

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
    });

    // 

  }
}