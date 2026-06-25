import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:beltech/core/widgets/sms_permission_rationale.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_filters.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';

typedef SmsPermissionRequester = Future<bool> Function();
typedef SmsQueryRunner = Future<List<SmsMessage>> Function(SmsQuery query);
typedef PlatformCheck = bool Function();

class SmsInboxEntry {
  const SmsInboxEntry({required this.body, required this.receivedAt});

  final String body;
  final DateTime? receivedAt;
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

    final messages = await _queryRunner(_query);

    return messages
        .where((message) {
          final body = message.body?.trim() ?? '';
          if (body.isEmpty) {
            return false;
          }
          if (from != null) {
            final at = message.date;
            if (at == null || at.isBefore(from)) {
              return false;
            }
          }
          final sender = (message.address ?? '').toLowerCase();
          final normalized = normalizeParserText(body);
          final lowerNormalized = normalized.toLowerCase();
          if (shouldIgnoreMpesaSms(lowerNormalized)) {
            return false;
          }
          final mpesaSender = sender.contains('mpesa');
          final mpesaBody = looksLikeMpesaMessage(lowerNormalized);
          return mpesaSender || mpesaBody;
        })
        .map(
          (message) => SmsInboxEntry(
            body: message.body!.trim(),
            receivedAt: message.date,
          ),
        )
        .toList();
  }

  static bool _defaultIsAndroid() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> _defaultPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<List<SmsMessage>> _defaultQueryRunner(SmsQuery query) {
    return query.querySms(
      kinds: const [SmsQueryKind.inbox],
      count: 1000,
      sort: true,
    );
  }
}
