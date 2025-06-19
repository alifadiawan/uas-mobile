import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:mobile_uas/widgets/CustomBottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

// --- UPDATED EVENT MODEL ---
class Event {
  final int id;
  final String title;
  final DateTime eventDate;
  final String userId; // Add userId field

  Event({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.userId,
  });

  @override
  String toString() => title;
}

class Calenderindex extends StatefulWidget {
  const Calenderindex({super.key});

  @override
  State<Calenderindex> createState() => _CalenderindexState();
}

class _CalenderindexState extends State<Calenderindex> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<Event>> _selectedEvents;
  // Use LinkedHashMap to preserve the order of insertion
  LinkedHashMap<DateTime, List<Event>> _events =
      LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // --- 1. READ: Fetch events from Supabase ---
  Future<void> _fetchEvents() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final response = await Supabase.instance.client
          .from('events')
          .select('id, title, event_date, user_id')
          .eq('user_id', currentUser.id) // Filter by current user
          .order('event_date', ascending: true);

      final LinkedHashMap<DateTime, List<Event>> fetchedEvents = LinkedHashMap(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      );

      for (final item in response) {
        final eventDate = DateTime.parse(item['event_date']);
        final normalizedDate = DateTime.utc(
          eventDate.year,
          eventDate.month,
          eventDate.day,
        );
        final event = Event(
          id: item['id'],
          title: item['title'],
          eventDate: eventDate,
          userId: item['user_id'], // Use user_id from the response
        );

        if (fetchedEvents[normalizedDate] == null) {
          fetchedEvents[normalizedDate] = [];
        }
        fetchedEvents[normalizedDate]!.add(event);
      }

      if (mounted) {
        setState(() {
          _events = fetchedEvents;
          _loading = false;
        });
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
    } catch (e) {
      print('Error fetching events: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- 2. CREATE: Add a new event to Supabase ---
  Future<void> _addEvent(String title) async {
    if (title.isEmpty || _selectedDay == null) return;

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final response = await Supabase.instance.client
          .from('events')
          .insert({
            'title': title,
            'event_date': _selectedDay!.toIso8601String(),
            'user_id': currentUser.id,  // Add user_id
          })
          .select()
          .single();

      final newEvent = Event(
        id: response['id'],
        title: response['title'],
        eventDate: DateTime.parse(response['event_date']),
        userId: response['user_id'],
      );

      final dayEvents = _events[_selectedDay!] ?? [];
      dayEvents.add(newEvent);
      setState(() {
        _events[_selectedDay!] = dayEvents;
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    } catch (e) {
      print('Error adding event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- 3. DELETE: Remove an event from Supabase ---
  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('events').delete().match({
        'id': event.id,
      });

      // Update local state immediately
      final dayEvents = _events[_selectedDay!] ?? [];
      dayEvents.removeWhere((e) => e.id == event.id);
      setState(() {
        if (dayEvents.isEmpty) {
          _events.remove(_selectedDay!);
        } else {
          _events[_selectedDay!] = dayEvents;
        }
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    } catch (e) {
      print('Error deleting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
      }
    }
  }

  void _showAddEventDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Event'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Event Title'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addEvent(controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // --- ADD FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.grey.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildTableCalendar(theme),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(height: 1),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(child: _buildEventList(theme)),
                ],
              ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildTableCalendar(ThemeData theme) {
    // Styling code is unchanged, so it's kept as is.
    final isDarkMode = theme.brightness == Brightness.dark;
    return TableCalendar<Event>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      eventLoader: _getEventsForDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.iconTheme.color,
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: theme.colorScheme.primary),
        selectedDecoration: BoxDecoration(
          color: isDarkMode ? theme.colorScheme.primary : Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        weekendTextStyle: TextStyle(
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        defaultTextStyle: TextStyle(
          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade900,
        ),
        markerDecoration: BoxDecoration(
          color:
              isDarkMode
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        markerSize: 5,
        markersAlignment: Alignment.bottomCenter,
        outsideDaysVisible: false,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.grey.shade600),
        weekendStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildEventList(ThemeData theme) {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: _selectedEvents,
      builder: (context, events, _) {
        if (events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No events for this day.',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventListItem(
              event: event,
              theme: theme,
              onDelete: () => _deleteEvent(event), // Pass delete handler
            );
          },
        );
      },
    );
  }
}

class _EventListItem extends StatelessWidget {
  const _EventListItem({
    required this.event,
    required this.theme,
    required this.onDelete, // Added for delete functionality
  });

  final Event event;
  final ThemeData theme;
  final VoidCallback onDelete; // Added for delete functionality

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.bookmark_border, color: theme.colorScheme.primary),
        ),
        title: Text(
          event.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        // --- ADD DELETE BUTTON ---
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
