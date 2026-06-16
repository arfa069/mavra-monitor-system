import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/platform_capabilities.dart';
import '../domain/auth_models.dart';

class WeChatCallbackPage extends StatefulWidget {
  const WeChatCallbackPage({
    super.key,
    required this.authController,
    required this.queryParameters,
    PlatformCapabilities? capabilities,
  }) : capabilities =
           capabilities ??
           const PlatformCapabilities(
             isWeb: true,
             isDesktop: false,
             isMobile: false,
             canPickFiles: true,
             canDownloadFiles: true,
             supportsSaveDialog: false,
             secureStorageMode: SecureStorageMode.webCookie,
             callbackMode: CallbackMode.browserUrl,
             realtimeMode: RealtimeMode.serverSentEvents,
           );

  final AuthController authController;
  final Map<String, String> queryParameters;
  final PlatformCapabilities capabilities;

  @override
  State<WeChatCallbackPage> createState() => _WeChatCallbackPageState();
}

class _WeChatCallbackPageState extends State<WeChatCallbackPage> {
  Future<WeChatExchangeResult?>? _exchange;

  @override
  void initState() {
    super.initState();
    final code =
        widget.queryParameters['exchange_code'] ??
        widget.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      _exchange = widget.authController.exchangeWeChatCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WeChat Callback')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<WeChatExchangeResult?>(
            future: _exchange,
            builder: (context, snapshot) {
              if (_exchange == null) {
                return _CallbackMessage(
                  icon: Icons.qr_code_2,
                  title: 'Waiting for WeChat',
                  message:
                      'Callback mode: ${widget.capabilities.callbackMode.name}',
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return _CallbackMessage(
                  icon: Icons.error_outline,
                  title: 'WeChat exchange failed',
                  message: snapshot.error.toString(),
                );
              }
              final result = snapshot.requireData;
              if (result == null) {
                return const _CallbackMessage(
                  icon: Icons.info_outline,
                  title: 'No exchange result',
                  message: 'Try signing in with WeChat again.',
                );
              }
              if (result.isBound) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.go(result.nextPath ?? '/today');
                  }
                });
                return const _CallbackMessage(
                  icon: Icons.check_circle_outline,
                  title: 'WeChat login complete',
                  message: 'Opening Today.',
                );
              }
              if (result.isUnbound) {
                return _CallbackMessage(
                  icon: Icons.link,
                  title: 'WeChat account is unbound',
                  message: 'Temporary token: ${result.tempToken}',
                );
              }
              return _CallbackMessage(
                icon: Icons.info_outline,
                title: 'WeChat status: ${result.status}',
                message: 'Continue from login.',
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CallbackMessage extends StatelessWidget {
  const _CallbackMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
