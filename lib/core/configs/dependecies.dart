import 'package:deepseek_chat/core/constants/api_constants.dart';
import 'package:deepseek_chat/data/repositories/chat_repository.dart';
import 'package:deepseek_chat/data/repositories/media_repositorie.dart';
import 'package:deepseek_chat/data/services/api_client.dart';
import 'package:deepseek_chat/data/services/api_service.dart';
import 'package:deepseek_chat/domain/chat_repository_interface.dart';
import 'package:deepseek_chat/domain/repositories/media_repository_interface.dart';
import 'package:deepseek_chat/presentation/viewModels/chat_list_viewmodel.dart';
import 'package:deepseek_chat/presentation/viewModels/chat_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Shared providers for all configurations.
List<SingleChildWidget> _sharedProviders = [
  // Cambia Provider por ChangeNotifierProvider
  ChangeNotifierProvider<ChatViewModel>(
    lazy: true,
    create:
        (context) =>
            ChatViewModel(chatRepository: context.read<IChatRepository>()),
  ),
  ChangeNotifierProvider<ChatListViewModel>(
    lazy: true,
    create:
        (context) =>
            ChatListViewModel(chatRepository: context.read<IChatRepository>()),
  ),
  Provider<IMediaRepository>(create: (context) => MediaRepository()),
];

/// Configure dependencies for development.
List<SingleChildWidget> get providersDevelopment {
  return [
    Provider(
      create:
          (context) => ApiClient(
            baseUrl: ApiConstants.API_URL,
            model: ApiConstants.OPENROUTER_MODEL,
            apiKey: ApiConstants.OPENROUTER_API_KEY,
          ),
    ),
    Provider(create: (context) => ApiService(apiClient: context.read())),
    Provider<IChatRepository>(
      create: (context) => ChatRepository(context.read()),
    ),
    ..._sharedProviders,
  ];
}

/// Configure dependencies for production.
List<SingleChildWidget> get providersProduction {
  return [
    Provider(
      create:
          (context) => ApiClient(
            baseUrl: ApiConstants.API_URL,
            model: ApiConstants.OPENROUTER_MODEL,
            apiKey: ApiConstants.OPENROUTER_API_KEY,
          ),
    ),
    Provider(create: (context) => ApiService(apiClient: context.read())),
    Provider<IChatRepository>(
      create: (context) => ChatRepository(context.read()),
    ),
    ..._sharedProviders,
  ];
}
