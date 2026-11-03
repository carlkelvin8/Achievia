import 'package:achievia/core/utils/module_file_access.dart';
import 'package:flutter/material.dart';

/// Displays the attachment stored on this question, without cropping it.
class QuestionImage extends StatefulWidget {
  final String imagePath;

  const QuestionImage({super.key, required this.imagePath});

  @override
  State<QuestionImage> createState() => _QuestionImageState();
}

class _QuestionImageState extends State<QuestionImage> {
  int _retry = 0;

  @override
  Widget build(BuildContext context) {
    final uri = resolveModuleFileUri(widget.imagePath);
    if (widget.imagePath.trim().isEmpty ||
        widget.imagePath.trim().toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }
    if (uri == null) return _error();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: Image.network(
          uri.toString(),
          key: ValueKey('${uri.toString()}-$_retry'),
          fit: BoxFit.contain,
          semanticLabel: 'Question image',
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, _, _) => _error(uri),
        ),
      ),
    );
  }

  Widget _error([Uri? uri]) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Question image could not be loaded.'),
        if (uri != null)
          TextButton(
            onPressed: () async {
              await NetworkImage(uri.toString()).evict();
              if (mounted) setState(() => _retry++);
            },
            child: const Text('Retry image'),
          ),
      ],
    ),
  );
}
