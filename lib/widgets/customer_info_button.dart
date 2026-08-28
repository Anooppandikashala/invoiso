import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/customer.dart';

/// Tapping the ⓘ icon shows a clean dialog with the customer's full contact details.
class CustomerInfoButton extends StatelessWidget {
  final Customer customer;

  const CustomerInfoButton({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.customerInfoButtonTooltip,
      child: InkWell(
        onTap: () => _showDialog(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Icon(Icons.info_outline, size: 15, color: Colors.indigo[400]),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = customer;
    final hasAny = c.phone.isNotEmpty ||
        c.email.isNotEmpty ||
        c.address.isNotEmpty ||
        c.gstin.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Contact details body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasAny)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.customerInfoButtonNoContactMessage,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13),
                        ),
                      ),
                    if (c.phone.isNotEmpty)
                      _infoRow(context, Icons.phone_outlined,
                          l10n.fieldPhoneLabel, c.phone, Colors.green),
                    if (c.email.isNotEmpty)
                      _infoRow(context, Icons.email_outlined,
                          l10n.fieldEmailLabel, c.email, Colors.blue),
                    if (c.address.isNotEmpty)
                      _infoRow(context, Icons.location_on_outlined,
                          l10n.fieldAddressLabel, c.address, Colors.orange),
                    if (c.gstin.isNotEmpty)
                      _infoRow(context, Icons.badge_outlined,
                          l10n.fieldGstinLabel, c.gstin, Colors.purple),
                  ],
                ),
              ),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 16, 12),
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.actionClose),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
