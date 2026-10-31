import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'backup_service.dart';

class TransferServerInfo {
  final String ip;
  final int port;
  final String token;
  final String pin;

  TransferServerInfo({
    required this.ip,
    required this.port,
    required this.token,
    required this.pin,
  });

  /// Connection string encoded in QR code: mcheques://ip:port?t=token&p=pin
  String toQrString() {
    return 'mcheques://$ip:$port?t=$token&p=$pin';
  }

  static TransferServerInfo? parseQrString(String qr) {
    try {
      final uri = Uri.parse(qr.trim());
      if (uri.scheme == 'mcheques') {
        final ip = uri.host;
        final port = uri.port;
        final token = uri.queryParameters['t'] ?? '';
        final pin = uri.queryParameters['p'] ?? '';
        if (ip.isNotEmpty && port > 0) {
          return TransferServerInfo(ip: ip, port: port, token: token, pin: pin);
        }
      }
    } catch (_) {}
    return null;
  }
}

class TransferService {
  final BackupService _backupService;
  HttpServer? _server;
  bool _isServing = false;

  TransferService({BackupService? backupService})
      : _backupService = backupService ?? BackupService();

  bool get isServing => _isServing;

  /// Find device IPv4 on local Wi-Fi or Hotspot
  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Prioritize Wi-Fi interfaces (wlan, en0, etc.)
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith(RegExp(r'^(192\.168|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))'))) {
            return addr.address;
          }
        }
      }

      // Fallback: any non-loopback
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  /// Generate a random 4-digit PIN
  static String generatePin() {
    final rnd = Random.secure();
    return (1000 + rnd.nextInt(9000)).toString();
  }

  /// Generate a random 16-character alphanumeric token
  static String generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return List.generate(16, (i) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Start direct local transfer server on Phone A
  Future<TransferServerInfo> startTransferServer({
    required String pin,
    Function(bool success)? onTransferDone,
  }) async {
    await stopServer();

    final ip = await getLocalIp();
    final token = generateToken();

    // Prepare encrypted payload
    final encryptedBytes = await _backupService.encryptPayload(pin);

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _isServing = true;
    final port = _server!.port;

    _server!.listen(
      (HttpRequest request) async {
        final requestedToken = request.uri.queryParameters['t'] ?? request.uri.queryParameters['token'];

        if (request.uri.path == '/transfer' && requestedToken == token) {
          request.response.headers.contentType = ContentType('application', 'octet-stream');
          request.response.headers.add('Access-Control-Allow-Origin', '*');
          request.response.add(encryptedBytes);
          await request.response.close();

          onTransferDone?.call(true);
        } else {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write('Accès refusé');
          await request.response.close();
        }
      },
      onError: (e) {
        _isServing = false;
      },
      onDone: () {
        _isServing = false;
      },
    );

    return TransferServerInfo(
      ip: ip,
      port: port,
      token: token,
      pin: pin,
    );
  }

  /// Stop local server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isServing = false;
  }

  /// Client: download and decrypt payload from Phone A
  Future<Map<String, dynamic>> fetchDirectTransfer({
    required String ip,
    required int port,
    required String token,
    required String pin,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri.parse('http://$ip:$port/transfer?t=$token');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw FormatException('Erreur de transfert direct (code ${response.statusCode})');
      }

      final builder = BytesBuilder();
      await for (final chunk in response) {
        builder.add(chunk);
      }

      final bytes = builder.takeBytes();
      return _backupService.decryptPayloadBytes(bytes: bytes, password: pin);
    } finally {
      client.close();
    }
  }
}
