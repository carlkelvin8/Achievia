// ignore_for_file: public_member_api_docs, sort_constructors_first
class ResetPasswordState {
  final bool isLoading;
  final int index;
  ResetPasswordState({required this.isLoading, required this.index});

  ResetPasswordState copyWith({bool? isLoading, int? index}) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      index: index ?? this.index,
    );
  }
}
