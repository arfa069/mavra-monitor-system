import 'app/bootstrap.dart';
import 'app/mavra_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  await bootstrap(const ProviderScope(child: MavraApp()));
}
