import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/domain/entities/widgets/pdf_entity.dart';
import 'package:achievia/presentation/widgets/supplementals/abbreviation_list.dart';
import 'package:achievia/presentation/widgets/supplementals/mnemonic_grid.dart';
import 'package:achievia/presentation/widgets/supplementals/procedure_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_detail_screen.dart';

void main() {
  test('supplemental conversion preserves content and attachments', () {
    for (final kind in ['mnemonic', 'procedure']) {
      final dto = SupplementalItemDto(
        id: 1,
        courseId: null,
        kind: kind,
        title: 'Title',
        content: 'Full content',
        imageUrl: 'https://example.com/image.png',
        fileUrl: 'https://example.com/file.pdf',
      );
      if (kind == 'mnemonic') {
        expect(dto.toMnemonic()!.content, 'Full content');
        expect(dto.toMnemonic()!.fileUrl, dto.fileUrl);
        expect(dto.toMnemonic()!.image, dto.imageUrl);
      } else {
        expect(dto.toProcedure()!.content, 'Full content');
        expect(dto.toProcedure()!.fileUrl, dto.fileUrl);
      }
    }
  });
  Future<void> pumpBody(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    );
  }

  void expectTappableInkWells(WidgetTester tester, {required int count}) {
    final wells = tester.widgetList<InkWell>(find.byType(InkWell));
    expect(wells, hasLength(count));
    for (final well in wells) {
      expect(well.onTap, isNotNull);
      expect(well.mouseCursor, SystemMouseCursors.click);
    }
  }

  testWidgets('mnemonic tiles are tappable', (tester) async {
    await pumpBody(
      tester,
      MnemonicGrid(
        items: [
          NotesEntity(
            image: '',
            title: 'SIRS criteria',
            content: 'Full mnemonic content',
          ),
          NotesEntity(image: '', title: 'Brick mnemonic'),
        ],
      ),
    );

    expectTappableInkWells(tester, count: 2);

    await tester.tap(find.text('SIRS criteria'));
    await tester.pumpAndSettle();
    expect(find.byType(SupplementalDetailScreen), findsOneWidget);
    expect(find.text('Full mnemonic content'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brick mnemonic'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No additional content is available for this supplemental yet.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('abbreviation tiles are tappable', (tester) async {
    await pumpBody(
      tester,
      AbbreviationList(
        items: const [
          MedicalAbbreviation(
            abbreviation: 'SOB',
            expansion: 'Shortness of breath',
          ),
        ],
      ),
    );

    expectTappableInkWells(tester, count: 1);

    await tester.tap(find.text('Shortness of breath'));
    await tester.pumpAndSettle();
    expect(find.byType(SupplementalDetailScreen), findsOneWidget);
    expect(find.text('SOB'), findsOneWidget);
    expect(find.text('Shortness of breath'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('procedure tiles are tappable across the whole tile', (
    tester,
  ) async {
    await pumpBody(
      tester,
      ProcedureGrid(
        items: [
          PdfEntity(text: 'Wound care protocol', fileUrl: 'invalid-file'),
        ],
      ),
    );

    expectTappableInkWells(tester, count: 1);

    final wellBox = tester.renderObject(find.byType(InkWell)) as RenderBox;
    final captionCenter = tester.getCenter(find.text('Wound care protocol'));
    expect(wellBox.size.contains(wellBox.globalToLocal(captionCenter)), isTrue);

    await tester.tap(find.text('Wound care protocol'));
    await tester.pumpAndSettle();
    expect(find.byType(SupplementalDetailScreen), findsOneWidget);
    expect(find.text('Open file'), findsOneWidget);
    await tester.tap(find.text('Open file'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to open this file. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  group('mnemonic image display', () {
    Future<void> openMnemonic(WidgetTester tester, NotesEntity item) async {
      await pumpBody(tester, MnemonicGrid(items: [item]));
      await tester.tap(find.text(item.title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('the picture shows in the page with no Open file button', (
      tester,
    ) async {
      await openMnemonic(
        tester,
        NotesEntity(
          image: 'https://example.test/mohr.png',
          title: 'Mohr pipette',
          content: 'Content',
        ),
      );
      expect(find.byType(SupplementalDetailScreen), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Open file'), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('a PDF attachment keeps its Open file button', (tester) async {
      await openMnemonic(
        tester,
        NotesEntity(
          image: 'https://example.test/mohr.pdf',
          title: 'Mohr pipette',
          content: 'Content',
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.text('Open file'), findsOneWidget);
    });
  });
}
