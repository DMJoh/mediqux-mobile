import 'package:mediqux_mobile/providers/storage_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_provider.g.dart';

@Riverpod(keepAlive: true)
class ServerConfig extends _$ServerConfig {
  @override
  Future<String?> build() async {
    return ref.watch(storageServiceProvider).readServerUrl();
  }

  Future<void> setUrl(String url) async {
    await ref.read(storageServiceProvider).saveServerUrl(url);
    state = AsyncValue.data(url);
  }
}
