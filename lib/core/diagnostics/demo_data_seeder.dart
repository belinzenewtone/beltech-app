import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter/foundation.dart';

/// Debug-only demo seeder (Phase demo).
///
/// When built with `--dart-define=SEED_DEMO=true`, this runs once at startup
/// and inserts a set of realistic M-PESA transactions into the app's real
/// on-disk SQLite database so analytics / graphs populate in the emulator
/// without needing a real SMS inbox.
///
/// It is a no-op unless the define is present AND we are in debug mode.
/// Existing rows are preserved: inserts are keyed on source_hash and use
/// INSERT OR IGNORE, so re-running does not duplicate data.
class DemoDataSeeder {
  /// M-PESA demo corpus — a spread of received/sent/paybill/buy-goods/
  /// airtime/withdraw/deposit/fuliza transactions across recent months.
  static const List<String> _demoSms = [
    // ── Received ────────────────────────────────────────────────────────────────
    'SIE8QWE123 Confirmed. You have received Ksh390.00 from JOHN DOE 0712345678 on 16/3/26 at 11:20 AM. New M-PESA balance is Ksh1,200.00.',
    'AB12345678 Confirmed. Ksh5,000.00 received from MARY WANJIRU 0722111222 on 16/3/26 at 9:00 AM. New M-PESA balance is Ksh6,200.00.',
    'CD98765432 Confirmed. You have received Ksh85,000.00 from EMPLOYER COMPANY LTD on 28/2/26 at 8:00 AM. New M-PESA balance is Ksh90,500.00.',
    'XAB1C2D3E4 Confirmed.You have received Ksh250.00 from Wanjiku Mwangi 0712345678 on 12/4/26 at 8:45 AM.New M-PESA balance is Ksh4,250.00.',
    'YBC2D3E4F5 Confirmed. Ksh1,200.00 received from JAMES OTIENO 0723456789 on 13/4/26 at 10:15 AM. New M-PESA balance is Ksh6,700.00.',
    'ZCD3E4F5G6 Confirmed. You have received Ksh78,500.00 from ACME LIMITED on 14/4/26 at 9:00 AM. New M-PESA balance is Ksh80,000.00.',
    'TGH6H7I8J9 Confirmed. You have received Ksh1,000.00 from SAFARICOM BONUS 0720000000 on 17/4/26 at 3:00 PM. New M-PESA balance is Ksh1,000.00.',
    // ── Sent ────────────────────────────────────────────────────────────────────
    'SIE8QWE124 Confirmed. Ksh390.00 sent to JANE DOE 0712345678 on 16/3/26 at 11:22 AM. New M-PESA balance is Ksh810.00.',
    'BPP3O4P5Q6 Confirmed. Ksh1,500.00 sent to JOHN KAMAU 0711234567 on 12/4/26 at 8:00 AM. New M-PESA balance is Ksh3,500.00.',
    'CQQ4P5Q6R7 Confirmed. Customer transfer of Ksh4,000.00 to ESTHER WANJIKU 0722345678 on 13/4/26 at 11:10 AM. New M-PESA balance is Ksh6,000.00.',
    'DRR5Q6R7S8 Confirmed. Ksh750.00 sent to MUM 0733456789 on 14/4/26 at 1:25 PM. New M-PESA balance is Ksh1,250.00.',
    'ESS6R7S8T9 Confirmed. Ksh10,000.00 sent to LANDLORD 0744567890 on 15/4/26 at 4:00 PM. New M-PESA balance is Ksh2,000.00.',
    'FTT7S8T9U0 Confirmed. Ksh199.00 sent to MBUSHI 0755678901 on 16/4/26 at 6:30 PM. New M-PESA balance is Ksh801.00.',
    // ── Paybill ─────────────────────────────────────────────────────────────────
    'SIE8QWE125 Confirmed. Ksh1,250.00 sent to KPLC PREPAID for account 998877 on 16/3/26 at 11:23 AM. New M-PESA balance is Ksh2,100.00.',
    'MAA4Z5A6B7 Confirmed. Ksh2,500.00 sent to KPLC PREPAID for account 1234567890 on 12/4/26 at 9:00 AM. New M-PESA balance is Ksh1,500.00.',
    'NBB5A6B7C8 Confirmed. Ksh1,800.00 paid to NAIROBI WATER for account 987654 on 13/4/26 at 10:30 AM. New M-PESA balance is Ksh2,200.00.',
    'OCC6B7C8D9 Confirmed. Ksh999.00 paybill payment to DSTV on 14/4/26 at 11:45 AM. New M-PESA balance is Ksh4,001.00.',
    'PDD7C8D9E0 Confirmed. Ksh3,500.00 sent to ZUKU for account 112233 on 15/4/26 at 1:00 PM. New M-PESA balance is Ksh6,500.00.',
    'SGG0F1G2H3 Confirmed. Ksh4,000.00 sent to KRA for account A001234567 on 18/4/26 at 4:45 PM. New M-PESA balance is Ksh5,000.00.',
    // ── Buy goods ───────────────────────────────────────────────────────────────
    'SIE8QWE126 Confirmed. Ksh450.00 paid to NAIVAS WESTLANDS on 16/3/26 at 11:25 AM. New M-PESA balance is Ksh1,650.00.',
    'WKK4J5K6L7 Confirmed. Ksh1,200.00 paid to CARREFOUR on 12/4/26 at 9:15 AM. New M-PESA balance is Ksh3,800.00.',
    'YMM6L7M8N9 Confirmed. Ksh890.00 paid to MATTRESS RESTAURANT via till number 98765 on 14/4/26 at 12:00 PM. New M-PESA balance is Ksh4,110.00.',
    'ZNN7M8N9O0 Confirmed. Ksh2,300.00 paid to TOTAL ENERGY on 15/4/26 at 1:30 PM. New M-PESA balance is Ksh5,700.00.',
    'CQQ0P1Q2R3 Confirmed. Ksh675.00 paid to PHARMACY PLUS on 18/4/26 at 5:15 PM. New M-PESA balance is Ksh2,325.00.',
    'DRR1Q2R3S4 Confirmed. Ksh3,000.00 paid to BATA KENYA on 19/4/26 at 6:30 PM. New M-PESA balance is Ksh4,000.00.',
    'ESS2R3S4T5 Confirmed. Ksh1,050.00 paid to JAVA HOUSE on 20/4/26 at 7:45 PM. New M-PESA balance is Ksh1,950.00.',
    // ── Airtime ─────────────────────────────────────────────────────────────────
    'VW33221100 Confirmed. Ksh50.00 sent to 0712345678 for airtime on 16/3/26 at 8:00 AM. New M-PESA balance is Ksh950.00.',
    'GUU4T5U6V7 Confirmed. Ksh20.00 sent to 0712345678 for airtime on 12/4/26 at 8:30 AM. New M-PESA balance is Ksh480.00.',
    'HVV5U6V7W8 Confirmed. Ksh500.00 airtime purchase for 0723456789 on 13/4/26 at 9:45 AM. New M-PESA balance is Ksh3,500.00.',
    // ── Withdraw ────────────────────────────────────────────────────────────────
    'ZA22110099 Confirmed. Ksh2,000.00 withdrawn from agent 1234 - JOHN AGENT on 15/3/26 at 2:00 PM. New M-PESA balance is Ksh8,000.00.',
    'QEE4D5E6F7 Confirmed. Ksh5,000.00 withdrawn from agent 9876 - AGENT ONE on 12/4/26 at 9:30 AM. New M-PESA balance is Ksh1,000.00.',
    'SGG6F7G8H9 Confirmed. Ksh1,000.00 withdrawn from agent 1111 - MWANGI AGENT on 14/4/26 at 12:00 PM. New M-PESA balance is Ksh2,500.00.',
    'UII8H9I0J1 Confirmed. Ksh7,500.00 withdrawn from agent 3333 - TRUSTED AGENT on 16/4/26 at 2:30 PM. New M-PESA balance is Ksh8,500.00.',
    // ── Deposit ─────────────────────────────────────────────────────────────────
    'DE66554400 Confirmed. Ksh3,000.00 deposited by agent FAITH AGENT 7890 on 14/3/26 at 11:00 AM. New M-PESA balance is Ksh3,500.00.',
    'ZNN3M4N5O6 Confirmed. Ksh2,000.00 deposited by agent WANJIKU AGENT 8888 on 12/4/26 at 9:45 AM. New M-PESA balance is Ksh5,500.00.',
    'CQQ6P7Q8R9 Confirmed. Cash deposit of Ksh25,000.00 on 15/4/26 at 1:30 PM. New M-PESA balance is Ksh30,000.00.',
    // ── Fuliza charge (updates outstanding — no ledger row) ─────────────────────
    'UCIDL9W36G Confirmed. Fuliza M-PESA amount is Ksh 60.00. Access Fee charged Ksh 0.60. Total Fuliza M-PESA outstanding amount is Ksh239.23 due on 15/04/26.',

    // ── Recent (July–Aug 2026) so Today/Week/Month cards populate ───────────────
    'RD1A2B3C4D Confirmed. You have received Ksh45,000.00 from EMPLOYER COMPANY LTD on 1/8/26 at 8:00 AM. New M-PESA balance is Ksh96,500.00.',
    'RD2B3C4D5E Confirmed. Ksh2,400.00 paid to CARREFOUR on 2/8/26 at 11:00 AM. New M-PESA balance is Ksh94,100.00.',
    'RD3C4D5E6F Confirmed. Ksh1,150.00 paid to JAVA HOUSE on 3/8/26 at 2:00 PM. New M-PESA balance is Ksh92,950.00.',
    'RD4D5E6F7G Confirmed. Ksh6,000.00 sent to LANDLORD 0744567890 on 3/8/26 at 4:00 PM. New M-PESA balance is Ksh86,950.00.',
    'RD5E6F7G8H Confirmed. Ksh2,500.00 sent to KPLC PREPAID for account 1234567890 on 4/8/26 at 9:00 AM. New M-PESA balance is Ksh84,450.00.',
    'RD6F7G8H9I Confirmed. Ksh850.00 paid to NAIVAS WESTLANDS on 4/8/26 at 6:00 PM. New M-PESA balance is Ksh83,600.00.',
    'RD7G8H9I0J Confirmed. Ksh200.00 sent to 0712345678 for airtime on 5/8/26 at 8:00 AM. New M-PESA balance is Ksh83,400.00.',
    'RD8H9I0J1K Confirmed. Ksh3,200.00 paid to TOTAL ENERGY on 5/8/26 at 10:00 AM. New M-PESA balance is Ksh80,200.00.',
    'RD9I0J1K2L Confirmed. Ksh5,000.00 received from JAMES OTIENO 0723456789 on 5/8/26 at 1:00 PM. New M-PESA balance is Ksh85,200.00.',
    // July 2026 — fills the 6-month trend (Feb, Mar, Apr, May, Jun, Jul, Aug)
    'RJ1K2L3M4N Confirmed. Ksh7,500.00 withdrawn from agent 3333 - TRUSTED AGENT on 20/7/26 at 2:30 PM. New M-PESA balance is Ksh51,500.00.',
    'RJ2L3M4N5O Confirmed. Ksh1,800.00 paid to NAIROBI WATER for account 987654 on 22/7/26 at 10:30 AM. New M-PESA balance is Ksh49,700.00.',
    'RJ3M4N5O6P Confirmed. Ksh900.00 paid to PHARMACY PLUS on 24/7/26 at 5:15 PM. New M-PESA balance is Ksh48,800.00.',
    'RJ4N5O6P7Q Confirmed. Ksh35,000.00 received from ACME LIMITED on 25/7/26 at 9:00 AM. New M-PESA balance is Ksh83,800.00.',
    'RJ5O6P7Q8R Confirmed. Ksh1,050.00 paid to MATTRESS RESTAURANT on 27/7/26 at 12:00 PM. New M-PESA balance is Ksh82,750.00.',
    'RJ6P7Q8R9S Confirmed. Ksh500.00 airtime purchase for 0723456789 on 28/7/26 at 9:45 AM. New M-PESA balance is Ksh82,250.00.',
    'RJ7Q8R9S0T Confirmed. Ksh4,000.00 sent to KRA for account A001234567 on 29/7/26 at 4:45 PM. New M-PESA balance is Ksh78,250.00.',
    // June 2026 — mid-range spend month
    'RK1R9S0T1U Confirmed. Ksh12,000.00 sent to LANDLORD 0744567890 on 15/6/26 at 4:00 PM. New M-PESA balance is Ksh43,250.00.',
    'RK2S0T1U2V Confirmed. Ksh2,200.00 paid to BATA KENYA on 18/6/26 at 6:30 PM. New M-PESA balance is Ksh41,050.00.',
    'RK3T1U2V3W Confirmed. Ksh65,000.00 received from EMPLOYER COMPANY LTD on 1/6/26 at 8:00 AM. New M-PESA balance is Ksh106,050.00.',
  ];

  static const bool _enabled = bool.fromEnvironment('SEED_DEMO');

  static Future<void> runIfEnabled() async {
    if (!kDebugMode || !_enabled) {
      return;
    }
    await seedNow();
  }

  /// Runs the seed immediately. No-op outside debug builds. Safe to call
  /// repeatedly — inserts are keyed on source_hash (INSERT OR IGNORE), so
  /// existing rows are never duplicated.
  static Future<void> seedNow() async {
    if (!kDebugMode) {
      return;
    }
    try {
      const parser = MpesaParserService();
      final store = AppDriftStore.persistent();
      await store.ensureInitialized();

      var seeded = 0;
      var skipped = 0;
      for (final body in _demoSms) {
        final candidate = parser.parseSingleDetailed(body);
        if (candidate == null ||
            candidate.route != MpesaParseRoute.directLedger) {
          skipped += 1;
          continue;
        }
        await store.addTransaction(
          title: candidate.title,
          category: candidate.category,
          amountKes: candidate.amountKes,
          occurredAt: candidate.occurredAt,
          source: 'sms',
          sourceHash: candidate.sourceHash,
          transactionType: candidate.transactionType.name,
          balanceAfterKes: candidate.balanceAfterKes,
          feeKes: candidate.feeKes,
          rawSms: candidate.rawMessage,
          mpesaCode: candidate.mpesaCode,
        );
        final isIncome =
            candidate.transactionType == MpesaTransactionType.received ||
            candidate.transactionType == MpesaTransactionType.deposit;
        if (isIncome && candidate.amountKes > 0) {
          await store.insertIncomeBatch([
            [
              candidate.title,
              candidate.amountKes,
              candidate.occurredAt.millisecondsSinceEpoch,
              'sms',
              candidate.sourceHash,
            ],
          ]);
        }
        seeded += 1;
      }

      await store.dispose();
      debugPrint(
        'DemoDataSeeder: seeded $seeded demo transactions '
        '(skipped $skipped error/ignored).',
      );
    } catch (error, stackTrace) {
      debugPrint('DemoDataSeeder: failed — $error');
      debugPrint('$stackTrace');
    }
  }
}
