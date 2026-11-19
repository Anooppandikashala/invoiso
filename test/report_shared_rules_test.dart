import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/domain/customer_identity.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/domain/payment_receipt_numbers.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/utils/app_date.dart';
import 'package:invoiso/utils/formatters.dart';

void main() {
  group('InvoiceTotalsCalculator', () {
    test('calculates line totals with flat and per-unit discounts', () {
      final flat = InvoiceTotalsCalculator.line(
        price: 100,
        quantity: 2,
        discount: 15,
        discountPerUnit: false,
        extraCost: 5,
        taxRatePercent: 10,
      );
      expect(flat.grossTotal, 205);
      expect(flat.discountTotal, 15);
      expect(flat.lineTotal, 190);
      expect(flat.itemTax, 19);

      final perUnit = InvoiceTotalsCalculator.line(
        price: 100,
        quantity: 2,
        discount: 15,
        discountPerUnit: true,
        extraCost: 5,
      );
      expect(perUnit.discountTotal, 30);
      expect(perUnit.lineTotal, 175);
    });

    test('percent discount applies to price x qty, ignores per-unit flag', () {
      for (final perUnitFlag in [true, false]) {
        final pct = InvoiceTotalsCalculator.line(
          price: 100,
          quantity: 3,
          discount: 10,
          discountPerUnit: perUnitFlag,
          discountIsPercent: true,
          extraCost: 5,
          taxRatePercent: 10,
        );
        expect(pct.discountTotal, 30);
        expect(pct.grossTotal, 305);
        expect(pct.lineTotal, 275);
        expect(pct.itemTax, closeTo(27.5, 1e-9));
      }

      final inclusive = InvoiceTotalsCalculator.line(
        price: 110,
        quantity: 2,
        discount: 50,
        discountPerUnit: false,
        discountIsPercent: true,
        taxRatePercent: 10,
        priceIncludesTax: true,
      );
      expect(inclusive.discountTotal, 110);
      expect(inclusive.displayTotal, 110);
      expect(inclusive.lineTotal, closeTo(100, 1e-9));

      final fromRow = InvoiceTotalsCalculator.lineFromDbRow({
        'unit_price': null,
        'product_price': 200,
        'quantity': 1,
        'discount': 25,
        'discount_per_unit': 1,
        'discount_is_percent': 1,
      });
      expect(fromRow.discountTotal, 50);
      expect(fromRow.lineTotal, 150);
    });

    test('keeps fraction and percent global tax rates explicit', () {
      final line = InvoiceTotalsCalculator.line(
        price: 100,
        quantity: 2,
        discount: 0,
        discountPerUnit: false,
      );

      final uiTotals = InvoiceTotalsCalculator.totals(
        lines: [line],
        taxMode: TaxMode.global,
        globalTaxRate: 0.18,
        globalTaxRateFormat: TaxRateFormat.fraction,
      );
      final dbTotals = InvoiceTotalsCalculator.totals(
        lines: [line],
        taxMode: TaxMode.global,
        globalTaxRate: 18,
        globalTaxRateFormat: TaxRateFormat.percent,
      );

      expect(uiTotals.tax, 36);
      expect(dbTotals.tax, 36);
    });

    group('additional charges', () {
      final line = InvoiceTotalsCalculator.line(
          price: 100, quantity: 10, discount: 0, discountPerUnit: false,
          taxRatePercent: 12);
      InvoiceTotals totals(TaxMode mode, List<AdditionalCost> costs) =>
          InvoiceTotalsCalculator.totals(
            lines: [line],
            taxMode: mode,
            globalTaxRate: 0.18,
            additionalCosts: costs,
          );

      test('old JSON (no taxable key) stays untaxed, after tax', () {
        final costs = AdditionalCost.listFromJson(
            '[{"label":"Freight","amount":100}]');
        final t = totals(TaxMode.global, costs);
        expect(t.tax, closeTo(180, 1e-9));
        expect(t.total, closeTo(1280, 1e-9)); // 1000 + 180 + 100
        expect(t.taxableChargesTotal, 0);
        expect(AdditionalCost.listToJson(costs),
            '[{"label":"Freight","amount":100.0}]');
      });

      test('global mode taxes a taxable charge at the invoice rate', () {
        final t = totals(TaxMode.global, [
          const AdditionalCost(
              label: 'Freight', amount: 100, taxable: true, taxRate: 5),
        ]);
        expect(t.chargesTax, closeTo(18, 1e-9)); // invoice 18 %, not 5 %
        expect(t.tax, closeTo(198, 1e-9));
        expect(t.taxableChargesTotal, 100);
        expect(t.total, closeTo(1298, 1e-9));
      });

      test('per-item mode uses the charge rate; untaxed charge stays outside',
          () {
        final t = totals(TaxMode.perItem, [
          const AdditionalCost(
              label: 'Freight', amount: 100, taxable: true, taxRate: 18),
          const AdditionalCost(label: 'Courier (actual)', amount: 50),
          const AdditionalCost(
              label: 'Less', amount: -20, taxable: true, taxRate: 12),
        ]);
        // items 1000 @12 % = 120; freight 18; negative charge −2.4
        expect(t.tax, closeTo(135.6, 1e-9));
        expect(t.taxableChargesTotal, 80);
        expect(t.additionalCostsTotal, 130);
        expect(t.total, closeTo(1265.6, 1e-9)); // 1000 + 135.6 + 130
      });

      test('no-tax mode ignores the taxable flag', () {
        final t = totals(TaxMode.none, [
          const AdditionalCost(
              label: 'Freight', amount: 100, taxable: true, taxRate: 18),
        ]);
        expect(t.tax, 0);
        expect(t.taxableChargesTotal, 0);
        expect(t.total, 1100);
      });

      test('JSON round-trips the tax fields', () {
        const c = AdditionalCost(
            label: 'Freight', amount: 100, taxable: true, taxRate: 18,
            hsn: '9965');
        final back = AdditionalCost.listFromJson(AdditionalCost.listToJson([c]))
            .single;
        expect([back.taxable, back.taxRate, back.hsn], [true, 18.0, '9965']);
      });
    });
  });

  group('PaymentReceiptNumbers', () {
    test('uses the highest existing suffix', () {
      expect(
        PaymentReceiptNumbers.nextReceiptNumber(
          invoiceId: 'INV-7',
          existingReceiptNumbers: ['INV-7-R1', 'INV-7-R9', 'bad'],
        ),
        'INV-7-R10',
      );
    });
  });

  group('CustomerIdentity', () {
    test('prefers stable id and falls back to displayable name', () {
      expect(CustomerIdentity.key(id: ' C-1 ', name: 'Acme'), 'C-1');
      expect(CustomerIdentity.key(id: '', name: ' Acme '), 'Acme');
      expect(CustomerIdentity.displayName('  '), CustomerIdentity.unknownName);
    });
  });

  group('AppDate', () {
    test('creates stable date-only keys without timestamp splitting', () {
      expect(AppDate.dateKey(DateTime(2026, 5, 3, 14, 20)), '2026-05-03');
    });
  });

  group('buildQuotedCsv', () {
    test('quotes every cell and escapes quotes', () {
      expect(
        buildQuotedCsv([
          ['Name', 'Notes'],
          ['A, B', 'He said "paid"'],
        ]),
        '"Name","Notes"\n"A, B","He said ""paid"""',
      );
    });
  });
}
