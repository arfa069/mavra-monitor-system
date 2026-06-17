import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mavra_app.dart';

void bootstrap() {
  bootstrapWidget(const ProviderScope(child: MavraApp()));
}

void bootstrapWidget(Widget app) {
  runApp(app);
}
