import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

@riverpod
class SessionVersion extends _$SessionVersion {
  @override
  int build() => 0;

  void increment() => state++;
}
