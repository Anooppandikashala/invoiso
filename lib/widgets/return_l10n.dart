import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Shared label helpers for return management — maps the canonical (stored)
/// English reason / payment-method strings to the localized display text.

String returnReasonLabel(AppLocalizations l10n, String reason) {
  switch (reason) {
    case 'Damaged / defective':
      return l10n.returnReasonDamaged;
    case 'Wrong item delivered':
      return l10n.returnReasonWrongItem;
    case 'Not required':
      return l10n.returnReasonNotRequired;
    case 'Quality issue':
      return l10n.returnReasonQualityIssue;
    case 'Price revision':
      return l10n.returnReasonPriceRevision;
    case 'Goods returned':
      return l10n.returnReasonGoodsReturned;
    case 'Billing correction':
      return l10n.returnReasonBillingCorrection;
    case 'Goodwill / discount':
      return l10n.returnReasonGoodwill;
    default:
      return l10n.returnReasonOther;
  }
}

String creditSettlementLabel(AppLocalizations l10n, CreditSettlement s) {
  switch (s) {
    case CreditSettlement.reduceInvoice:
      return l10n.returnSettledReduceInvoice;
    case CreditSettlement.refund:
      return l10n.returnSettledRefund;
    case CreditSettlement.customerCredit:
      return l10n.returnSettledCustomerCredit;
  }
}

String refundMethodLabel(AppLocalizations l10n, String method) {
  switch (method) {
    case 'Cash':
      return l10n.paymentMethodCash;
    case 'Bank Transfer':
      return l10n.paymentMethodBankTransfer;
    case 'Check':
      return l10n.paymentMethodCheck;
    case 'Online':
      return l10n.paymentMethodOnline;
    default:
      return l10n.paymentMethodOther;
  }
}
