import 'package:bp_notepad/components/constants.dart';
import 'package:bp_notepad/db/alarm_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/sleep_databaseProvider.dart';
import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:async/async.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({Key key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  Map<DateTime, List> _events = {};
  final _selectedDay = DateTime.now();
  List _selectedEvents = [];

  AnimationController _animationController;
  CalendarController _calendarController;
  AsyncMemoizer _memoizer;

  // ================= GET DATA =================
  getDatabaseEvent() async {
    return _memoizer.runOnce(() async {
      Locale locale = Localizations.localeOf(context);

      Future<List> bpEvents = BpDataBaseProvider.db.getData();
      Future<List> bsEvents = BsDataBaseProvider.db.getData();
      Future<List> bmiEvents = BodyDataBaseProvider.db.getData();
      Future<List> alarmEvents = AlarmDataBaseProvider.db.getData();
      Future<List> sleepEvents = SleepDataBaseProvider.db.getData();

      List bpList = await bpEvents;
      List bsList = await bsEvents;
      List bmiList = await bmiEvents;
      List alarmList = await alarmEvents;
      List sleepList = await sleepEvents;

      // format ngày theo locale
      String formatDate(String date) {
        DateTime d = DateTime.parse(date);
        return DateFormat.yMMMMd(locale.toString()).format(d);
      }

      // thêm event vào map
      void addEvent(DateTime date, String text) {
        DateTime key = DateTime(date.year, date.month, date.day);

        _events.update(key, (value) {
          value.add(text);
          return value;
        }, ifAbsent: () => [text]);
      }

      // ===== BP =====
      for (var item in bpList) {
        DateTime d = DateTime.parse(item.date);

        addEvent(
          d,
          "${formatDate(item.date)}\n"
              "${AppLocalization.of(context).translate('sys')}${item.sbp}mmHg\n"
              "${AppLocalization.of(context).translate('dia')}${item.dbp}mmHg\n"
              "${AppLocalization.of(context).translate('heart_rate')}: ${item.hr}"
              "${AppLocalization.of(context).translate('heart_rate_subtittle')}",
        );
      }

      // ===== BS =====
      for (var item in bsList) {
        DateTime d = DateTime.parse(item.date);

        addEvent(
          d,
          "${formatDate(item.date)}\n"
              "${AppLocalization.of(context).translate('bs')} ${item.glu} mmol/L",
        );
      }

      // ===== BMI =====
      for (var item in bmiList) {
        DateTime d = DateTime.parse(item.date);

        addEvent(
          d,
          "${formatDate(item.date)}\n"
              "${AppLocalization.of(context).translate('weight')}: ${item.weight} KG\n"
              "${AppLocalization.of(context).translate('bmi')}: ${item.bmi}",
        );
      }

      // ===== ALARM =====
      for (var item in alarmList) {
        DateTime d = DateTime.parse(item.date);

        addEvent(
          d,
          "${formatDate(item.date)}\n"
              "${AppLocalization.of(context).translate('alarm_textfield_tittle1')}: ${item.medicine}\n"
              "${AppLocalization.of(context).translate('alarm_textfield_tittle2')}: ${item.dosage}",
        );
      }

      // ===== SLEEP =====
      for (var item in sleepList) {
        DateTime d = DateTime.parse(item.date);

        addEvent(
          d,
          "${formatDate(item.date)}\n"
              "${AppLocalization.of(context).translate('sleep_input_title')}: ${item.sleep}",
        );
      }

      return _events;
    });
  }

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _memoizer = AsyncMemoizer();
    _selectedEvents = [];

    _calendarController = CalendarController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  // ================= EVENTS =================
  void _onDaySelected(DateTime day, List events, List holidays) {
    setState(() {
      _selectedEvents = events ?? [];
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  AppLocalization.of(context).translate('history_page'),
                ),
              ),
            ];
          },
          body: FutureBuilder(
            future: getDatabaseEvent(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  TableCalendar(
                    locale: Localizations.localeOf(context).toString(),
                    calendarController: _calendarController,
                    events: snapshot.data,
                    initialCalendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    availableGestures: AvailableGestures.all,
                    availableCalendarFormats: const {
                      CalendarFormat.month: '',
                      CalendarFormat.week: '',
                    },
                    calendarStyle: CalendarStyle(
                      selectedColor: CupertinoColors.systemRed,
                      todayColor: Colors.red[200],
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      centerHeaderTitle: true,
                      formatButtonVisible: false,
                    ),
                    builders: CalendarBuilders(
                      markersBuilder: (context, date, events, holidays) {
                        if (events.isEmpty) return [];

                        return [
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.activeBlue,
                              ),
                              child: Center(
                                child: Text(
                                  '${events.length}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          )
                        ];
                      },
                    ),
                    onDaySelected: (date, events, holidays) {
                      _onDaySelected(date, events, holidays);
                      _animationController.forward(from: 0.0);
                    },
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      children: (_selectedEvents ?? [])
                          .map((event) => Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            event.toString(),
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}