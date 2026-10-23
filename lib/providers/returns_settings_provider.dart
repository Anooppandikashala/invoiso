import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Credit Notes / Debit Notes dashboard tabs are shown. Live
/// provider state so toggling it in Settings > Accessibility updates the
/// dashboard sidebar immediately (mirrors cash_exchange_settings_provider).
final returnsEnabledProvider = StateProvider<bool>((ref) => false);
