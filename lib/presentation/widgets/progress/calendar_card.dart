import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarCard extends StatefulWidget {
  final CalendarData calendarData;

  const CalendarCard({super.key, required this.calendarData});

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.calendarData.currentMonth;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  List<CalendarDay> _generateCalendarDaysForMonth(DateTime month) {
    final days = <CalendarDay>[];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final prevMonthLastDay = DateTime(month.year, month.month, 0);
    final isOriginalMonth =
        month.year == widget.calendarData.currentMonth.year &&
        month.month == widget.calendarData.currentMonth.month;

    // Previous month padding
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(
        CalendarDay(
          date: DateTime(
            prevMonthLastDay.year,
            prevMonthLastDay.month,
            prevMonthLastDay.day - i + 1,
          ),
          status: DayStatus.inactive,
        ),
      );
    }

    // Current month days
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final status = isOriginalMonth
          ? widget.calendarData.days
                .firstWhere(
                  (d) =>
                      d.date.year == date.year &&
                      d.date.month == date.month &&
                      d.date.day == date.day,
                  orElse: () =>
                      CalendarDay(date: date, status: DayStatus.inactive),
                )
                .status
          : (day <= 17
                ? DayStatus.completed
                : day <= 19
                ? DayStatus.current
                : DayStatus.inactive);
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
          status: DayStatus.inactive,
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

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
                onPressed: () => _changeMonth(-1),
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
                onPressed: () => _changeMonth(1),
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
    final (backgroundColor, textColor, logo) = _getDayStyle(theme, day.status);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (day.status == DayStatus.completed && logo != null)
            ClipRRect(borderRadius: BorderRadius.circular(4), child: logo),
          Text(
            '${day.date.day}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontSize: 10,
              fontWeight:
                  day.status == DayStatus.completed ||
                      day.status == DayStatus.current ||
                      day.status == DayStatus.upcoming
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          if (logo != null && day.status != DayStatus.completed)
            Positioned(bottom: 2, child: logo),
        ],
      ),
    );
  }

  (Color, Color, Widget?) _getDayStyle(ThemeData theme, DayStatus status) {
    switch (status) {
      case DayStatus.completed:
        return (
          Colors.transparent,
          Colors.white,
          Image.asset(
            'assets/images/logo.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      case DayStatus.current:
      case DayStatus.upcoming:
        return (
          Colors.white,
          theme.colorScheme.primary,
          Text(
            'AX',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          ),
        );
      case DayStatus.inactive:
        return (
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          null,
        );
    }
  }

  Widget _buildStreakBar(BuildContext context, int streakDays) {
    final theme = Theme.of(context);
    final height = (streakDays / 31) * 200.0;

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
              const Positioned(
                bottom: 4,
                child: Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
