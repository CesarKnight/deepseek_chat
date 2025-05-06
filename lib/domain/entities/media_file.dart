// lib/domain/entities/media_file.dart
import 'package:flutter/foundation.dart';

enum MediaType {
  image,
  video
}

class MediaFile {
  final String id;
  final String chatId;
  final String fileName;
  final String filePath;
  final MediaType type;
  final DateTime createdAt;
  String? name;

  MediaFile({
    required this.id,
    required this.chatId,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.createdAt,
    this.name,
  });

  // Para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'fileName': fileName,
      'filePath': filePath,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'name': name,
    };
  }

  // Para crear desde SharedPreferences
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      chatId: json['chatId'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      type: json['type'].toString().contains('video')
          ? MediaType.video
          : MediaType.image,
      createdAt: DateTime.parse(json['createdAt']),
      name: json['name'],
    );
  }
}