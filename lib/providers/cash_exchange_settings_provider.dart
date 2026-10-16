import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Services (Cash/UPI exchange) dashboard tab is shown. Live
/// provider state so toggling it in Settings > Accessibility updates the
/// dashboard sidebar immediately (mirrors purchase_bills_settings_provider).
final cashUpiExchangeEnabledProvider = StateProvider<bool>((ref) => false);
