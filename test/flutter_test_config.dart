// Auto-loaded by flutter_test before every test file in test/.
// Disables google_fonts runtime fetching: in widget tests the HTTP
// stack returns 400, so font fetches fail asynchronously and flake
// otherwise-green tests. Widgets fall back to bundled fonts.
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
