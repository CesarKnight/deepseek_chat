import 'package:deepseek_chat/app.dart';
import 'package:deepseek_chat/core/configs/dependecies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: providersProduction,
      child: const App(),
    ),
  );
}