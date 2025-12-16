import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MockboardDynamicCard extends ConsumerWidget {
  final String label;
  const MockboardDynamicCard({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(getRandomQ);
    return provider.when(
      data: (question) {
      return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ListView.separated(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, index) =>
                                    Text('${index + 1}. ${question[index].title}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black
                                      ),
                                    ),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemCount: question.length,
                              )
                      ),
                    ),
                  ],
                );
          }, 
      error: (obj, st)=> Center(child: Text('An Error Occured'),),
      loading: ()=> Center(child: CircularProgressIndicator(),));
  }
}
