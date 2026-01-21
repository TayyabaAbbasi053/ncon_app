import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../utils/colors.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

enum EventViewMode { daily, monthly, yearly }

class EventsScreen extends StatefulWidget {
  final List<Post> allPosts;
  const EventsScreen({super.key, required this.allPosts});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventViewMode _currentMode = EventViewMode.daily;
  DateTime _selectedDate = DateTime.now();
  int _displayYear = DateTime.now().year;

  // FILTER: Only include Events category
  List<Post> get _eventPosts => widget.allPosts
      .where((p) => p.category == 'Events')
      .toList();

  // HEATMAP LOGIC: Returns blue intensity based on event count
  Color _getHeatmapColor(DateTime date) {
    int count = _eventPosts.where((p) =>
    p.eventDate?.day == date.day &&
        p.eventDate?.month == date.month &&
        p.eventDate?.year == date.year).length;

    if (count == 0) return Colors.white.withOpacity(0.05);
    if (count == 1) return AppColors.electricBlue.withOpacity(0.3);
    if (count == 2) return AppColors.electricBlue.withOpacity(0.6);
    return AppColors.electricBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInternalHeader(),
        Expanded(child: _buildViewContent()),
      ],
    );
  }

  Widget _buildInternalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          // BACK BUTTON: Only shows if NOT in Yearly view
          if (_currentMode != EventViewMode.yearly)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () {
                setState(() {
                  if (_currentMode == EventViewMode.daily) _currentMode = EventViewMode.monthly;
                  else if (_currentMode == EventViewMode.monthly) _currentMode = EventViewMode.yearly;
                });
              },
            ),
          const SizedBox(width: 8),
          Text(
            _currentMode == EventViewMode.yearly ? "YEARLY VIEW" :
            _currentMode == EventViewMode.monthly ? DateFormat('MMMM').format(_selectedDate).toUpperCase() :
            "DAILY VIEW",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const Spacer(),
          // SWITCHER: Moves forward through views
          PopupMenuButton<EventViewMode>(
            icon: const Icon(Icons.calendar_month, color: AppColors.electricBlue),
            color: AppColors.surface,
            onSelected: (EventViewMode mode) => setState(() => _currentMode = mode),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<EventViewMode>>[
              const PopupMenuItem(value: EventViewMode.daily, child: Text("DAILY VIEW", style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: EventViewMode.monthly, child: Text("MONTHLY VIEW", style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: EventViewMode.yearly, child: Text("YEARLY VIEW", style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewContent() {
    switch (_currentMode) {
      case EventViewMode.yearly: return _buildYearlyView();
      case EventViewMode.monthly: return _buildMonthlyView();
      case EventViewMode.daily: return _buildDailyView();
    }
  }

  // --- YEARLY VIEW (Heatmap dots) ---
  Widget _buildYearlyView() {
    return Column(
      children: [
        // Year Selector Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.electricBlue),
                onPressed: () => setState(() => _displayYear--),
              ),
              Text(
                "$_displayYear",
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.electricBlue),
                onPressed: () => setState(() => _displayYear++),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: 12,
            itemBuilder: (context, monthIdx) {
              final month = monthIdx + 1;
              final firstDay = DateTime(_displayYear, month, 1);
              final weekdayOffset = firstDay.weekday % 7;
              final daysInMonth = DateUtils.getDaysInMonth(_displayYear, month);

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = DateTime(_displayYear, month, 1);
                  _currentMode = EventViewMode.monthly;
                }),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM').format(DateTime(_displayYear, month)).toUpperCase(),
                      style: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7, crossAxisSpacing: 2, mainAxisSpacing: 2),
                        // 3. TOTAL ITEMS = Offset + Days
                        itemCount: daysInMonth + weekdayOffset,
                        itemBuilder: (ctx, dayIdx) {
                          // If current index is less than the offset, it's an empty space
                          if (dayIdx < weekdayOffset) {
                            return const SizedBox.shrink();
                          }

                          // Calculate the actual day number (1, 2, 3...)
                          final actualDay = dayIdx - weekdayOffset + 1;

                          return Container(
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(DateTime(_displayYear, month, actualDay)),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- MONTHLY VIEW (Calendar Grid) ---
  Widget _buildMonthlyView() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final weekdayOffset = firstDay.weekday % 7; // Sunday start = 0

    return Column(
      children: [
        // Weekday Labels (S M T W T F S)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) =>
                Text(d, style: const TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w900, fontSize: 12))
            ).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: daysInMonth + weekdayOffset,
            itemBuilder: (context, index) {
              if (index < weekdayOffset) return const SizedBox.shrink();

              final dayNum = index - weekdayOffset + 1;
              final day = DateTime(_selectedDate.year, _selectedDate.month, dayNum);

              return GestureDetector(
                onTap: () => setState(() { _selectedDate = day; _currentMode = EventViewMode.daily; }),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(day),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Text("$dayNum",
                        style: TextStyle(
                            color: day.day == DateTime.now().day && day.month == DateTime.now().month ? AppColors.electricYellow : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- DAILY VIEW (Timeline) ---
  Widget _buildDailyView() {
    final dailyEvents = _eventPosts.where((p) =>
    p.eventDate?.day == _selectedDate.day &&
        p.eventDate?.month == _selectedDate.month &&
        p.eventDate?.year == _selectedDate.year).toList();

    return ListView(
      children: [
        _buildBigDateHeader(),
        if (dailyEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(60),
            child: Center(child: Text("NO EVENTS SCHEDULED", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900))),
          ),
        ...dailyEvents.map((post) => PostCard(
            post: post,
            onTap: () {
              // THE FIX: Navigation to detail screen
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))
              );
            }
        )),
      ],
    );
  }

  Widget _buildBigDateHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.electricBlue,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.white10, offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text("${_selectedDate.day}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.black)),
          ),
          const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEEE').format(_selectedDate).toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                  Text(DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}