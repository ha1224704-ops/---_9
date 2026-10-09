import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: current == 0 ? const QuranListPage() : const AzkarPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current,
        onTap: (i) => setState(() => current = i),
        selectedItemColor: Colors.green,
        backgroundColor: const Color(0xFF1E1E1E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "القرآن"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "أذكاري"),
        ],
      ),
    );
  }
}

class QuranListPage extends StatelessWidget {
  const QuranListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("القرآن الكريم - بصوت 3 قراء"), centerTitle: true, backgroundColor: const Color(0xFF1E1E1E)),
      body: ListView.builder(
        itemCount: 114,
        itemBuilder: (context, i) {
          int num = i + 1;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: const Color(0xFF1E1E1E),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green.shade900, child: Text("$num", style: const TextStyle(color: Colors.white))),
              title: Text(quran.getSurahNameArabic(num), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              subtitle: Text("${quran.getPlaceOfRevelation(num) == "Makkah" ? "مكية" : "مدنية"} - ${quran.getVerseCount(num)} آية"),
              trailing: const Icon(Icons.play_circle, color: Colors.green, size: 35),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderPage(surahNumber: num))),
            ),
          );
        },
      ),
    );
  }
}

class SurahReaderPage extends StatefulWidget {
  final int surahNumber;
  const SurahReaderPage({super.key, required this.surahNumber});
  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  bool loading = false;
  int currentVerse = 0;
  String selectedReciter = "عبد الباسط عبد الصمد";
  
  final Map<String, String> reciters = {
    "عبد الباسط عبد الصمد": "Abdul_Basit_Murattal_192kbps",
    "محمد صديق المنشاوي": "Minshawy_Murattal_128kbps",
    "ياسر الدوسري": "Yasser_Ad-Dosari_128kbps",
  };

  @override
  void initState() {
    super.initState();
    player.currentIndexStream.listen((index) {
      if (index != null) setState(() => currentVerse = index + 1);
    });
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() { isPlaying = false; currentVerse = 0; });
      }
    });
  }

  Future<void> playSurah() async {
    if (isPlaying) {
      await player.pause();
      setState(() => isPlaying = false);
      return;
    }
    if (player.audioSource != null && currentVerse > 0) {
      await player.play();
      setState(() => isPlaying = true);
      return;
    }
    setState(() => loading = true);
    try {
      int count = quran.getVerseCount(widget.surahNumber);
      String reciterCode = reciters[selectedReciter]!;
      List<AudioSource> sources = [];
      for (int i = 1; i <= count; i++) {
        String sId = widget.surahNumber.toString().padLeft(3, '0');
        String vId = i.toString().padLeft(3, '0');
        String url = "https://everyayah.com/data/$reciterCode/$sId$vId.mp3";
        sources.add(AudioSource.uri(Uri.parse(url)));
      }
      await player.setAudioSource(ConcatenatingAudioSource(children: sources));
      await player.play();
      setState(() { isPlaying = true; loading = false; currentVerse = 1; });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تأكد من الانترنت - الصوت يحتاج نت")));
    }
  }

  Future<void> changeReciter(String newReciter) async {
    await player.stop();
    setState(() { selectedReciter = newReciter; isPlaying = false; currentVerse = 0; });
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    int count = quran.getVerseCount(widget.surahNumber);
    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahNameArabic(widget.surahNumber)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          DropdownButton<String>(
            value: selectedReciter,
            underline: const SizedBox(),
            dropdownColor: const Color(0x