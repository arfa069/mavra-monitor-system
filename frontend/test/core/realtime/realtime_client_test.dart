import 'package:flutter/foundation.dart';
import 'dart:async';

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

    test(
      'polling client keeps polling until the subscription is cancelled',
      () async {
        var calls = 0;
        final client = PollingRealtimeClient(
          interval: const Duration(milliseconds: 1),
          poll: () async {
            calls += 1;
            return [
              RealtimeMessage(type: 'tick', payload: {'call': calls}),
            ];
          },
        );

        final messages = <RealtimeMessage>[];
        late final StreamSubscription<RealtimeMessage> subscription;
        subscription = client.connect('events').listen((message) {
          messages.add(message);
          if (messages.length == 2) {
            subscription.cancel();
          }
        });

        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(messages, hasLength(2));
        expect(messages.map((message) => message.payload['call']), [1, 2]);
      },
    );
  });
}
