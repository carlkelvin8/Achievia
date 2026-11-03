import 'package:achievia/const.dart' show supabaseUrl;
import 'package:http/http.dart' as http;

/// Resolves module paths stored by the admin uploader without changing full URLs.
Uri? resolveModuleFileUri(String? value) {
  final path = value?.trim() ?? '';
  if (path.isEmpty) return null;
  final uri = Uri.tryParse(path);
  if (uri == null) return null;
  if (uri.hasScheme) {
    return (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty
        ? uri
        : null;
  }
  final relativePath = path.replaceFirst(RegExp(r'^/+'), '');
  return Uri.parse(
    '$supabaseUrl/storage/v1/object/public/admin/',
  ).resolve(relativePath);
}

Future<bool> checkModuleFileAccess(Uri uri, http.Client client) async {
  // Check the actual attachment before handing it to a third-party viewer.
  // Supabase returns HTTP 400 for missing objects, as well as HTTP 404.
  var response = await client.head(uri).timeout(const Duration(seconds: 20));
  // Some storage/CDN endpoints reject HEAD while serving GET normally.
  if (response.statusCode == 405 || response.statusCode == 501) {
    response = await client
        .get(uri, headers: const {'Range': 'bytes=0-0'})
        .timeout(const Duration(seconds: 20));
  }
  if (response.statusCode == 400 || response.statusCode == 404) {
    throw const ModuleFileException(
      'The document is missing at its saved link. Please ask the admin to '
      're-upload the file or update its link.',
    );
  }
  if (response.statusCode == 401 || response.statusCode == 403) {
    throw const ModuleFileException(
      'The document is not accessible. Please ask the admin to check its file permissions.',
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw const ModuleFileException(
      'The document could not be loaded. Please try again later.',
    );
  }
  return response.headers['content-type']
              ?.split(';')
              .first
              .trim()
              .toLowerCase() ==
          'application/pdf' ||
      uri.path.toLowerCase().endsWith('.pdf');
}

class ModuleFileException implements Exception {
  final String message;
  const ModuleFileException(this.message);
}
