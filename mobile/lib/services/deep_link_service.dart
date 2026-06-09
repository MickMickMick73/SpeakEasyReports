import 'dart:async';

import 'package:app_links/app_links.dart';

import '../app_state.dart';

class DeepLinkService {
  DeepLinkService(this.state);

  final AppState state;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> listen() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) await _handle(initial);

    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handle(uri);
    }, onError: (_) {});
  }

  Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'speakeasy') return;
    if (uri.host != 'connect' && uri.path != '/connect') return;

    final url = uri.queryParameters['url']?.trim();
    if (url == null || url.isEmpty) return;

    state.settings.apiBaseUrl = url;
    await state.saveSettings();
    state.markPcConnectedFromQr(url);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}