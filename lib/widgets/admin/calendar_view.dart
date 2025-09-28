import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // Cyprus working hours
  static const Map<int, Map<String, String>?> _workingHours = {
    DateTime.sunday: null, // Closed
    DateTime.monday: {'start': '07:00', 'end': '16:00'},
    DateTime.tuesday: {'start': '07:00', 'end': '16:00'},
    DateTime.wednesday: {'start': '07:00', 'end': '13:00'},
    DateTime.thursday: {'start': '07:00', 'end': '16:00'},
    DateTime.friday: {'start': '07:00', 'end': '16:00'},
    DateTime.saturday: {'start': '07:00', 'end': '13:00'},
  };

  bool _isWorkingDay(DateTime date) {
    return _workingHours[date.weekday] != null;
  }

  String _getWorkingHours(DateTime date) {
    final hours = _workingHours[date.weekday];
    if (hours == null) {
      return 'Closed';
    }
    return '${hours['start']} - ${hours['end']}';
  }

  List<String> _getTimeSlots(DateTime date) {
    final hours = _workingHours[date.weekday];
    if (hours == null) return [];

    final startHour = int.parse(hours['start']!.split(':')[0]);
    final endHour = int.parse(hours['end']!.split(':')[0]);

    List<String> slots = [];
    for (int hour = startHour; hour < endHour; hour += 2) {
      final startTime = '${hour.toString().padLeft(2, '0')}:00';
      final endTime = '${(hour + 2).toString().padLeft(2, '0')}:00';
      slots.add('$startTime - $endTime');
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Section
          Expanded(
            flex: 2,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Calendar',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCalendar(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Day Details Section
          Expanded(
            flex: 1,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Working Hours
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isWorkingDay(_selectedDate)
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isWorkingDay(_selectedDate)
                              ? Colors.green[200]!
                              : Colors.red[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isWorkingDay(_selectedDate)
                                ? Icons.access_time
                                : Icons.close,
                            color: _isWorkingDay(_selectedDate)
                                ? Colors.green[700]
                                : Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getWorkingHours(_selectedDate),
                              style: TextStyle(
                                color: _isWorkingDay(_selectedDate)
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isWorkingDay(_selectedDate)) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Available Time Slots',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getTimeSlots(_selectedDate).length,
                          itemBuilder: (context, index) {
                            final slot = _getTimeSlots(_selectedDate)[index];
                            final isBooked = false; // TODO: Check actual bookings

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(slot),
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isBooked ? Colors.red : Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                trailing: Text(
                                  isBooked ? 'Booked' : 'Available',
                                  style: TextStyle(
                                    color: isBooked ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                tileColor: Colors.grey[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),

        // Calendar grid
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex + 1 - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final isWorkingDay = _isWorkingDay(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryTeal
                          : isToday
                              ? AppTheme.primaryTeal.withValues(alpha: 0.3)
                              : null,
                      border: Border.all(
                        color: isWorkingDay ? Colors.green[300]! : Colors.red[300]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppTheme.primaryTeal
                                  : Colors.grey[800],
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}