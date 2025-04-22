import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

ValueNotifier<Map<String, String>> emotionDataNotifier = ValueNotifier({});

// 날짜를 yyyy-MM-dd 형식으로 포맷하는 함수
String formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 초기화
  await initializeDateFormatting('ko_KR', null); // 한글 날짜 포맷 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: CalendarScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _mostFrequentEmotion = '보통';

  @override
  void initState(){
    super.initState();
    _loadEmotionData(); // 앱 실행 시 감정 데이터 불러오기
    _debugPrintAppDir(); // 콘솔에 경로 출력

    emotionDataNotifier.addListener((){
      print('감정 데이터 변경됨: ${emotionDataNotifier.value}');
      setState(() {
        _mostFrequentEmotion = getMostFrequentEmotion(emotionDataNotifier.value);
      });
    });
  }

  Future<void> _loadEmotionData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('emotionData');
    print('불러온 JSON 문자열: $jsonString');

    if (jsonString != null) {
      final data = Map<String, String>.from(json.decode(jsonString));
      emotionDataNotifier.value = data;
      _mostFrequentEmotion = getMostFrequentEmotion(data);
    }
  }
  void _debugPrintAppDir() async {
    final dir = await getApplicationSupportDirectory();
    print('🗂️ 앱 저장 경로: ${dir.path}');
  }

  String getMostFrequentEmotion(Map<String, String>data) {
    Map<String, int> count = {
      '기분 좋음' : 0,
      '보통' : 0,
      '기분 안 좋음' : 0,
    };

    for (var value in data.values) {
      if (count.containsKey(value)) {
        count[value] = count[value]! + 1;
      }
    }

    // 최대 빈도 찾기
    int maxCount = count.values.fold(0, (prev, curr) => curr > prev ? curr : prev);
    final maxEmotions = count.entries.where((e) => e.value == maxCount).map((e) => e.key).toList();

    // 동점일 경우 '보통'으로
    if (maxEmotions.length != 1) return '모든 감정이 비슷하게 선택되었어요';

    return maxEmotions.first;
  }

  String getEmotionEmoji(String emotion) {
    switch (emotion) {
      case '기분 좋음':
        return '😊';
      case '보통':
        return '😐';
      case '기분 안 좋음':
        return '😞';
      case '모든 감정이 비슷하게 선택되었어요':
        return '🤷';
      default:
        return '';
    }
  }

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('시니어 마음일기'),
        actions: [
          IconButton(
            icon: Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmotionStatsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 감정 최빈값 상단 표시
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
              Text(
              '가장 자주 느낀 감정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
              Text(
                getEmotionEmoji(_mostFrequentEmotion),
                style: const TextStyle(fontSize: 36),
              ),
              ],
            ),
          ),

      // 캘린더
      ValueListenableBuilder(
            valueListenable: emotionDataNotifier,
            builder: (context, emotionMap, _){
              return TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,

                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
                calendarStyle: CalendarStyle(
                  disabledTextStyle: TextStyle(color: Colors.grey), // 미래는 회색
                ),
                onDaySelected: (selectedDay, focusedDay) async {
                  if (selectedDay.isAfter(DateTime.now())) return; // 미래면 클릭 무시

                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  // 감정 입력 화면 다녀오기
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmotionInputScreen(selectedDay: selectedDay),
                    ),
                  );

                  // 데이터 다시 불러오기
                  await _loadEmotionData();

                  // 강제로 selectedDay를 한번 무효화했다가 다시 설정
                  setState(() {
                    _selectedDay = null;
                  });

                  Future.delayed(Duration(milliseconds: 50), () {
                    setState(() {
                      _focusedDay = selectedDay; // 다시 원래 날짜로 복귀해서 리렌더 유도
                    });
                  });
                },

                // 감정 이모티콘 셀
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dateStr = formatDate(day);
                    final emotion = emotionDataNotifier.value[dateStr];

                    if (emotion != null) {
                      String emoji;
                      if (emotion == '기분 좋음') emoji = '😊';
                      else if (emotion == '보통') emoji = '😐';
                      else emoji = '😞';

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${day.day}'),
                          Text(emoji),
                        ],
                      );
                    }
                    return null;
                  },

                  todayBuilder: (context, day, focusedDay) {
                    final dateStr = formatDate(day);
                    final emotion = emotionDataNotifier.value[dateStr];
                    String emoji = '';

                    if (emotion != null) {
                      if (emotion == '기분 좋음') emoji = '😊';
                      else if (emotion == '보통') emoji = '😐';
                      else emoji = '😞';
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold),
                        ),
                        if (emoji.isNotEmpty) Text(emoji),
                      ],
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class EmotionInputScreen extends StatelessWidget {
  final DateTime selectedDay;

  const EmotionInputScreen({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${selectedDay.month}월 ${selectedDay.day}일 감정 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '오늘 기분은 어땠나요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 😊 기분 좋음
            EmotionButton(
              emoji: '😊',
              label: '기분 좋음',
              color: Colors.green.shade300,
              onTap: () {
                _submitEmotion(context, selectedDay, '기분 좋음');
              },
            ),

            const SizedBox(height: 20),

            // 😐 보통
            EmotionButton(
              emoji: '😐',
              label: '보통',
              color: Colors.grey.shade400,
              onTap: () {
                _submitEmotion(context, selectedDay, '보통');
              },
            ),

            const SizedBox(height: 20),

            // 😞 기분 안 좋음
            EmotionButton(
              emoji: '😞',
              label: '기분 안 좋음',
              color: Colors.red.shade200,
              onTap: () {
                _submitEmotion(context, selectedDay, '기분 안 좋음');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitEmotion(BuildContext context, DateTime date, String emotion) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('emotionData');
    Map<String, String> data = {};
    if (jsonString != null) {
      data = Map<String, String>.from(json.decode(jsonString));
    }

    final formattedDate = formatDate(date);
    data[formattedDate] = emotion;

    print('저장되는 감정 데이터: $data');

    await prefs.setString('emotionData', json.encode(data));

    // notifier에 업데이트
    emotionDataNotifier = ValueNotifier<Map<String, String>>(Map<String, String>.from(data));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$emotion 으로 저장되었습니다.')),
    );

    Navigator.pop(context); // 이전 화면으로 돌아가기
  }
}

class EmotionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const EmotionButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class EmotionStatsScreen extends StatelessWidget {
  const EmotionStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('감정 통계'),
      ),
      body: Center(
        child: Text(
          '여기에 감정 통계 그래프가 표시됩니다.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}