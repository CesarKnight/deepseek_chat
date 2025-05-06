// lib/presentation/views/chat_files_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/media_file.dart';
import '../viewModels/chat_viewmodel.dart';
import '../viewModels/media_viewmodel.dart';
import '../../routing/routes.dart';

class ChatFilesScreen extends StatefulWidget {
  final String chatId;
  final String? chatTitle;

  const ChatFilesScreen({
    Key? key,
    required this.chatId,
    this.chatTitle,
  }) : super(key: key);

  @override
  State<ChatFilesScreen> createState() => _ChatFilesScreenState();
}

class _ChatFilesScreenState extends State<ChatFilesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);

    // Cargar todos los archivos
    await context.read<MediaViewModel>().getMedia.execute(widget.chatId, null);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archivos${widget.chatTitle != null ? ' - ${widget.chatTitle}' : ''}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Fotos'),
            Tab(text: 'Videos'),
          ],
          onTap: (index) {
            // Cambiar el filtro cuando se selecciona una pestaña
            final mediaViewModel = context.read<MediaViewModel>();
            if (index == 0) {
              mediaViewModel.getMedia.execute(widget.chatId, null);
            } else if (index == 1) {
              mediaViewModel.getMedia.execute(widget.chatId, MediaType.image);
            } else {
              mediaViewModel.getMedia.execute(widget.chatId, MediaType.video);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MediaViewModel>(
              builder: (context, mediaViewModel, child) {
                if (mediaViewModel.mediaFiles.isEmpty) {
                  return const Center(
                    child: Text('No hay archivos multimedia en este chat'),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Todos los archivos
                    _buildMediaGrid(mediaViewModel.mediaFiles),
                    // Solo fotos
                    _buildMediaGrid(mediaViewModel.mediaFiles.where((m) => m.type == MediaType.image).toList()),
                    // Solo videos
                    _buildMediaGrid(mediaViewModel.mediaFiles.where((m) => m.type == MediaType.video).toList()),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildMediaGrid(List<MediaFile> files) {
    return files.isEmpty
        ? const Center(child: Text('No hay archivos en esta categoría'))
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final media = files[index];
              return GestureDetector(
                onTap: () => _showMediaDetails(media),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Contenido del archivo (imagen o video)
                      media.type == MediaType.image
                          ? Image.file(
                              File(media.filePath),
                              fit: BoxFit.cover,
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/video_placeholder.png',
                                  fit: BoxFit.cover,
                                ),
                                const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ],
                            ),

                      // Información en la parte inferior
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black.withOpacity(0.6),
                          child: Text(
                            media.name ?? 'Sin nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  void _showMediaDetails(MediaFile media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Barra superior
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          media.type == MediaType.image ? 'Foto' : 'Video',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showMediaOptions(media),
                        ),
                      ],
                    ),
                  ),

                  // Contenido principal
                  Expanded(
                    child: media.type == MediaType.image
                        ? _buildImageViewer(media)
                        : _buildVideoPlayer(media),
                  ),

                  // Información en la parte inferior
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                media.name ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showRenameDialog(media),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fecha: ${_formatDate(media.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageViewer(MediaFile media) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          File(media.filePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(MediaFile media) {
    return _VideoPlayerWidget(videoPath: media.filePath);
  }

  void _showMediaOptions(MediaFile media) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Renombrar'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(media);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMedia(media);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(MediaFile media) {
    final TextEditingController nameController = TextEditingController(text: media.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Renombrar archivo'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await context.read<MediaViewModel>().updateMediaName.execute(
                    media.id,
                    newName,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedia(MediaFile media) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar archivo'),
          content: const Text('¿Estás seguro de que deseas eliminar este archivo? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await context.read<MediaViewModel>().deleteMedia.execute(media.id);
                if (context.mounted) {
                  Navigator.pop(context); // Cerrar el diálogo
                  Navigator.pop(context); // Cerrar la vista de detalles
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Widget para reproducir videos
class _VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerWidget({Key? key, required this.videoPath}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}