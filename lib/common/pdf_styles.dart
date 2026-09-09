class CompactPdfTotalsStyle {
  const CompactPdfTotalsStyle({
    this.width = 108,
    this.rowFontSize = 4.5,
    this.highlightFontSize = 5.0,
    this.rowHorizontalPadding = 3,
    this.rowVerticalPadding = 2,
    this.highlightHorizontalPadding = 4,
    this.highlightVerticalPadding = 3,
    this.borderRadius = 2,
  });

  final double width;
  final double rowFontSize;
  final double highlightFontSize;
  final double rowHorizontalPadding;
  final double rowVerticalPadding;
  final double highlightHorizontalPadding;
  final double highlightVerticalPadding;
  final double borderRadius;
}

const compactPdfTotalsStyle = CompactPdfTotalsStyle();

class CompactPdfLayoutStyle {
  const CompactPdfLayoutStyle({
    this.logoScale = 0.5,
    this.tableFontSize = 4.0,
    this.tableHorizontalPadding = 2,
    this.tableVerticalPadding = 1.2,
    this.headerGap = 3,
    this.headerPadding = 2,
    this.signatureTopGap = 5,
    this.signatureImageHeight = 22,
    this.signatureLabelGap = 1.5,
    this.signatureLabelFontSize = 3.8,
    this.footerBrandingFontSize = 3.8,
    this.footerTopMargin = 4,
    this.titleFontSize = 8,
    this.subtitleFontSize = 5,
    this.bodyFontSize = 5,
    this.totalsFontSize = 7,
  });

  final double logoScale;
  final double tableFontSize;
  final double tableHorizontalPadding;
  final double tableVerticalPadding;
  final double headerGap;
  final double headerPadding;
  final double signatureTopGap;
  final double signatureImageHeight;
  final double signatureLabelGap;
  final double signatureLabelFontSize;
  final double footerBrandingFontSize;
  final double footerTopMargin;
  final double titleFontSize;
  final double subtitleFontSize;
  final double bodyFontSize;
  final double totalsFontSize;
}

const compactPdfLayoutStyle = CompactPdfLayoutStyle();

/// Tunable font sizes/paddings for a single PDF template. One const instance
/// per template (below) holds that template's current values as defaults —
/// edit an instance's values here to restyle that template everywhere.
class PdfTemplateStyle {
  const PdfTemplateStyle({
    this.titleFontSize = 14,
    this.subtitleFontSize = 9,
    this.labelFontSize = 8,
    this.bodyFontSize = 9,
    this.tableHeaderFontSize = 8,
    this.tableFontSize = 8,
    this.totalsFontSize = 9,
    this.totalsHighlightFontSize = 11,
    this.footerFontSize = 8,
    this.cellPaddingH = 6,
    this.cellPaddingV = 6,
    this.sectionPadding = 8,
    this.headerGap = 6,
    this.typeFont = 10,
  });

  final double titleFontSize;
  final double subtitleFontSize;
  final double labelFontSize;
  final double bodyFontSize;
  final double tableHeaderFontSize;
  final double tableFontSize;
  final double totalsFontSize;
  final double totalsHighlightFontSize;
  final double footerFontSize;
  final double cellPaddingH;
  final double cellPaddingV;
  final double sectionPadding;
  final double headerGap;
  final double typeFont;
}

const classicPdfStyle = PdfTemplateStyle(
  titleFontSize: 14,
  subtitleFontSize: 8,
  labelFontSize: 8,
  bodyFontSize: 8,
  headerGap: 2,
  sectionPadding: 4,
  tableFontSize: 8,
  typeFont: 10,
);
const executivePdfStyle = PdfTemplateStyle(
  titleFontSize: 14,
  subtitleFontSize: 9,
  labelFontSize: 8,
  bodyFontSize: 8,
  sectionPadding: 8,
  headerGap: 6,
);
const minimalPdfStyle = PdfTemplateStyle(
  titleFontSize: 12,
  subtitleFontSize: 9,
  labelFontSize: 9,
  bodyFontSize: 8,
  headerGap: 5,
);
const modernPdfStyle = PdfTemplateStyle(
  titleFontSize: 15,
  subtitleFontSize: 10,
  labelFontSize: 10,
  bodyFontSize: 8,
  sectionPadding: 10,
  headerGap: 8,
  tableFontSize: 8,
  typeFont: 10
);
const gridClassicPdfStyle = PdfTemplateStyle(
  titleFontSize: 12,
  subtitleFontSize: 8,
  labelFontSize: 7.5,
  bodyFontSize: 9,
  tableHeaderFontSize: 7.5,
  tableFontSize: 7.5,
  totalsFontSize: 8,
  totalsHighlightFontSize: 10,
  footerFontSize: 7,
  cellPaddingH: 4,
  cellPaddingV: 4,
  sectionPadding: 7,
  headerGap: 6,
);
