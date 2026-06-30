import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediqux_mobile/services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);
