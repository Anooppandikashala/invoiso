// Makes a DEV template pack for trying the template screens in a debug build
// (PaidTemplatesPlan.md §17.9 Q5). Not encrypted, not signed: release builds
// refuse it. Real packs come from the private make_pack tool (S3).
//
//   dart run tool/make_dev_pack.dart <layout.json> <templateId> <name> [version] [--free]
//
// Writes <templateId>.invoiso next to the layout file.
import 'dart:convert';
import 'dart:io';

void main(List<String> argv) {
  final args = [...argv];
  final free = args.remove('--free');
  if (args.length < 3) {
    stderr.writeln('usage: dart run tool/make_dev_pack.dart <layout.json> <templateId> <name> [version] [--free]');
    exit(64);
  }
  final layoutFile = File(args[0]);
  final layout = jsonDecode(layoutFile.readAsStringSync());
  final pack = {
    'manifest': {
      'templateId': args[1],
      'name': args[2],
      'version': args.length > 3 ? int.parse(args[3]) : 1,
      'minEngine': layout is Map && layout['engine'] is int ? layout['engine'] : 1,
      'free': free,
    },
    'layout': layout,
  };
  final out = File('${layoutFile.parent.path}/${args[1]}.invoiso');
  out.writeAsStringSync('INVDEV1\n${jsonEncode(pack)}');
  stdout.writeln('wrote ${out.path}');
}
