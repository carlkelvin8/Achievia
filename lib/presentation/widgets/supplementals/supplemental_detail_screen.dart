import 'package:achievia/core/utils/inline_html.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplementalDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  /// Longer explanation shown under [content] (abbreviations).
  final String description;
  final String? imageUrl;
  final String? fileUrl;
  final bool isMnemonic;

  /// When true, an attachment that is the image already shown inline gets no
  /// separate "Open file" button (Mnemonics). PDFs and other files keep it,
  /// since they cannot be displayed in the page.
  final bool hideOpenFileForInlineImage;

  const SupplementalDetailScreen({
    super.key,
    required this.title,
    required this.content,
    this.description = '',
    this.imageUrl,
    this.fileUrl,
    this.isMnemonic = false,
    this.hideOpenFileForInlineImage = false,
  });

  /// Starts downloading [url] into Flutter's image cache so the picture is
  /// ready (or nearly) by the time its page is on screen. Never throws.
  static void prefetchImage(BuildContext context, String? url) {
    final value = url?.trim() ?? '';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        value.isEmpty ||
        uri.path.toLowerCase().endsWith('.pdf') ||
        !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return;
    }
    precacheImage(NetworkImage(value), context, onError: (_, _) {});
  }

  static void open(
    BuildContext context, {
    required String title,
    required String content,
    String description = '',
    String? imageUrl,
    String? fileUrl,
    bool isMnemonic = false,
    bool hideOpenFileForInlineImage = false,
  }) {
    // Begin the download while the page transition runs.
    prefetchImage(context, imageUrl);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SupplementalDetailScreen(
          title: title,
          content: content,
          description: description,
          imageUrl: imageUrl,
          fileUrl: fileUrl,
          isMnemonic: isMnemonic,
          hideOpenFileForInlineImage: hideOpenFileForInlineImage,
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Keep the detail view usable when the attachment cannot be opened.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open this file. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim() ?? '';
    final file = fileUrl?.trim() ?? '';
    // Some mnemonic attachments are PDFs rather than images.
    final imageIsPdf =
        Uri.tryParse(image)?.path.toLowerCase().endsWith('.pdf') ?? false;
    final attachment = file.isNotEmpty ? file : image;
    final showsImageInline = image.isNotEmpty && !imageIsPdf;
    // The attachment is the picture that is already displayed in the page.
    final attachmentIsInlineImage =
        showsImageInline && (attachment == image || file.isEmpty);
    final showOpenFile =
        attachment.isNotEmpty &&
        !(hideOpenFileForInlineImage && attachmentIsInlineImage);
    final titleStyle = isMnemonic
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.headlineSmall;
    final titleWidget = SelectableText.rich(
      InlineHtml.span(title, titleStyle, selectable: true),
      textAlign: isMnemonic ? TextAlign.center : TextAlign.start,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyLarge;
    final descriptionWidget = SelectableText.rich(
      InlineHtml.span(content, bodyStyle, selectable: true),
      textAlign: isMnemonic ? TextAlign.justify : TextAlign.start,
    );

    return Scaffold(
      appBar: AppBar(title: Text(isMnemonic ? 'Mnemonic' : 'Supplemental')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, isMnemonic ? 8 : 20, 20, 20),
          children: [
            if (!isMnemonic) ...[
              titleWidget,
              const SizedBox(height: 20),
              if (content.trim().isNotEmpty) ...[
                descriptionWidget,
                const SizedBox(height: 20),
              ],
              if (description.trim().isNotEmpty) ...[
                SelectableText.rich(
                  InlineHtml.span(
                    description,
                    Theme.of(context).textTheme.bodyMedium,
                    selectable: true,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
            if (showsImageInline) ...[
              InteractiveViewer(
                maxScale: 5,
                alignment: isMnemonic ? Alignment.center : null,
                child: Image.network(
                  image,
                  alignment: Alignment.center,
                  // Keep the space reserved and show progress while the
                  // picture downloads, then fade it in; a cached picture
                  // appears at once (no placeholder frame).
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    final total = progress.expectedTotalBytes;
                    return SizedBox(
                      key: const ValueKey('supplemental-image-loading'),
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: total == null
                              ? null
                              : progress.cumulativeBytesLoaded / total,
                        ),
                      ),
                    );
                  },
                  frameBuilder: (context, child, frame, sync) {
                    if (sync) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: child,
                    );
                  },
                  errorBuilder: (_, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      showOpenFile
                          ? 'Image preview unavailable. Use Open file to view the attachment.'
                          : 'Image preview unavailable. Please try again.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isMnemonic) ...[
              titleWidget,
              if (content.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                descriptionWidget,
              ],
              if (showOpenFile) const SizedBox(height: 20),
            ],
            if (showOpenFile)
              FilledButton.icon(
                onPressed: () => _openFile(context, attachment),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open file'),
              ),
            if (content.trim().isEmpty &&
                description.trim().isEmpty &&
                !showsImageInline &&
                attachment.isEmpty)
              const Text(
                'No additional content is available for this supplemental yet.',
              ),
          ],
        ),
      ),
    );
  }
}
