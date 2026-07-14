import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:beltech/core/widgets/sms_permission_rationale.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_filters.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';

typedef SmsPermissionRequester = Future<bool> Function();
typedef SmsQueryRunner = Future<List<SmsMessage>> Function(
  SmsQuery query, {
  int start,
  int count,
});
typedef PlatformCheck = bool Function();

class SmsInboxEntry {
  const SmsInboxEntry({
    required this.body,
    required this.receivedAt,
    this.sender,
  });

  final String body;
  final DateTime? receivedAt;

  /// The SMS sender address, if available (e.g. "MPESA", "SAFARICOM", a
  /// phone number, or a shortcode).
  final String? sender;
}

class DeviceSmsDataSource {
  DeviceSmsDataSource({
    SmsQuery? query,
    SmsPermissionRequester? requestPermission,
    SmsQueryRunner? queryRunner,
    PlatformCheck? isAndroid,
  }) : _query = query ?? SmsQuery(),
       _requestPermission = requestPermission ?? _defaultPermission,
       _queryRunner = queryRunner ?? _defaultQueryRunner,
       _isAndroid = isAndroid ?? _defaultIsAndroid;

  final SmsQuery _query;
  final SmsPermissionRequester _requestPermission;
  final SmsQueryRunner _queryRunner;
  final PlatformCheck _isAndroid;

  /// Number of SMS messages to fetch per inbox query. Lower means lower peak
  /// memory and faster "first results"; higher means fewer platform round-trips.
  static const int _chunkSize = 200;

  Future<bool> get hasRequestedPermission async =>
      await Permission.sms.isGranted && _isAndroid();

  static Future<bool> requestPermissionWithRationale(
    BuildContext context,
  ) async {
    final accepted = await showSmsPermissionRationale(context);
    if (!accepted) {
      return false;
    }
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<String>> loadLikelyMpesaMessages({DateTime? from}) async {
    final entries = await loadLikelyMpesaEntries(from: from);
    return entries.map((entry) => entry.body).toList(growable: false);
  }

  Future<List<SmsInboxEntry>> loadLikelyMpesaEntries({DateTime? from}) async {
    if (!_isAndroid()) {
      return const [];
    }
    if (!await _requestPermission()) {
      return const [];
    }

    final result = <SmsInboxEntry>[];
    for (var start = 0;; start += _chunkSize) {
      final messages = await _queryRunner(
        _query,
        start: start,
        count: _chunkSize,
      );
      if (messages.isEmpty) {
        break;
      }

      DateTime? oldestInChunk;
      for (final message in messages) {
        final body = message.body?.trim() ?? '';
        if (body.isEmpty) {
          continue;
        }
        final at = message.date;
        if (from != null) {
          if (at == null || at.isBefore(from)) {
            continue;
          }
        }
        final sender = (message.address ?? '').toLowerCase();
        final normalized = normalizeParserText(body);
        final lowerNormalized = normalized.toLowerCase();
        if (shouldIgnoreMpesaSms(lowerNormalized)) {
          continue;
        }
        final mpesaSender = sender.contains('mpesa');
        final mpesaBody = looksLikeMpesaMessage(lowerNormalized);
        if (!mpesaSender && !mpesaBody) {
          continue;
        }
        result.add(
          SmsInboxEntry(
            body: message.body!.trim(),
            receivedAt: at,
            sender: message.address?.trim(),
          ),
        );
        if (at != null && (oldestInChunk == null || at.isBefore(oldestInChunk))) {
          oldestInChunk = at;
        }
      }

      // Messages are sorted newest-first. Once the oldest raw message in a
      // chunk is before the requested window, older chunks won't help either.
      if (from != null &&
          oldestInChunk != null &&
          oldestInChunk.isBefore(from)) {
        break;
      }
      if (messages.length < _chunkSize) {
        break;
      }
    }
    return result;
  }

  static bool _defaultIsAndroid() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> _defaultPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<List<SmsMessage>> _defaultQueryRunner(
    SmsQuery query, {
    int start = 0,
    int count = _chunkSize,
  }) {
    return query.querySms(
      kinds: const [SmsQueryKind.inbox],
      start: start,
      count: count,
      sort: true,
    );
  }
}
