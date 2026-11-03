import 'package:achievia/core/constants/legal_documents.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Opens the bundled Privacy Policy or Terms of Service PDF. Reachable before
/// login so the sign-up form can link to both.
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: document.title, centerTitle: true),
      body: SafeArea(
        child: PdfViewer.asset(
          document.asset,
          params: PdfViewerParams(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            errorBannerBuilder: (context, error, stack, documentRef) =>
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Unable to open this document. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
