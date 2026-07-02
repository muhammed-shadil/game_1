import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/game_app.dart';
import 'core/services/storage_service.dart';
import 'features/progress/application/progress_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The game is designed for landscape; lock it so the physics playfield keeps
  // a consistent aspect ratio across devices.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Bootstrap persistence before the first frame so progress is available
  // synchronously to the UI (avoids a loading flash on the menu).
  final storage = await StorageService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const GameApp(),
    ),
  );
}
