// lib/presentation/viewModels/media_viewmodel.dart
import 'dart:io';
import 'package:deepseek_chat/domain/repositories/media_repository_interface.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../../core/utils/command.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/media_file.dart';

class MediaViewModel extends ChangeNotifier {
  MediaViewModel({
    required IMediaRepository mediaRepository,
  }) : _mediaRepository = mediaRepository {
    saveMedia = Command2(_saveMedia);
    getMedia = Command2(_getMedia);
    deleteMedia = Command1(_deleteMedia);
    updateMediaName = Command2(_updateMediaName);
  }

  final IMediaRepository _mediaRepository;
  final ImagePicker _picker = ImagePicker();

  late final Command2<MediaFile, String, File> saveMedia;
  late final Command2<List<MediaFile>, String, MediaType?> getMedia;
  late final Command1<bool, String> deleteMedia;
  late final Command2<MediaFile, String, String> updateMediaName;

  MediaType _selectedType = MediaType.image;
  List<MediaFile> _mediaFiles = [];

  MediaType get selectedType => _selectedType;
  List<MediaFile> get mediaFiles => _mediaFiles;

  set selectedType(MediaType type) {
    _selectedType = type;
    notifyListeners();
  }

  // Capturar imagen de la cámara
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error al tomar foto: $e');
      return null;
    }
  }

  // Capturar video de la cámara
  Future<File?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Error al grabar video: $e');
      return null;
    }
  }

  // Seleccionar imagen de la galería
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      return null;
    }
  }

  // Seleccionar video de la galería
  Future<File?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar video: $e');
      return null;
    }
  }

  Future<Result<MediaFile>> _saveMedia(String chatId, File file) async {
    final String filePath = file.path;
    final bool isVideo = filePath.toLowerCase().endsWith('.mp4') ||
                         filePath.toLowerCase().endsWith('.mov') ||
                         filePath.toLowerCase().endsWith('.avi');

    final MediaType type = isVideo ? MediaType.video : MediaType.image;
    final result = await _mediaRepository.saveMedia(chatId, filePath, type);

    if (result is Ok) {
      return result;
    }

    return Error((result as Error).error);
  }

  Future<Result<List<MediaFile>>> _getMedia(String chatId, MediaType? type) async {
    final result = await _mediaRepository.getMediaForChat(chatId, type: type);

    if (result is Ok) {
      _mediaFiles = (result as Ok<List<MediaFile>>).value;
      notifyListeners();
      return result;
    }

    return Error((result as Error).error);
  }

  Future<Result<bool>> _deleteMedia(String mediaId) async {
    final result = await _mediaRepository.deleteMedia(mediaId);

    if (result is Ok && (result as Ok<bool>).value) {
      _mediaFiles.removeWhere((media) => media.id == mediaId);
      notifyListeners();
      return result;
    }

    return Error((result is Error) ? (result as Error).error : Exception('No se pudo eliminar el archivo'));
  }

  Future<Result<MediaFile>> _updateMediaName(String mediaId, String newName) async {
    final result = await _mediaRepository.updateMediaName(mediaId, newName);

    if (result is Ok) {
      final updatedMedia = (result as Ok<MediaFile>).value;
      final index = _mediaFiles.indexWhere((media) => media.id == mediaId);
      if (index >= 0) {
        _mediaFiles[index] = updatedMedia;
        notifyListeners();
      }
      return result;
    }

    return Error((result as Error).error);
  }

  @override
  void dispose() {
    saveMedia.dispose();
    getMedia.dispose();
    deleteMedia.dispose();
    updateMediaName.dispose();
    super.dispose();
  }
}