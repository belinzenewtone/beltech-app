import 'parser_fixture.dart';

/// Ported 1:1 from Kotlin BankParserFixtures.kt (Phase P0 golden corpus).
const List<BankFixture> bankFixtures = [
  // ncba
  BankFixture(
    body:
        "BELINZE, Online transaction of KES.250.00 has been approved on your card ending **8283 at GOOGLE *Google One. Forex Adjustment, KES.8.75 on 29/07/2025 16:56:01. If it's not yours, please call Loop 0730 714444/0709 714444 urgently.",
    expectedInstitution: 'ncba',
    expectedAmount: 250.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'An airtime purchase of KES.600.00 from your LOOP account has been completed on 29/07/2025 18:44PM. LOOP ref NHLEQ22R7SEB',
    expectedInstitution: 'ncba',
    expectedAmount: 600.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear BELINZE, you have received KES.25,000.00 into your account. LOOP Ref NHLEQ222C6TR. 29/07/2025 05:34:47.',
    expectedInstitution: 'ncba',
    expectedAmount: 25000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear BELINZE! You have successfully transfered KES.280.00 from 44******4117 to wallet.',
    expectedInstitution: 'ncba',
    expectedAmount: 280.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Our NCBA NOW app and USSD code *488# Mobile Banking services have been restored. Thank you for your patience.',
    expectedInstitution: 'ncba',
    shouldIgnore: true,
  ),
  BankFixture(
    body:
        'Dear Customer, in celebration of the new year holiday, our branches will remain closed on Thursday, 1st January 2026.',
    expectedInstitution: 'ncba',
    shouldIgnore: true,
  ),
  // equity
  BankFixture(
    body:
        'Your payment of 270 KES to SAMUEL MAINA 0712345678 was successful. Ref. AC8C5B6D1B147 on 11/04/2025 at 13:58. Charges 0 KES',
    expectedInstitution: 'equity',
    expectedAmount: 270.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Never share this code with anyone, including us. Use code 082017 to send 50.00 KES to 0712345678 via MPesa.',
    expectedInstitution: 'equity',
    shouldIgnore: true,
  ),
  BankFixture(
    body:
        'Your airtime purchase of 50 KES for Safaricom 0712345678 was successful. Ref. A908899BD8AB2 on 31 Mar 2025 at 19:04 EAT. Charges 0 KES',
    expectedInstitution: 'equity',
    expectedAmount: 50.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        '22000.00 KES has been successfully sent to Belinze Newtone Ojing 0712345678 INVESTMENT & MORGAGES BANK. Ref. AA0A2B6FAA8EA on 02 Apr 2025 at 09:30 EAT. Charges 59.76 KES',
    expectedInstitution: 'equity',
    expectedAmount: 22000.0,
    expectedKind: 'debit',
  ),
  // kcb
  BankFixture(
    body:
        'MBNHE7LGVNK8K5OH Completed. Your SEND TO M-PESA request of KES 409.00 from 134****073 to 254****586 - BELINZE NEWTONE OJING at 2026-03-30 02:27:07 PM has been processed successfully. Transaction cost KES 11.00',
    expectedInstitution: 'kcb',
    expectedAmount: 409.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'MBNHE7LGVNK8K5OH Confirmed! You have received KES 409.00 from BELINZE NEWTONE OJING - 134****073 at 2026-03-30 02:27:07 PM via KCB.',
    expectedInstitution: 'kcb',
    expectedAmount: 409.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Ksh 170.00 sent to KCB account METRALIFEKENYALIMITED 8034610 has been received on 30/03/2026 at 08:48 AM. M-PESA Ref UCUDLB7GY3.',
    expectedInstitution: 'kcb',
    expectedAmount: 170.0,
    expectedKind: 'credit',
  ),
  // stanchart
  BankFixture(
    body:
        'Dear Client, KES 1110.00 has been credited to your account ending with 2600 from MPESA. For any queries call +254 20 3293900',
    expectedInstitution: 'stanchart',
    expectedAmount: 1110.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Client, our Online Banking/SC Mobile app will be temporarily unavailable today 4 April 2026 from 10pm to 11pm, as part of scheduled system enhancements.',
    expectedInstitution: 'stanchart',
    shouldIgnore: true,
  ),
  BankFixture(
    body:
        'Dear Client, we will never call you and ask for your Visa debit or credit card details such as PIN, expiry details or CVV number. Do not share these with anyone.',
    expectedInstitution: 'stanchart',
    shouldIgnore: true,
  ),
  // coop
  BankFixture(
    body:
        'Dear Customer, your MCo-op Cash account has been credited with KES 3,500.00. Ref: COOP20260726. Date: 26/07/2026. New Balance: KES 9,742.00',
    expectedInstitution: 'coopbank',
    expectedAmount: 3500.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Customer, KES 1,200.00 has been debited from your MCo-op Cash account. Ref: COOP20260727. Date: 26/07/2026. New Balance: KES 8,542.00',
    expectedInstitution: 'coopbank',
    expectedAmount: 1200.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Co-operative Bank of Kenya mobile banking services will be unavailable on 28/07/2026 from 12:00 AM to 3:00 AM due to scheduled system maintenance.',
    expectedInstitution: 'coopbank',
    shouldIgnore: true,
  ),
  // absa
  BankFixture(
    body:
        'Dear Customer, KES 10,000.00 CR to your Absa Bank Kenya account ending **4321. Auth Code: ABSA20261001 on 26/07/2026 14:30.',
    expectedInstitution: 'absa',
    expectedAmount: 10000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Customer, KES 2,750.00 DR from your Absa Bank Kenya account ending **4321. Auth Code: ABSA20261002 on 26/07/2026 09:15.',
    expectedInstitution: 'absa',
    expectedAmount: 2750.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Absa Bank Kenya systems will be under scheduled maintenance on 28/07/2026 from 11 PM to 1 AM EAT. We apologise for any inconvenience.',
    expectedInstitution: 'absa',
    shouldIgnore: true,
  ),
  // dtb
  BankFixture(
    body:
        'Dear Customer, your Diamond Trust Bank account has been credited with KES 5,000.00. Trans Ref: DTBKE2026001. Date: 26/07/2026. Avail Bal: KES 12,345.00',
    expectedInstitution: 'dtb',
    expectedAmount: 5000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Customer, KES 1,500.00 has been debited from your DTB Kenya account. Trans Ref: DTBKE2026002. Date: 26/07/2026. Balance: KES 10,845.00',
    expectedInstitution: 'dtb',
    expectedAmount: 1500.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Diamond Trust Bank (DTB) internet banking will be unavailable on 29/07/2026 from 10 PM to 12 AM for system maintenance.',
    expectedInstitution: 'dtb',
    shouldIgnore: true,
  ),
  // family
  BankFixture(
    body:
        'Dear Valued Customer, KES 4,000.00 has been credited to your Family Bank account. Ref No: FAMKE20261001. Balance: KES 7,890.00',
    expectedInstitution: 'family',
    expectedAmount: 4000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Valued Customer, KES 800.00 has been debited from your Family Bank account. Ref No: FAMKE20261002. Balance: KES 7,090.00',
    expectedInstitution: 'family',
    expectedAmount: 800.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Family Bank Kenya mobile banking will be under maintenance on 29/07/2026 from 11 PM to 2 AM. We apologise for the inconvenience.',
    expectedInstitution: 'family',
    shouldIgnore: true,
  ),
  // im
  BankFixture(
    body:
        'I&M Bank: KES 7,500.00 credited to your account ending **9876. Ref: IMKE20261001. Date: 26/07/2026.',
    expectedInstitution: 'im',
    expectedAmount: 7500.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'I&M Bank: KES 3,200.00 debited from your account ending **9876. Ref: IMKE20261002. Date: 26/07/2026.',
    expectedInstitution: 'im',
    expectedAmount: 3200.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, I&M Bank systems will be temporarily unavailable on 29/07/2026 from 10 PM to 12 AM for a scheduled upgrade.',
    expectedInstitution: 'im',
    shouldIgnore: true,
  ),
  // stanbic
  BankFixture(
    body:
        'Your Stanbic Bank Kenya account ending 5432 has been credited with KES 20,000.00. Ref: SBKE20261001. Date: 26/07/2026.',
    expectedInstitution: 'stanbic',
    expectedAmount: 20000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Your Stanbic Bank Kenya account ending 5432 has been debited with KES 5,000.00. Ref: SBKE20261002. Date: 26/07/2026.',
    expectedInstitution: 'stanbic',
    expectedAmount: 5000.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Stanbic Bank Kenya internet banking will be down for scheduled maintenance on 30/07/2026 from 10 PM to 12 AM.',
    expectedInstitution: 'stanbic',
    shouldIgnore: true,
  ),
  // sbm
  BankFixture(
    body:
        'SBM Bank Kenya: KES 8,000.00 credited to your account. Txn Ref: SBMKE2026001. Date: 26/07/2026.',
    expectedInstitution: 'sbm',
    expectedAmount: 8000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'SBM Bank Kenya: KES 1,800.00 debited from your account. Txn Ref: SBMKE2026002. Date: 26/07/2026.',
    expectedInstitution: 'sbm',
    expectedAmount: 1800.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, SBM Bank Kenya online services will be down for scheduled maintenance on 30/07/2026 from 11 PM to 1 AM.',
    expectedInstitution: 'sbm',
    shouldIgnore: true,
  ),
  // hf
  BankFixture(
    body:
        'Dear Customer, KES 6,000.00 has been credited to your Housing Finance account. Ref: HFCK20261001. Balance: KES 18,500.00',
    expectedInstitution: 'hfgroup',
    expectedAmount: 6000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Customer, KES 2,500.00 has been debited from your HF Group account. Ref: HFCK20261002. Balance: KES 16,000.00',
    expectedInstitution: 'hfgroup',
    expectedAmount: 2500.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, HF Group mobile banking services will be temporarily unavailable on 30/07/2026 for system maintenance. We apologise for the inconvenience.',
    expectedInstitution: 'hfgroup',
    shouldIgnore: true,
  ),
  // gulf
  BankFixture(
    body:
        'Dear Customer, KES 12,000.00 credited to your Gulf African Bank account. Ref: GULF20261001. Date: 26/07/2026. Balance: KES 25,300.00',
    expectedInstitution: 'gulf',
    expectedAmount: 12000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Customer, KES 4,500.00 debited from your Gulf African Bank account. Ref: GULF20261002. Date: 26/07/2026. Balance: KES 20,800.00',
    expectedInstitution: 'gulf',
    expectedAmount: 4500.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Gulf African Bank mobile banking will be under maintenance on 31/07/2026 from 11 PM to 2 AM EAT.',
    expectedInstitution: 'gulf',
    shouldIgnore: true,
  ),
  // boa
  BankFixture(
    body:
        'Bank of Africa Kenya: KES 9,000.00 has been received to your account. Ref: BOAKE2026001. Date: 26/07/2026.',
    expectedInstitution: 'boa',
    expectedAmount: 9000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Bank of Africa Kenya: KES 3,000.00 has been sent from your account. Ref: BOAKE2026002. Date: 26/07/2026.',
    expectedInstitution: 'boa',
    expectedAmount: 3000.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, Bank of Africa (BOA Kenya) mobile banking services will be unavailable on 31/07/2026 from 11 PM to 1 AM for planned maintenance.',
    expectedInstitution: 'boa',
    shouldIgnore: true,
  ),
  // pesalink
  BankFixture(
    body:
        'Dear Customer, KES 15,000.00 has been received to your account via PesaLink. Ref: IPSL20261001. Date: 26/07/2026.',
    expectedInstitution: 'pesalink',
    expectedAmount: 15000.0,
    expectedKind: 'credit',
  ),
  BankFixture(
    body:
        'Dear Customer, KES 6,000.00 has been sent from your account via PesaLink. Ref: IPSL20261002. Date: 26/07/2026.',
    expectedInstitution: 'pesalink',
    expectedAmount: 6000.0,
    expectedKind: 'debit',
  ),
  BankFixture(
    body:
        'Dear Customer, PesaLink (Integrated Payment Services) will be unavailable on 01/08/2026 from 12 AM to 2 AM for scheduled maintenance.',
    expectedInstitution: 'pesalink',
    shouldIgnore: true,
  ),
];
