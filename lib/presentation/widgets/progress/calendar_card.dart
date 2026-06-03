import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class CalendarCard extends StatefulWidget {
  final CalendarData calendarData;

  const CalendarCard({super.key, required this.calendarData});

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _currentMonth;

  DateTime _monthOnly(DateTime date) => DateTime(date.year, date.month);

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime get _minMonth {
    if (widget.calendarData.days.isEmpty) {
      return _monthOnly(widget.calendarData.currentMonth);
    }

    final firstDate = widget.calendarData.days
        .map((d) => d.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _monthOnly(firstDate);
  }

  DateTime get _maxMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.calendarData.currentMonth;
  }

  void _changeMonth(int delta) {
    final candidate = DateTime(_currentMonth.year, _currentMonth.month + delta);
    final candidateMonth = _monthOnly(candidate);

    if (candidateMonth.isBefore(_minMonth) || candidateMonth.isAfter(_maxMonth)) {
      return;
    }

    setState(() {
      _currentMonth = candidateMonth;
    });
  }

  List<CalendarDay> _generateCalendarDaysForMonth(DateTime month) {
    final days = <CalendarDay>[];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final prevMonthLastDay = DateTime(month.year, month.month, 0);

    // determine account range from provided calendar data
    DateTime? firstRecordedDate;
    DateTime? lastRecordedDate;
    if (widget.calendarData.days.isNotEmpty) {
      firstRecordedDate = widget.calendarData.days
          .map((d) => d.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      lastRecordedDate = widget.calendarData.days
          .map((d) => d.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Previous month padding (out-of-account range -> blank)
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(
        CalendarDay(
          date: DateTime(
            prevMonthLastDay.year,
            prevMonthLastDay.month,
            prevMonthLastDay.day - i + 1,
          ),
          status: DayStatus.blank,
        ),
      );
    }

    // Current month days
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);

      // If outside recorded account range, mark as blank
      if ((firstRecordedDate != null && date.isBefore(firstRecordedDate)) ||
          (lastRecordedDate != null && date.isAfter(lastRecordedDate))) {
        days.add(CalendarDay(date: date, status: DayStatus.blank));
        continue;
      }

      final status = widget.calendarData.days
          .firstWhere(
            (d) =>
                d.date.year == date.year &&
                d.date.month == date.month &&
                d.date.day == date.day,
            orElse: () => CalendarDay(date: date, status: DayStatus.inactive),
          )
          .status;

      days.add(CalendarDay(date: date, status: status));
    }

    // Next month padding
    final totalDaysSoFar = days.length;
    final daysToAdd = totalDaysSoFar <= 35
        ? 35 - totalDaysSoFar
        : (() {
            final needed = 42 - totalDaysSoFar;
            return (needed == 1 || needed == 2) ? 0 : needed;
          })();

    for (int day = 1; day <= daysToAdd; day++) {
      days.add(
        CalendarDay(
          date: DateTime(month.year, month.month + 1, day),
          status: DayStatus.blank,
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    final canGoPrev = !_isSameMonth(_currentMonth, _minMonth);
    final canGoNext = !_isSameMonth(_currentMonth, _maxMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: canGoPrev ? () => _changeMonth(-1) : null,
                color: theme.colorScheme.primary,
              ),
              Text(
                monthName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: canGoNext ? () => _changeMonth(1) : null,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakItem(
                context,
                label: "This month's streak",
                value: '${widget.calendarData.thisMonthStreak} days',
              ),
              _buildStreakItem(
                context,
                label: 'Longest Streak',
                value: '${widget.calendarData.longestStreak} days',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(
            context,
            _generateCalendarDaysForMonth(_currentMonth),
          ),
          const SizedBox(height: 16),
          Text(
            'To keep your streak as an Achievian, dedicate at least 1 hour a day using the app. Consistent daily review builds habits, sharpens knowledge, and brings you closer to your goal.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, List<CalendarDay> days) {
    final theme = Theme.of(context);
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                children: weekDays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) =>
                    _buildDayCell(context, days[index]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStreakBar(context, widget.calendarData.thisMonthStreak),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, CalendarDay day) {
    final theme = Theme.of(context);
    final (backgroundColor, textColor, svgPath) = _getDayStyle(day.status);
    final showDayNumber = day.status == DayStatus.inactive || day.status == DayStatus.blank;
    final hasSvg = svgPath != null;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: hasSvg
            ? null
            : Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (svgPath != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SvgPicture.asset(
                  svgPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (showDayNumber)
            Positioned(
              top: 2,
              left: 2,
              child: Text(
                '${day.date.day}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color, String?) _getDayStyle(DayStatus status) {
    switch (status) {
      case DayStatus.completed:
        // Logged-in day
        return (
          Colors.transparent,
          Colors.white,
          'assets/images/LOGO/16.svg',
        );
      case DayStatus.current:
      case DayStatus.upcoming:
        // Active/current-like days without SVG
        return (
          Colors.transparent,
          const Color(0xFF455267),
          null,
        );
      case DayStatus.inactive:
        // In-account but not active -> show small inactive SVG
        return (
          Colors.transparent,
          Colors.white,
          'assets/images/LOGO/2.svg',
        );
      case DayStatus.blank:
        // Padding/out-of-account-range
        return (
          const Color(0xFFE6E8EE),
          const Color(0xFF8F96A3),
          null,
        );
    }
  }

  Widget _buildStreakBar(BuildContext context, int streakDays) {
    final theme = Theme.of(context);
    const maxVisualStreak = 20;
    final normalizedStreak = streakDays.clamp(0, maxVisualStreak);
    final height = (normalizedStreak / maxVisualStreak) * 200.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 200,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2E86),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF009DC5), width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$streakDays',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
