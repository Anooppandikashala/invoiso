
// constants.dart
import 'package:flutter/material.dart';

class AppSpacing {
  static const baseValue = 8.0;
  static const hSmall = SizedBox(height: baseValue);
  static const hMedium = SizedBox(height: 2*baseValue);
  static const hLarge = SizedBox(height: 3*baseValue);
  static const hXlarge = SizedBox(height: 4*baseValue);

  static const wSmall = SizedBox(width: baseValue);
  static const wMedium = SizedBox(width: 2*baseValue);
  static const wLarge = SizedBox(width: 3*baseValue);
  static const wXlarge = SizedBox(width: 4*baseValue);
}

class AppFontSize
{
  static const small = 12;
  static const medium = 14;
  static const large = 16;
  static const xlarge = 20;
  static const xxlarge = 24;
}

class AppConfig
{
  static const name = "invoiso";
  static const version = "1.0";
}

class Tax
{
  static const defaultTaxRate = 0.18;
}