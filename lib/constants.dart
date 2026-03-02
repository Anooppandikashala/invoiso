
// constants.dart
import 'package:flutter/material.dart';
import 'package:invoiso/common.dart';

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
  static const xsmall = 10.0;
  static const small = 12.0;
  static const medium = 14.0;
  static const large = 16.0;
  static const xlarge = 18.0;
  static const xxlarge = 20.0;
  static const xxxlarge = 22.0;
}

class AppPadding
{
  static const xxxsmall = 4.0;
  static const xxsmall = 6.0;
  static const xsmall = 8.0;
  static const small = 10.0;
  static const medium = 12.0;
  static const large = 14.0;
  static const xlarge = 16.0;
  static const xxlarge = 18.0;
  static const xxxlarge = 20.0;
}

class AppMargin
{
  static const xxxsmall = 4.0;
  static const xxsmall = 6.0;
  static const xsmall = 8.0;
  static const small = 10.0;
  static const medium = 12.0;
  static const large = 14.0;
  static const xlarge = 16.0;
  static const xxlarge = 18.0;
  static const xxxlarge = 20.0;
}

class AppBorderRadius
{
  static const xsmall = 8.0;
  static const small = 10.0;
  static const medium = 12.0;
  static const large = 14.0;
}

class AppConfig
{
  static const name = "invoiso";
  static const version = "v3.0.5";
  static const developer = "ANOOP P";
  static const supportEmail = "anooppkrishnan96@gmail.com";
  static const website = "https://anooppandikashala.github.io/invoisoapp/";
  static const license = "MIT";
  static const description = "Invoiso is a modern invoice and quotation management app for freelancers and small businesses.";
}

class Tax
{
  static const defaultTaxRate = 0.18;
}

class DefaultValues
{
  static const String additionalNote = "No return after 15 days.";
  static const String thankYouNote = "Thank you for your business! | Visit us at [Your Website]";
  static const LogoPosition logoPosition = LogoPosition.left;
}