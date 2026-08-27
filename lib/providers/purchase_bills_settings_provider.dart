import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Purchase Bills / Suppliers dashboard tabs are shown. Off by
/// default — opt-in via onboarding or Settings > Suppliers. Kept as live
/// provider state (mirrors `localeProvider`) so toggling it from Settings
/// updates the dashboard sidebar immediately, without needing to reopen it.
final enablePurchaseBillsAndSuppliersProvider = StateProvider<bool>((ref) => false);
