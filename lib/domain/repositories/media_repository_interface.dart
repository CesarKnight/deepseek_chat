// lib/domain/media_repository_interface.dart
import 'package:deepseek_chat/core/utils/result.dart';
import 'package:deepseek_chat/domain/entities/media_file.dart';
import 'package:flutter/foundation.dart';

abstract class IMediaRepository {
  Future<Result<MediaFile>> saveMedia(String chatId, String filePath, MediaType type);
  Future<Result<List<MediaFile>>> getMediaForChat(String chatId, {MediaType? type});
  Future<Result<bool>> deleteMedia(String mediaId);
  Future<Result<MediaFile>> updateMediaName(String mediaId, String newName);
}