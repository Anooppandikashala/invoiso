import 'package:invoiso/services/templates/template_pack.dart';

// Official builds: CI replaces this file with one that returns the private
// `.invoiso` decoder (PaidTemplatesPlan.md §4.2, S3). Keep the function name
// and signature unchanged. Public-source builds cannot open template files.
TemplatePackDecoder officialPackDecoder() => const NoPackDecoder();
