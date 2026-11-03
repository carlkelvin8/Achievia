import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ModulePdfPreviewScreen extends StatelessWidget {
  final Uri uri;
  final String title;

  const ModulePdfPreviewScreen({
    super.key,
    required this.uri,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: PdfViewer.uri(
          uri,
          timeout: const Duration(seconds: 30),
          params: PdfViewerParams(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            loadingBannerBuilder: (context, downloaded, total) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: total != null && total > 0
                        ? (downloaded / total).clamp(0.0, 1.0)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading PDF…'),
                ],
              ),
            ),
            errorBannerBuilder: (context, error, stack, document) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to preview this PDF. Check your connection or ask the admin to verify the file.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          document.resolveListenable().load(forceReload: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
