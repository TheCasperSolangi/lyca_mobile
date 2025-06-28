import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  
  final Map<DateTime, List<Event>> _events = {
    DateTime(2025, 5, 15): [
      Event('Team Meeting', 'Team sync-up at 10:00 AM', Colors.blue),
    ],
    DateTime(2025, 5, 18): [
      Event('Lunch with Sarah', 'At Bistro Garden, 12:30 PM', Colors.orange),
      Event('Gym Session', 'Strength training, 6:00 PM', Colors.green),
    ],
    DateTime(2025, 5, 20): [
      Event('Project Deadline', 'Submit final report', Colors.red),
    ],
    DateTime(2025, 5, 25): [
      Event('Alex\'s Birthday', 'Don\'t forget the gift!', Colors.purple),
    ],
  };

  List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _weekDays = DateFormat.E().dateSymbols.SHORTWEEKDAYS.sublist(1)..add(DateFormat.E().dateSymbols.SHORTWEEKDAYS[0]);
    _months = DateFormat.MMMM().dateSymbols.MONTHS;
  }

  void _onPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasEvents(DateTime day) {
    return _events.keys.any((eventDay) => _isSameDay(eventDay, day));
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events.entries
        .where((entry) => _isSameDay(entry.key, day))
        .map((entry) => entry.value)
        .expand((events) => events)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendar(),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _onPreviousMonth,
            icon: const Icon(Icons.chevron_left, size: 28),
            color: Colors.black54,
            tooltip: 'Previous month',
          ),
          Text(
            '${_months[_focusedDate.month - 1]} ${_focusedDate.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: _onNextMonth,
            icon: const Icon(Icons.chevron_right, size: 28),
            color: Colors.black54,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    
    // Adjust weekday to start from Monday (1) to Sunday (7)
    final adjustedFirstWeekday = firstWeekdayOfMonth == 7 ? 0 : firstWeekdayOfMonth;
    
    // Calculate total cells needed (days + empty cells for previous month)
    final int totalCells = daysInMonth + adjustedFirstWeekday;
    final int totalRows = (totalCells / 7).ceil();

    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Weekday headers
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final bool isWeekend = index >= 5;
                  return SizedBox(
                    width: 40,
                    child: Text(
                      _weekDays[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isWeekend ? Colors.black45 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
            
            // Calendar grid
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1.0,
                ),
                itemCount: totalRows * 7,
                itemBuilder: (context, index) {
                  // Calculate the day number
                  final int dayNumber = index + 1 - adjustedFirstWeekday;
                  
                  // If the cell is before the 1st of the month or after the last day
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  
                  final currentDate = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
                  final isToday = _isSameDay(currentDate, DateTime.now());
                  final isSelected = _isSameDay(currentDate, _selectedDate);
                  final hasEvent = _hasEvents(currentDate);
                  
                  return GestureDetector(
                    onTap: () => _onDaySelected(currentDate),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6750A4) : 
                               isToday ? const Color(0xFFEADDFF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.white : 
                                     isToday ? const Color(0xFF6750A4) : Colors.black87,
                            ),
                          ),
                          if (hasEvent)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFF6750A4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final eventsList = _getEventsForDay(_selectedDate);
    
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                DateFormat('EEEE, d MMMM').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: eventsList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events for this day',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: eventsList.length,
                      itemBuilder: (context, index) {
                        final event = eventsList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: event.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              event.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String title;
  final String description;
  final Color color;

  Event(this.title, this.description, this.color);
}