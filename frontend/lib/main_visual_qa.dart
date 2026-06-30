import 'app/bootstrap.dart';
import 'visual_qa/visual_qa_app.dart';

Future<void> main() async {
  await bootstrap(
    buildVisualQaApp(),
    apiBaseUrl: 'https://visual-qa.local/api/v1',
  );
}
