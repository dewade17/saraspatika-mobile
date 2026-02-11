import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarKehadiran<T> extends StatefulWidget {
  final DateTime? selectedDay;
  final ValueChanged<DateTime?>? onDaySelected;
  final ValueChanged<DateTime>? onMonthChanged;
  final List<T> items;
  final DateTime? Function(T item) getStartDate;
  final DateTime? Function(T item) getEndDate;

  const CalendarKehadiran({
    super.key,
    this.selectedDay,
    this.onDaySelected,
    this.onMonthChanged,
    this.items = const [],
    required this.getStartDate,
    required this.getEndDate,
  });

  @override
  State<CalendarKehadiran<T>> createState() => _CalendarKehadiranState<T>();
}

class _CalendarKehadiranState<T> extends State<CalendarKehadiran<T>>
    with TickerProviderStateMixin {
  static final DateTime _firstDay = DateTime(2000, 1, 1);
  static final DateTime _lastDay = DateTime(2100, 12, 31);

  late DateTime _focused;
  bool _expanded = false;
  DateTime? _selected;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedDay;
    _focused = _selected ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant CalendarKehadiran<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.selectedDay, widget.selectedDay)) {
      setState(() {
        _selected = widget.selectedDay;
        if (_selected != null) {
          _focused = _selected!;
        }
      });
    }
  }

  String get _bulanTahun => DateFormat.yMMMM('id_ID').format(_focused);

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<T> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalize(day);
    final events = <T>[];

    for (final item in widget.items) {
      final startRaw = widget.getStartDate(item);
      if (startRaw == null) continue;

      final start = _normalize(startRaw);
      final endRaw = widget.getEndDate(item);
      final end = endRaw != null ? _normalize(endRaw) : start;

      final inRange =
          (normalizedDay.isAtSameMomentAs(start) ||
              normalizedDay.isAfter(start)) &&
          (normalizedDay.isAtSameMomentAs(end) || normalizedDay.isBefore(end));

      if (inRange) events.add(item);
    }

    return events;
  }

  void _shiftFocusedMonth(int delta) {
    final nextFocused = DateTime(_focused.year, _focused.month + delta, 1);
    setState(() => _focused = nextFocused);
    widget.onMonthChanged?.call(nextFocused);
  }

  void _goPrev() {
    if (_pageController?.hasClients ?? false) {
      _pageController!.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    _shiftFocusedMonth(-1);
  }

  void _goNext() {
    if (_pageController?.hasClients ?? false) {
      _pageController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    _shiftFocusedMonth(1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goPrev,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _bulanTahun,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _goNext,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TableCalendar<T>(
                      firstDay: _firstDay,
                      lastDay: _lastDay,
                      focusedDay: _focused,
                      selectedDayPredicate: (day) => isSameDay(_selected, day),
                      locale: 'id_ID',
                      eventLoader: _getEventsForDay,
                      calendarFormat: CalendarFormat.month,
                      headerVisible: false,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      onCalendarCreated: (controller) =>
                          _pageController = controller,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          if (isSameDay(_selected, selectedDay)) {
                            _selected = null;
                          } else {
                            _selected = selectedDay;
                          }
                          _focused = focusedDay;
                        });
                        widget.onDaySelected?.call(_selected);
                      },
                      onPageChanged: (focusedDay) {
                        setState(() => _focused = focusedDay);
                        widget.onMonthChanged?.call(focusedDay);
                      },
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        isTodayHighlighted: true,
                        todayDecoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
