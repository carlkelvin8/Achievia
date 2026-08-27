import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/widgets/questions_entity.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const List<GradingBracket> gradingBrackets = [
  GradingBracket(
    scoreRange: 'Below 50%',
    level: 'Recharge & Refocus',
    message:
        'Double your effort. Revisit the basics and rebuild your foundation.',
  ),
  GradingBracket(
    scoreRange: '50% - 64%',
    level: 'Warming Up',
    message: 'Progress is showing. Strengthen weak areas and stay consistent.',
  ),
  GradingBracket(
    scoreRange: '65% - 74%',
    level: 'Almost There',
    message:
        'You\'re on the right track. Improve accuracy and keep practicing.',
  ),
  GradingBracket(
    scoreRange: '75% - 84%',
    level: 'Solid Achievian',
    message:
        'Strong performance! Focus on high-yield topics and aim even higher.',
  ),
  GradingBracket(
    scoreRange: '85% - 89%',
    level: 'Board Ready',
    message:
        'You\'re nearly there. Sharpen your details and maintain your momentum.',
  ),
  GradingBracket(
    scoreRange: '90% and Above',
    level: 'Achievian Topnotcher Potential',
    message:
        'Excellent work! You\'re on topnotcher path - keep pushing and stay sharp.',
  ),
];

final List<QuestionsEntityWidget> questions = [
  QuestionsEntityWidget(
    icon: Icons.question_answer_rounded,
    label: 'Question Bank',
    sub_label:
        'A comprehensive collection of board exam-style questions designed to cover all major topics, helping you practice, assess your understanding, and prepare effectively for the actual exam.',
    callback: (context) => context.push(RouteConstants.questionBankSubjects),
  ),
  QuestionsEntityWidget(
    icon: Icons.edit_document,
    label: 'Mock Boards',
    sub_label:
        'Simulated board examinations designed to mirror the actual exam experience, helping you assess your readiness, build confidence, and identify areas that need improvement before the real test.',
    callback: null,
  ),
  QuestionsEntityWidget(
    icon: Icons.emoji_events_sharp,
    label: 'Pre Boards',
    sub_label:
        'A final one-take comprehensive exam that simulates the actual board, available only once and unlocked 2 weeks before the scheduled board exam to help you gauge your ultimate readiness.',
    callback: (context) => context.push(RouteConstants.onboardingQuestions),
  ),
];

final List<String> assets = [
  'Review each question carefully.',
  'Skip questions that are hard and come back to them if there\'s still time.',
  'Manage your time wisely — don\'t get stuck on one question.',
  'Focus throughout the exam and avoid distractions.',
];

final List<String> assets2 = [
  'General Passing Average: Minimum of 75% overall.',
  'Minimum Subject Score: You must not score below 50% in any major subject. One subject below 50% results in automatic failure.',
];

List<Widget> buildExamFooter({
  required VoidCallback onPrev,
  required VoidCallback onToggleModal,
  required VoidCallback? onNext,
  required bool isAnswered,
  required Color iconColor,
  double buttonWidth = 240,
  double buttonHeight = 50,
}) {
  return [
    IconButton(
      onPressed: onPrev,
      icon: Icon(Icons.arrow_back_ios, color: iconColor),
    ),
    ReusableButton(
      title: isAnswered ? 'ANSWERED' : 'UNANSWERED',
      onPressed: onToggleModal,
      width: buttonWidth,
      height: buttonHeight,
    ),
    IconButton(
      onPressed: onNext,
      icon: Icon(Icons.arrow_forward_ios, color: iconColor),
    ),
  ];
}

String? validate(
  String field,
  String? value,
  TextEditingController? controller,
) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return '$field is required';

  switch (field.toLowerCase()) {
    case 'first name':
    case 'middle name':
    case 'surname':
      if (!RegExp(r"^[a-zA-Z]+(?:[ '-][a-zA-Z]+)*$").hasMatch(input)) {
        return '$field can only contain letters, spaces, hyphens, and apostrophes';
      }
      break;
    case 'username':
      if (!RegExp(r'^[a-zA-Z0-9._]{3,20}$').hasMatch(input)) {
        return 'Username must be 3-20 characters and use only letters, numbers, dots, or underscores';
      }
      break;
    case 'email':
      if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(input)) {
        return 'Enter a valid email address';
      }
      break;
    case 'password':
      if (!RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
      ).hasMatch(input)) {
        return 'Password must be 8+ characters with uppercase, lowercase, number, and symbol';
      }
      break;
    case 'confirm password':
      if (input != controller?.text) return 'Passwords do not match';
      break;
  }
  return null;
}
