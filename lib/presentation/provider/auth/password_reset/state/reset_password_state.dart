// ignore_for_file: public_member_api_docs, sort_constructors_first
class ResetPasswordState {
  final bool isLoading;
  final int index;
  final int otpSecondsRemaining;
  ResetPasswordState({
    required this.isLoading,
    required this.index,
    this.otpSecondsRemaining = 0,
  });

  bool get canResendOtp => otpSecondsRemaining == 0;

  ResetPasswordState copyWith({
    bool? isLoading,
    int? index,
    int? otpSecondsRemaining,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      index: index ?? this.index,
      otpSecondsRemaining: otpSecondsRemaining ?? this.otpSecondsRemaining,
    );
  }
}
