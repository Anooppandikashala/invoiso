import 'common.dart';

class SupportedCurrencies {
  static const List<CurrencyOption> all = [
    // Default currency
    CurrencyOption(code: 'INR', symbol: 'Rs.', name: 'Indian Rupee'),

    // Sorted by currency code
    CurrencyOption(code: 'AED', symbol: 'AED.', name: 'UAE Dirham'),
    CurrencyOption(code: 'AFN', symbol: '؋', name: 'Afghan Afghani'),
    CurrencyOption(code: 'ALL', symbol: 'Lek', name: 'Albanian Lek'),
    CurrencyOption(code: 'AMD', symbol: '֏', name: 'Armenian Dram'),
    CurrencyOption(
      code: 'ANG',
      symbol: 'ƒ',
      name: 'Netherlands Antillean Guilder',
    ),
    CurrencyOption(code: 'AOA', symbol: 'Kz', name: 'Angolan Kwanza'),
    CurrencyOption(code: 'ARS', symbol: '\$', name: 'Argentine Peso'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyOption(code: 'AWG', symbol: 'ƒ', name: 'Aruban Florin'),
    CurrencyOption(code: 'AZN', symbol: '₼', name: 'Azerbaijani Manat'),

    CurrencyOption(
      code: 'BAM',
      symbol: 'KM',
      name: 'Bosnia-Herzegovina Convertible Mark',
    ),
    CurrencyOption(code: 'BBD', symbol: 'Bds\$', name: 'Barbadian Dollar'),
    CurrencyOption(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    CurrencyOption(code: 'BGN', symbol: 'лв', name: 'Bulgarian Lev'),
    CurrencyOption(code: 'BHD', symbol: 'BHD', name: 'Bahraini Dinar'),
    CurrencyOption(code: 'BIF', symbol: 'FBu', name: 'Burundian Franc'),
    CurrencyOption(code: 'BMD', symbol: '\$', name: 'Bermudian Dollar'),
    CurrencyOption(code: 'BND', symbol: 'B\$', name: 'Brunei Dollar'),
    CurrencyOption(code: 'BOB', symbol: 'Bs.', name: 'Bolivian Boliviano'),
    CurrencyOption(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    CurrencyOption(code: 'BSD', symbol: 'B\$', name: 'Bahamian Dollar'),
    CurrencyOption(code: 'BTN', symbol: 'Nu.', name: 'Bhutanese Ngultrum'),
    CurrencyOption(code: 'BWP', symbol: 'P', name: 'Botswana Pula'),
    CurrencyOption(code: 'BYN', symbol: 'Br', name: 'Belarusian Ruble'),
    CurrencyOption(code: 'BZD', symbol: 'BZ\$', name: 'Belize Dollar'),

    CurrencyOption(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    CurrencyOption(code: 'CDF', symbol: 'FC', name: 'Congolese Franc'),
    CurrencyOption(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    CurrencyOption(code: 'CLP', symbol: '\$', name: 'Chilean Peso'),
    CurrencyOption(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyOption(code: 'COP', symbol: '\$', name: 'Colombian Peso'),
    CurrencyOption(code: 'CRC', symbol: '₡', name: 'Costa Rican Colón'),
    CurrencyOption(code: 'CUP', symbol: '\$', name: 'Cuban Peso'),
    CurrencyOption(code: 'CVE', symbol: '\$', name: 'Cape Verdean Escudo'),
    CurrencyOption(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna'),

    CurrencyOption(code: 'DJF', symbol: 'Fdj', name: 'Djiboutian Franc'),
    CurrencyOption(code: 'DKK', symbol: 'kr.', name: 'Danish Krone'),
    CurrencyOption(code: 'DOP', symbol: 'RD\$', name: 'Dominican Peso'),
    CurrencyOption(code: 'DZD', symbol: 'دج', name: 'Algerian Dinar'),

    CurrencyOption(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
    CurrencyOption(code: 'ERN', symbol: 'Nfk', name: 'Eritrean Nakfa'),
    CurrencyOption(code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr'),
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),

    CurrencyOption(code: 'FJD', symbol: 'FJ\$', name: 'Fijian Dollar'),
    CurrencyOption(code: 'FKP', symbol: '£', name: 'Falkland Islands Pound'),

    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound Sterling'),
    CurrencyOption(code: 'GEL', symbol: '₾', name: 'Georgian Lari'),
    CurrencyOption(code: 'GHS', symbol: '₵', name: 'Ghanaian Cedi'),
    CurrencyOption(code: 'GIP', symbol: '£', name: 'Gibraltar Pound'),
    CurrencyOption(code: 'GMD', symbol: 'D', name: 'Gambian Dalasi'),
    CurrencyOption(code: 'GNF', symbol: 'FG', name: 'Guinean Franc'),
    CurrencyOption(code: 'GTQ', symbol: 'Q', name: 'Guatemalan Quetzal'),
    CurrencyOption(code: 'GYD', symbol: 'G\$', name: 'Guyanese Dollar'),

    CurrencyOption(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
    CurrencyOption(code: 'HNL', symbol: 'L', name: 'Honduran Lempira'),
    CurrencyOption(code: 'HTG', symbol: 'G', name: 'Haitian Gourde'),
    CurrencyOption(code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint'),

    CurrencyOption(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    CurrencyOption(code: 'ILS', symbol: '₪', name: 'Israeli New Shekel'),
    CurrencyOption(code: 'IQD', symbol: 'IQD', name: 'Iraqi Dinar'),
    CurrencyOption(code: 'IRR', symbol: '﷼', name: 'Iranian Rial'),
    CurrencyOption(code: 'ISK', symbol: 'kr', name: 'Icelandic Króna'),

    CurrencyOption(code: 'JMD', symbol: 'J\$', name: 'Jamaican Dollar'),
    CurrencyOption(code: 'JOD', symbol: 'JOD', name: 'Jordanian Dinar'),
    CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),

    CurrencyOption(code: 'KES', symbol: 'KSh.', name: 'Kenyan Shilling'),
    CurrencyOption(code: 'KGS', symbol: 'с', name: 'Kyrgyzstani Som'),
    CurrencyOption(code: 'KHR', symbol: '៛', name: 'Cambodian Riel'),
    CurrencyOption(code: 'KMF', symbol: 'CF', name: 'Comorian Franc'),
    CurrencyOption(code: 'KPW', symbol: '₩', name: 'North Korean Won'),
    CurrencyOption(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    CurrencyOption(code: 'KWD', symbol: 'KWD', name: 'Kuwaiti Dinar'),
    CurrencyOption(code: 'KYD', symbol: 'CI\$', name: 'Cayman Islands Dollar'),
    CurrencyOption(code: 'KZT', symbol: '₸', name: 'Kazakhstani Tenge'),

    CurrencyOption(code: 'LAK', symbol: '₭', name: 'Lao Kip'),
    CurrencyOption(code: 'LBP', symbol: 'ل.ل', name: 'Lebanese Pound'),
    CurrencyOption(code: 'LKR', symbol: 'රු', name: 'Sri Lankan Rupee'),
    CurrencyOption(code: 'LRD', symbol: 'L\$', name: 'Liberian Dollar'),
    CurrencyOption(code: 'LSL', symbol: 'L', name: 'Lesotho Loti'),
    CurrencyOption(code: 'LYD', symbol: 'LYD', name: 'Libyan Dinar'),

    CurrencyOption(code: 'MAD', symbol: 'د.م.', name: 'Moroccan Dirham'),
    CurrencyOption(code: 'MDL', symbol: 'L', name: 'Moldovan Leu'),
    CurrencyOption(code: 'MGA', symbol: 'Ar', name: 'Malagasy Ariary'),
    CurrencyOption(code: 'MKD', symbol: 'ден', name: 'Macedonian Denar'),
    CurrencyOption(code: 'MMK', symbol: 'K', name: 'Myanmar Kyat'),
    CurrencyOption(code: 'MNT', symbol: '₮', name: 'Mongolian Tögrög'),
    CurrencyOption(code: 'MOP', symbol: 'MOP\$', name: 'Macanese Pataca'),
    CurrencyOption(code: 'MRU', symbol: 'UM', name: 'Mauritanian Ouguiya'),
    CurrencyOption(code: 'MUR', symbol: '₨', name: 'Mauritian Rupee'),
    CurrencyOption(code: 'MVR', symbol: 'Rf', name: 'Maldivian Rufiyaa'),
    CurrencyOption(code: 'MWK', symbol: 'MK', name: 'Malawian Kwacha'),
    CurrencyOption(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso'),
    CurrencyOption(code: 'MYR', symbol: 'RM.', name: 'Malaysian Ringgit'),
    CurrencyOption(code: 'MZN', symbol: 'MT', name: 'Mozambican Metical'),

    CurrencyOption(code: 'NAD', symbol: 'N\$', name: 'Namibian Dollar'),
    CurrencyOption(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    CurrencyOption(code: 'NIO', symbol: 'C\$', name: 'Nicaraguan Córdoba'),
    CurrencyOption(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    CurrencyOption(code: 'NPR', symbol: 'Rs.', name: 'Nepalese Rupee'),
    CurrencyOption(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),

    CurrencyOption(code: 'OMR', symbol: 'OMR.', name: 'Omani Rial'),

    CurrencyOption(code: 'PAB', symbol: 'B/.', name: 'Panamanian Balboa'),
    CurrencyOption(code: 'PEN', symbol: 'S/', name: 'Peruvian Sol'),
    CurrencyOption(code: 'PGK', symbol: 'K', name: 'Papua New Guinean Kina'),
    CurrencyOption(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    CurrencyOption(code: 'PKR', symbol: 'Rs.', name: 'Pakistani Rupee'),
    CurrencyOption(code: 'PLN', symbol: 'zł', name: 'Polish Złoty'),
    CurrencyOption(code: 'PYG', symbol: '₲', name: 'Paraguayan Guarani'),

    CurrencyOption(code: 'QAR', symbol: 'QAR.', name: 'Qatari Riyal'),

    CurrencyOption(code: 'RON', symbol: 'lei', name: 'Romanian Leu'),
    CurrencyOption(code: 'RSD', symbol: 'дин.', name: 'Serbian Dinar'),
    CurrencyOption(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    CurrencyOption(code: 'RWF', symbol: 'FRw', name: 'Rwandan Franc'),

    CurrencyOption(code: 'SAR', symbol: 'SAR.', name: 'Saudi Riyal'),
    CurrencyOption(code: 'SBD', symbol: 'SI\$', name: 'Solomon Islands Dollar'),
    CurrencyOption(code: 'SCR', symbol: '₨', name: 'Seychellois Rupee'),
    CurrencyOption(code: 'SDG', symbol: 'ج.س.', name: 'Sudanese Pound'),
    CurrencyOption(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    CurrencyOption(code: 'SHP', symbol: '£', name: 'Saint Helena Pound'),
    CurrencyOption(code: 'SLE', symbol: 'Le', name: 'Sierra Leonean Leone'),
    CurrencyOption(code: 'SOS', symbol: 'S', name: 'Somali Shilling'),
    CurrencyOption(code: 'SRD', symbol: 'SR\$', name: 'Surinamese Dollar'),
    CurrencyOption(code: 'SSP', symbol: '£', name: 'South Sudanese Pound'),
    CurrencyOption(
      code: 'STN',
      symbol: 'Db',
      name: 'São Tomé and Príncipe Dobra',
    ),
    CurrencyOption(code: 'SYP', symbol: '£', name: 'Syrian Pound'),
    CurrencyOption(code: 'SZL', symbol: 'E', name: 'Eswatini Lilangeni'),

    CurrencyOption(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    CurrencyOption(code: 'TJS', symbol: 'SM', name: 'Tajikistani Somoni'),
    CurrencyOption(code: 'TMT', symbol: 'T', name: 'Turkmenistan Manat'),
    CurrencyOption(code: 'TND', symbol: 'TND.', name: 'Tunisian Dinar'),
    CurrencyOption(code: 'TOP', symbol: 'T\$', name: 'Tongan Paʻanga'),
    CurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    CurrencyOption(code: 'TTD', symbol: 'TT\$', name: 'Trinidad and Tobago Dollar'),
    CurrencyOption(code: 'TWD', symbol: 'NT\$', name: 'New Taiwan Dollar'),
    CurrencyOption(code: 'TZS', symbol: 'TSh', name: 'Tanzanian Shilling'),

    CurrencyOption(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia'),
    CurrencyOption(code: 'UGX', symbol: 'USh', name: 'Ugandan Shilling'),
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyOption(code: 'UYU', symbol: '\$U', name: 'Uruguayan Peso'),
    CurrencyOption(code: 'UZS', symbol: "soʻm", name: 'Uzbekistani Som'),

    CurrencyOption(
      code: 'VED',
      symbol: 'Bs.D',
      name: 'Venezuelan Digital Bolívar',
    ),
    CurrencyOption(code: 'VES', symbol: 'Bs.S', name: 'Venezuelan Bolívar'),
    CurrencyOption(code: 'VND', symbol: '₫', name: 'Vietnamese Đồng'),
    CurrencyOption(code: 'VUV', symbol: 'VT', name: 'Vanuatu Vatu'),

    CurrencyOption(code: 'WST', symbol: 'T', name: 'Samoan Tala'),

    CurrencyOption(
      code: 'XAF',
      symbol: 'FCFA',
      name: 'Central African CFA Franc',
    ),
    CurrencyOption(
      code: 'XCD',
      symbol: 'EC\$',
      name: 'East Caribbean Dollar',
    ),
    CurrencyOption(
      code: 'XOF',
      symbol: 'FCFA',
      name: 'West African CFA Franc',
    ),
    CurrencyOption(code: 'XPF', symbol: '₣', name: 'CFP Franc'),

    CurrencyOption(code: 'YER', symbol: '﷼', name: 'Yemeni Rial'),

    CurrencyOption(code: 'ZAR', symbol: 'R.', name: 'South African Rand'),
    CurrencyOption(code: 'ZMW', symbol: 'ZK', name: 'Zambian Kwacha'),
    CurrencyOption(code: 'ZWG', symbol: 'ZiG', name: 'Zimbabwe Gold'),
  ];

  static CurrencyOption fromCode(String code) {
    return all.firstWhere(
          (c) => c.code == code,
      orElse: () => all.first,
    );
  }
}