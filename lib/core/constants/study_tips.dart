import 'package:flutter/material.dart';

/// One tip on the About > Study Tips page.
class StudyTip {
  final String title;
  final String description;
  final IconData icon;

  /// Drawn instead of [icon] when set (the "Aa" of the terminology tip).
  final String? iconText;

  const StudyTip({
    required this.title,
    required this.description,
    required this.icon,
    this.iconText,
  });
}

/// The "Be Our First Batch of Topnotchers" banner at the top of Study Tips.
const studyTipsBanner = 'assets/images/study_tips_banner.png';

const studyTipsReminder =
    'Every question answered, every concept mastered, and every study '
    'session completed brings you one step closer to becoming a topnotcher. '
    'Keep going, Achievian!';

const studyTips = <StudyTip>[
  StudyTip(
    title: 'Start with Mother Notes',
    description:
        'Build a strong foundation by understanding essential concepts '
        'before answering practice questions.',
    icon: Icons.menu_book_outlined,
  ),
  StudyTip(
    title: 'Master One Subject at a Time',
    description:
        'Use the Question Bank to focus on specific topics and strengthen '
        'your understanding before moving on.',
    icon: Icons.article_outlined,
  ),
  StudyTip(
    title: "Understand, Don't Just Memorize",
    description:
        'Read the rationale after every question, even when your answer is '
        'correct, so you know why it is right.',
    icon: Icons.lightbulb_outline,
  ),
  StudyTip(
    title: 'Learn from Your Mistakes',
    description:
        'Revisit the questions you missed until you can confidently explain '
        'the correct answer.',
    icon: Icons.track_changes,
  ),
  StudyTip(
    title: 'Use the "I Already Know" Feature Wisely',
    description:
        'Mark a question as known only when you truly understand the concept '
        'behind it, not just the answer.',
    icon: Icons.check_circle_outline,
  ),
  StudyTip(
    title: 'Study Smarter with Mnemonics',
    description:
        'Use memory aids to remember difficult classifications, laboratory '
        'values, and important concepts.',
    icon: Icons.psychology_outlined,
  ),
  StudyTip(
    title: 'Stay Focused with Pomodoro',
    description:
        'Study in focused sessions and take scheduled breaks to keep your '
        'concentration sharp.',
    icon: Icons.timer_outlined,
  ),
  StudyTip(
    title: 'Track Your Subject Performance',
    description:
        'Check your progress regularly to identify weak areas and give them '
        'the attention they need.',
    icon: Icons.bar_chart,
  ),
  StudyTip(
    title: 'Practice Under Exam Conditions',
    description:
        'Take timed exams to build your accuracy, speed, and confidence for '
        'the real board exam.',
    icon: Icons.assignment_outlined,
  ),
  StudyTip(
    title: 'Take Mock Boards Seriously',
    description:
        'Simulate the actual board exam, review your results, and identify '
        'the areas that need further preparation.',
    icon: Icons.fact_check_outlined,
  ),
  StudyTip(
    title: 'Use the Mark Feature',
    description:
        'Flag difficult or uncertain questions during Mock Boards so you can '
        'revisit them before submitting.',
    icon: Icons.bookmark_border,
  ),
  StudyTip(
    title: 'Make Every Day Count',
    description:
        'Answer the Question of the Day, set a realistic daily goal, and keep '
        'a steady study routine.',
    icon: Icons.calendar_today_outlined,
  ),
  StudyTip(
    title: 'Strengthen Your Medical Terminology',
    description:
        'Use the abbreviations and other references to become familiar with '
        'essential laboratory terms.',
    icon: Icons.text_fields,
    iconText: 'Aa',
  ),
  StudyTip(
    title: 'Measure Progress, Not Perfection',
    description:
        'Your progress matters more than perfection. Focus on steady '
        'improvement and celebrate small wins.',
    icon: Icons.trending_up,
  ),
  StudyTip(
    title: 'Make Achievia Your Study Companion',
    description:
        'Learn with Mother Notes, practice with the Question Bank, reinforce '
        'with Mnemonics, and assess yourself through Mock Boards.',
    icon: Icons.groups_outlined,
  ),
];
