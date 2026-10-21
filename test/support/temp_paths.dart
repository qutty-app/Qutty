import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Points path_provider at a temp directory for the duration of a test group.
///
/// The font code caches font files through `getApplicationSupportDirectory`,
/// which is a platform channel. Without this it does not fail in a test, it
/// hangs, waiting for a reply no test binding will send.
class TempPathProvider extends PathProviderPlatform {
  TempPathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
}
