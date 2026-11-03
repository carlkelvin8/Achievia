import 'package:achievia/core/utils/module_file_access.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/reviewer/module_provider.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'module_pdf_preview_screen.dart';

class MotherNotesContent extends ConsumerStatefulWidget {
  const MotherNotesContent({super.key});

  @override
  ConsumerState<MotherNotesContent> createState() => _MotherNotesContentState();
}

class _MotherNotesContentState extends ConsumerState<MotherNotesContent> {
  late final ScrollController _scrollController;
  bool _openingFile = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      ref.read(paginatedModulesProvider.notifier).loadMore();
    }
  }

  Future<void> _openFile(String? fileUrl, String title) async {
    if (_openingFile) return;
    if (fileUrl == null || fileUrl.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file available for this module.')),
        );
      }
      return;
    }

    final uri = resolveModuleFileUri(fileUrl);
    if (uri == null) {
      await _showFileError(
        'The document link is invalid. Please ask the admin to update it.',
        fileUrl,
        title,
      );
      return;
    }
    setState(() => _openingFile = true);
    final client = http.Client();
    String? failure;
    try {
      final isPdf = await checkModuleFileAccess(uri, client);
      if (!mounted) return;
      if (isPdf) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ModulePdfPreviewScreen(uri: uri, title: title),
          ),
        );
        return;
      }
      // Keep the office-document viewer for non-PDF attachments.
      final viewerUri = Uri.parse(
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(uri.toString())}&embedded=true',
      );
      final launched = await launchUrl(
        viewerUri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        failure = 'Could not open the document viewer. Please try again.';
      }
    } on ModuleFileException catch (error) {
      failure = error.message;
    } catch (_) {
      failure =
          'Unable to load the document. Check your internet connection and try again.';
    } finally {
      client.close();
      if (mounted) setState(() => _openingFile = false);
    }
    if (mounted && failure != null) {
      await _showFileError(failure, fileUrl, title);
    }
  }

  Future<void> _showFileError(
    String message,
    String? fileUrl,
    String title,
  ) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview unavailable'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) await _openFile(fileUrl, title);
  }

  @override
  Widget build(BuildContext context) {
    final modulesState = ref.watch(paginatedModulesProvider);
    final modulesNotifier = ref.read(paginatedModulesProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: level1,
        child: Builder(
          builder: (context) {
            if (modulesState.isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (modulesState.items.isEmpty &&
                modulesState.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading modules',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      modulesState.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: modulesNotifier.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (modulesState.items.isEmpty) {
              return const Center(child: Text('No modules found'));
            }

            final totalCount =
                modulesState.items.length +
                (modulesState.isLoadingMore ? 1 : 0);

            return Column(
              children: [
                if (_openingFile) const LinearProgressIndicator(),
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: totalCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      if (index >= modulesState.items.length) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        );
                      }

                      final module = modulesState.items[index];
                      return PdfBadge(
                        tabType: 'mother notes',
                        text: module.title,
                        imageUrl: module.image,
                        callback: () => _openFile(module.file, module.title),
                      );
                    },
                  ),
                ),
                if (modulesState.errorMessage != null &&
                    modulesState.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: modulesNotifier.loadMore,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading more'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
