import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/platform/platform_capabilities.dart';
import 'package:mavra_frontend/core/realtime/realtime_client.dart';

void main() {
  group('RealtimeClient', () {
    test('prefers SSE when the platform supports it', () {
      final transport = RealtimeClient.transportFor(
        PlatformCapabilities.forEnvironment(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
      );

      expect(transport, RealtimeTransport.serverSentEvents);
    });

    test('uses polling when capabilities request a fallback', () {
      final transport = RealtimeClient.transportFor(
        PlatformCapabilities.forEnvironment(
          isWeb: false,
          platform: TargetPlatform.windows,
          realtimeMode: RealtimeMode.polling,
        ),
      );

      expect(transport, RealtimeTransport.polling);
    });

    test('polling client emits normalized realtime messages', () async {
      final client = PollingRealtimeClient(
        poll: () async => [
          const RealtimeMessage(type: 'alert.created', payload: {'id': 42}),
        ],
      );

      final messages = await client.pollOnce();

      expect(messages, hasLength(1));
      expect(messages.single.type, 'alert.created');
      expect(messages.single.payload, {'id': 42});
    });
  });
}
