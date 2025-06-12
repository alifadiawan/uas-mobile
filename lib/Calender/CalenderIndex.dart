import 'package:flutter/material.dart';
import 'package:mobile_uas/widgets/CustomBottomNavBar.dart';
import 'package:table_calendar/table_calendar.dart';

class Calenderindex extends StatefulWidget {
  const Calenderindex({super.key});

  @override
  State<Calenderindex> createState() => _CalenderindexState();
}

class Event {
  final String title;
  Event(this.title);

  @override
  String toString() => title;
}

class _CalenderindexState extends State<Calenderindex> {
  // Using DateTime.utc to avoid issues with local time zones.
  DateTime _focusedDay = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {}; // Using a Map to store events

  // Example events - replace with your actual event fetching logic if needed
  final Map<DateTime, List<Event>> _sampleEvents = {
    DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day + 2,
    ): [Event('Team Meeting'), Event('Lunch with Client')],
    DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day + 5,
    ): [Event('Project Deadline')],
    DateTime.utc(DateTime.now().year, DateTime.now().month, 15): [
      Event('Doctor Appointment'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = _sampleEvents; // Initialize with sample events
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation of _getEventsForDay
    // This function will return a list of events for the given day.
    // DateTime objects used as keys in a Map must be normalized to avoid issues
    // with time components. Using DateTime.utc ensures this.
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // update `_focusedDay` here as well
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Page'),
        backgroundColor:
            Colors.indigo, // A slightly different color for the AppBar
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            // Event is now used as a type argument
            firstDay: DateTime.utc(2020, 1, 1), // First available day
            lastDay: DateTime.utc(2030, 12, 31), // Last available day
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader:
                _getEventsForDay, // Function to load events for each day
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek:
                StartingDayOfWeek.monday, // Optional: Set start of the week
            calendarStyle: CalendarStyle(
              // Customize UI
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                // Decoration for event markers
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible:
                  false, // Hide the format button (e.g., "2 weeks", "month")
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPageChanged: (focusedDay) {
              // No need to call `setState()` here
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 16.0),
          Expanded(child: _buildEventList()),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildEventList() {
    // Ensure _selectedDay is not null before accessing.
    // initState sets _selectedDay = _focusedDay, so it should be initialized.
    if (_selectedDay == null) {
      return const Center(child: Text("Please select a day."));
    }
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events for this day.',
          style: TextStyle(fontSize: 16.0, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          // Using Card for better visual separation of events
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.event, color: Colors.teal),
            title: Text(event.title),
            // You can add more details here, like event time or description
          ),
        );
      },
    );
  }
}
