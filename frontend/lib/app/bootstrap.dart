import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mavra_app.dart';

void bootstrap() {
  runApp(const ProviderScope(child: MavraApp()));
}
