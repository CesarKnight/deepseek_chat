// lib/data/repositories/media_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:deepseek_chat/domain/repositories/media_repository_interface.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/media_file.dart';

class MediaRepository implements IMediaRepository {
  final String _mediaKey = 'media_files';
  final Uuid _uuid = const Uuid();

  @override
  Future<Result<MediaFile>> saveMedia(String chatId, String filePath, MediaType type) async {
    try {
      // Copiar el archivo a un directorio permanente
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(filePath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = "${timestamp}_$fileName";
      final String savedPath = path.join(appDir.path, 'media', chatId, newFileName);

      // Crear directorio si no existe
      final Directory mediaDir = Directory(path.dirname(savedPath));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      // Copiar archivo
      await File(filePath).copy(savedPath);

      // Crear registro del archivo
      final MediaFile mediaFile = MediaFile(
        id: _uuid.v4(),
        chatId: chatId,
        fileName: newFileName,
        filePath: savedPath,
        type: type,
        createdAt: DateTime.now(),
        name: type == MediaType.image ? 'Foto ${timestamp.substring(timestamp.length - 4)}' : 'Video ${timestamp.substring(timestamp.length - 4)}',
      );

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final mediaListJson = prefs.getString(_mediaKey);
      List<Map<String, dynamic>> mediaList = [];

      if (mediaListJson != null) {
        mediaList = List<Map<String, dynamic>>.from(
          jsonDecode(mediaListJson) as List,
        );
      }

      mediaList.add(mediaFile.toJson());
      await prefs.setString(_mediaKey, jsonEncode(mediaList));

      return Ok(mediaFile);
    } catch (e) {
      return Error(Exception('Error al guardar el archivo multimedia: $e'));
    }
  }

  @override
  Future<Result<List<MediaFile>>> getMediaForChat(String chatId, {MediaType? type}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mediaListJson = prefs.getString(_mediaKey);

      if (mediaListJson == null) {
        return const Ok([]);
      }

      final mediaList = List<Map<String, dynamic>>.from(
        jsonDecode(mediaListJson) as List,
      );

      List<MediaFile> chatMedia = mediaList
          .where((media) => media['chatId'] == chatId)
          .map((media) => MediaFile.fromJson(media))
          .toList();

      // Filtrar por tipo si se especifica
      if (type != null) {
        chatMedia = chatMedia.where((media) => media.type == type).toList();
      }

      // Ordenar por fecha de creación (más recientes primero)
      chatMedia.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Ok(chatMedia);
    } catch (e) {
      return Error(Exception('Error al obtener archivos multimedia: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteMedia(String mediaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mediaListJson = prefs.getString(_mediaKey);

      if (mediaListJson == null) {
        return const Ok(false);
      }

      final mediaList = List<Map<String, dynamic>>.from(
        jsonDecode(mediaListJson) as List,
      );

      final mediaIndex = mediaList.indexWhere((media) => media['id'] == mediaId);

      if (mediaIndex < 0) {
        return const Ok(false);
      }

      // Eliminar archivo físico
      final mediaPath = mediaList[mediaIndex]['filePath'];
      final file = File(mediaPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Eliminar registro
      mediaList.removeAt(mediaIndex);
      await prefs.setString(_mediaKey, jsonEncode(mediaList));

      return const Ok(true);
    } catch (e) {
      return Error(Exception('Error al eliminar archivo multimedia: $e'));
    }
  }

  @override
  Future<Result<MediaFile>> updateMediaName(String mediaId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mediaListJson = prefs.getString(_mediaKey);

      if (mediaListJson == null) {
        return Error(Exception('No se encontró el archivo multimedia'));
      }

      final mediaList = List<Map<String, dynamic>>.from(
        jsonDecode(mediaListJson) as List,
      );

      final mediaIndex = mediaList.indexWhere((media) => media['id'] == mediaId);

      if (mediaIndex < 0) {
        return Error(Exception('No se encontró el archivo multimedia'));
      }

      // Actualizar nombre
      mediaList[mediaIndex]['name'] = newName;
      await prefs.setString(_mediaKey, jsonEncode(mediaList));

      // Devolver el objeto actualizado
      final updatedMedia = MediaFile.fromJson(mediaList[mediaIndex]);
      return Ok(updatedMedia);
    } catch (e) {
      return Error(Exception('Error al actualizar el nombre: $e'));
    }
  }
}