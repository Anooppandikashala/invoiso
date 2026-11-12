import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether invoice Attachments UI is shown (invoice form row, list menu item,
/// count badge). Live provider state so toggling it in Settings > Accessibility
/// applies immediately (mirrors cash_exchange_settings_provider).
final attachmentsEnabledProvider = StateProvider<bool>((ref) => false);
