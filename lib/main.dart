import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// ------------------------------------------------------------
/// DATA MODELLERİ
/// ------------------------------------------------------------

/// Kelime deposu (Kelime Öğren sekmesi)
/// tur: isim / fiil / sıfat / zarf / ifade
/// cinsiyet: m / f / n
class KelimeEntry {
  final String bos;
  final String tr;
  final String tur;
  final String? cinsiyet;
  final String? ornek;

  KelimeEntry({
    required this.bos,
    required this.tr,
    required this.tur,
    this.cinsiyet,
    this.ornek,
  });
}

/// Çoktan seçmeli soru tipleri
enum QuizMode {
  bsToTr,      // Ezber Yap: Boşnakça -> Türkçe
  trToBs,      // Ezber Yap: Türkçe -> Boşnakça
  soruZarfi,   // Soru Sor sekmesi (Gdje/Kako/Kada/Zašto...)
  padez,       // Padež Alanı (gramer)
}

/// Çoktan seçmeli soru yapısı
class QuizQuestion {
  final String prompt;        // soru metni veya kelime
  final List<String> options; // 4 şık
  final int correct;          // doğru index
  final QuizMode mode;
  final String? explanation;  // padež için açıklama

  QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correct,
    required this.mode,
    this.explanation,
  });
}

/// Boşluk doldurma sorusu
class ClozeQuestion {
  final String questionText; // "Ja pijem ____."
  final String answer;       // "vodu"
  ClozeQuestion({
    required this.questionText,
    required this.answer,
  });
}

/// Çeviri paragrafı (Admin'in eklediği çalışma metni)
class StudyParagraph {
  final String bosText; // Boşnakça/BHS orijinal
  final String trText;  // Senin doğru Türkçe çevirin
  StudyParagraph({
    required this.bosText,
    required this.trText,
  });
}

/// ------------------------------------------------------------
/// BAŞLANGIÇ (GÖMÜLÜ) VERİLER - Uygulama açıldığında cihazda var
/// ------------------------------------------------------------

List<KelimeEntry> kelimeListesi = [
  KelimeEntry(
    bos: "hljeb",
    tr: "ekmek",
    tur: "isim",
    cinsiyet: "m",
    ornek: "Ja volim svjež hljeb. (Taze ekmeği severim.)",
  ),
  KelimeEntry(
    bos: "kuća",
    tr: "ev",
    tur: "isim",
    cinsiyet: "f",
    ornek: "Ovo je moja kuća. (Bu benim evim.)",
  ),
  KelimeEntry(
    bos: "voda",
    tr: "su",
    tur: "isim",
    cinsiyet: "f",
    ornek: "Pijem vodu. (Su içiyorum.)",
  ),
  KelimeEntry(
    bos: "more",
    tr: "deniz",
    tur: "isim",
    cinsiyet: "n",
    ornek: "More je mirno. (Deniz sakin.)",
  ),
  KelimeEntry(
    bos: "brat",
    tr: "erkek kardeş",
    tur: "isim",
    cinsiyet: "m",
    ornek: "Moj brat je u školi. (Kardeşim okulda.)",
  ),
  KelimeEntry(
    bos: "sestra",
    tr: "kız kardeş",
    tur: "isim",
    cinsiyet: "f",
    ornek: "Imam sestru. (Bir kız kardeşim var.)",
  ),
  KelimeEntry(
    bos: "škola",
    tr: "okul",
    tur: "isim",
    cinsiyet: "f",
    ornek: "Idem u školu. (Okula gidiyorum.)",
  ),
  KelimeEntry(
    bos: "grad",
    tr: "şehir",
    tur: "isim",
    cinsiyet: "m",
    ornek: "Sarajevo je lijep grad. (Saraybosna güzel bir şehir.)",
  ),
  KelimeEntry(
    bos: "auto",
    tr: "araba",
    tur: "isim",
    cinsiyet: "n",
    ornek: "Imam novo auto. (Yeni bir arabam var.)",
  ),
  KelimeEntry(
    bos: "lijep",
    tr: "güzel",
    tur: "sıfat",
    cinsiyet: null,
    ornek: "To je lijep grad. (O güzel bir şehir.)",
  ),
  KelimeEntry(
    bos: "hladan",
    tr: "soğuk",
    tur: "sıfat",
    cinsiyet: null,
    ornek: "Hladan vjetar. (Soğuk rüzgar.)",
  ),
  KelimeEntry(
    bos: "pisati",
    tr: "yazmak",
    tur: "fiil",
    cinsiyet: null,
    ornek: "Moram pisati pismo. (Mektup yazmam lazım.)",
  ),
  KelimeEntry(
    bos: "čitati",
    tr: "okumak",
    tur: "fiil",
    cinsiyet: null,
    ornek: "Volim čitati knjige. (Kitap okumayı severim.)",
  ),
  KelimeEntry(
    bos: "ići",
    tr: "gitmek",
    tur: "fiil",
    cinsiyet: null,
    ornek: "Moram ići kući. (Eve gitmem lazım.)",
  ),
  KelimeEntry(
    bos: "spavati",
    tr: "uyumak",
    tur: "fiil",
    cinsiyet: null,
    ornek: "Idem spavati. (Uyumaya gidiyorum.)",
  ),
  KelimeEntry(
    bos: "dobar dan",
    tr: "iyi günler",
    tur: "ifade",
  ),
  KelimeEntry(
    bos: "laku noć",
    tr: "iyi geceler",
    tur: "ifade",
  ),
  KelimeEntry(
    bos: "hvala",
    tr: "teşekkürler",
    tur: "ifade",
  ),
  KelimeEntry(
    bos: "polako",
    tr: "yavaş / sakin",
    tur: "zarf",
    ornek: "Govori polako. (Yavaş konuş.)",
  ),
  KelimeEntry(
    bos: "sad",
    tr: "şimdi",
    tur: "zarf",
    ornek: "Sad idem. (Şimdi gidiyorum.)",
  ),
];

/// Ezber Yap soruları
List<QuizQuestion> ezberSorular = [
  QuizQuestion(
    prompt: "hljeb",
    options: ["ekmek", "deniz", "ev", "anne"],
    correct: 0,
    mode: QuizMode.bsToTr,
  ),
  QuizQuestion(
    prompt: "kuća",
    options: ["okul", "ev", "ayakkabı", "baba"],
    correct: 1,
    mode: QuizMode.bsToTr,
  ),
  QuizQuestion(
    prompt: "ekmek",
    options: ["hljeb", "more", "kuća", "voda"],
    correct: 0,
    mode: QuizMode.trToBs,
  ),
];

/// Boşluk doldur soruları
List<ClozeQuestion> boslukSorular = [
  ClozeQuestion(questionText: "Ja pijem ____.", answer: "vodu"),
  ClozeQuestion(questionText: "Idem u ____.", answer: "školu"),
  ClozeQuestion(questionText: "Ovo je ____.", answer: "kuća"),
  ClozeQuestion(questionText: "____ je velika.", answer: "kuća"),
  ClozeQuestion(questionText: "Volim ____.", answer: "hljeb"),
  ClozeQuestion(questionText: "Ovo je moj ____.", answer: "brat"),
  ClozeQuestion(questionText: "More je ____.", answer: "mirno"),
  ClozeQuestion(questionText: "Idem spavati ____.", answer: "sad"),
  ClozeQuestion(questionText: "To je ____ grad.", answer: "lijep"),
  ClozeQuestion(questionText: "Pijem ____ svaki dan.", answer: "vodu"),
];

/// Soru Sor (soru zarfı, wh-words)
List<QuizQuestion> soruZarfSorular = [
  QuizQuestion(
    prompt: "_____ živiš?",
    options: ["Gdje", "Kada", "Kako", "Zašto"],
    correct: 0,
    mode: QuizMode.soruZarfi,
  ),
  QuizQuestion(
    prompt: "_____ ideš u školu?",
    options: ["Kada", "Zašto", "Kako", "Koliko"],
    correct: 0,
    mode: QuizMode.soruZarfi,
  ),
  QuizQuestion(
    prompt: "_____ si umoran?",
    options: ["Zašto", "Gdje", "Kada", "Kako"],
    correct: 0,
    mode: QuizMode.soruZarfi,
  ),
  QuizQuestion(
    prompt: "_____ se zoveš?",
    options: ["Kako", "Gdje", "Zašto", "Kada"],
    correct: 0,
    mode: QuizMode.soruZarfi,
  ),
  QuizQuestion(
    prompt: "_____ godina imaš?",
    options: ["Koliko", "Gdje", "Kako", "Zašto"],
    correct: 0,
    mode: QuizMode.soruZarfi,
  ),
];

/// Padež soruları
List<QuizQuestion> padezSorular = [
  QuizQuestion(
    prompt: "Idem u školu. Hangi hâl?",
    options: ["Nominativ", "Akuzativ", "Genitiv", "Lokativ"],
    correct: 1,
    explanation: "u + akuzativ = nereye? (hareket yönü)",
    mode: QuizMode.padez,
  ),
  QuizQuestion(
    prompt: "Ja sam u školi. Hangi hâl?",
    options: ["Akuzativ", "Genitiv", "Lokativ", "Instrumental"],
    correct: 2,
    explanation: "u + lokativ = nerede? (konum)",
    mode: QuizMode.padez,
  ),
  QuizQuestion(
    prompt: "Nema hljeba. 'hljeba' hangi hâl?",
    options: ["Genitiv", "Lokativ", "Nominativ", "Akuzativ"],
    correct: 0,
    explanation: "Genitiv = yokluk / aitlik. 'Nema hljeba' = Ekmek yok.",
    mode: QuizMode.padez,
  ),
];

/// Çift yönlü mini sözlük (Çeviri Yap kelime kelime skor hesaplama için değil,
/// ama ileride lazım olacak diye tuttuk)
Map<String, String> dictBsToTr = {
  "hljeb": "ekmek",
  "kuća": "ev",
  "voda": "su",
  "brat": "erkek kardeş",
  "sestra": "kız kardeş",
  "škola": "okul",
  "idem": "gidiyorum",
  "danas": "bugün",
  "sa": "ile",
  "more": "deniz",
  "grad": "şehir",
};
Map<String, String> dictTrToBs = {
  "ekmek": "hljeb",
  "ev": "kuća",
  "su": "voda",
  "erkek kardeş": "brat",
  "kız kardeş": "sestra",
  "okul": "škola",
  "gidiyorum": "idem",
  "bugün": "danas",
  "ile": "sa",
  "deniz": "more",
  "şehir": "grad",
};

/// Çeviri paragraf listesi (Admin -> Çeviri tabında ekleniyor)
/// Not: Uygulama "son ekleneni" gösteriyor.
List<StudyParagraph> ceviriParagraflari = [
  StudyParagraph(
    bosText:
        "Ovo je početni paragraf. Ovo će değişecek, sen Admin'den yenisini ekleyince burası güncellenmiş olacak.",
    trText:
        "Bu bir başlangıç paragrafıdır. Admin'den yeni metin ekleyince burada en son girilen paragraf görünecek.",
  ),
];

/// ------------------------------------------------------------
/// UYGULAMA (Tema yönetimi + HomeScreen)
/// ------------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int themeIndex = 0; // 0 light, 1 dark, 2 soft

    ThemeData _buildLight() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      scaffoldBackgroundColor: const Color(0xFFF7F7F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),

      // <-- burası düzeltildi
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  ThemeData _buildDark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorSchemeSeed: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFF0F0F12),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A22),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // <-- burası düzeltildi
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E28),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  ThemeData _buildSoft() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorSchemeSeed: Colors.purpleAccent,
      scaffoldBackgroundColor: const Color(0xFFF2EEF8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFECE6FA),
        foregroundColor: Color(0xFF2F244A),
        elevation: 0,
        centerTitle: true,
      ),

      // <-- burası düzeltildi
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 1,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Color(0xFF2F244A),
        ),
      ),
    );
  }


  ThemeData _currentTheme() {
    switch (themeIndex) {
      case 1:
        return _buildDark();
      case 2:
        return _buildSoft();
      default:
        return _buildLight();
    }
  }

  void _cycleTheme() {
    setState(() {
      themeIndex = (themeIndex + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bosanski TR',
      debugShowCheckedModeBanner: false,
      theme: _currentTheme(),
      home: HomeScreen(onThemeChange: _cycleTheme),
    );
  }
}

/// ------------------------------------------------------------
/// ANA EKRAN (BottomNavigationBar)
/// ------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChange;
  const HomeScreen({super.key, required this.onThemeChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      KelimeOgrenPage(
        onOpenAdmin: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPage()),
          );
        },
      ),
      const EzberYapPage(),
      const BoslukDoldurPage(),
      const SoruSorPage(),
      const CeviriYapPage(),
      const PadezPage(),
    ];

    final titles = [
      "Kelime Öğren",
      "Ezber Yap",
      "Boşluk Doldur",
      "Soru Sor",
      "Çeviri Yap",
      "Padež Alanı",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[tabIndex],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: "Tema değiştir",
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onThemeChange,
          ),
          IconButton(
            tooltip: "Admin Paneli (Ekle)",
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPage()),
              );
            },
          ),
        ],
      ),
      body: pages[tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.menu_book), label: "Kelime Öğren"),
          NavigationDestination(icon: Icon(Icons.quiz), label: "Ezber Yap"),
          NavigationDestination(
              icon: Icon(Icons.edit_note), label: "Boşluk Doldur"),
          NavigationDestination(
              icon: Icon(Icons.help_center), label: "Soru Sor"),
          NavigationDestination(
              icon: Icon(Icons.translate), label: "Çeviri Yap"),
          NavigationDestination(
              icon: Icon(Icons.rule), label: "Padež Alanı"),
        ],
        onDestinationSelected: (i) {
          setState(() {
            tabIndex = i;
          });
        },
      ),
    );
  }
}
/// ------------------------------------------------------------
/// KELİME ÖĞREN SAYFASI
/// - Arama
/// - Tür filtresi chipleri
/// - Kartta: Boşnakça (büyük), altında Türkçesi
/// ------------------------------------------------------------
class KelimeOgrenPage extends StatefulWidget {
  final VoidCallback onOpenAdmin;
  const KelimeOgrenPage({super.key, required this.onOpenAdmin});

  @override
  State<KelimeOgrenPage> createState() => _KelimeOgrenPageState();
}

class _KelimeOgrenPageState extends State<KelimeOgrenPage> {
  String search = "";
  String kategori = "Hepsi"; // Hepsi / isim / fiil / sıfat / zarf / ifade

  @override
  Widget build(BuildContext context) {
    final filtered = kelimeListesi.where((w) {
      final fMatch = (kategori == "Hepsi") ? true : w.tur == kategori;
      final s = search.toLowerCase();
      final sMatch = w.bos.toLowerCase().contains(s) ||
          w.tr.toLowerCase().contains(s);
      return fMatch && sMatch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama kutusu
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Ara: kuća / ev ...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Kelime ekle",
                onPressed: widget.onOpenAdmin,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: (v) => setState(() => search = v),
          ),
        ),

        // Kategori chipleri
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final t in ["Hepsi", "isim", "fiil", "sıfat", "zarf", "ifade"])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: kategori == t,
                    onSelected: (_) {
                      setState(() {
                        kategori = t;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Filtrelenmiş: ${filtered.length} / Genel: ${kelimeListesi.length} kelime",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
        ),

        // Liste
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final w = filtered[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Boşnakça kelime
                      Text(
                        w.bos,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Türkçesi altında
                      Text(
                        w.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // tür / cinsiyet etiketleri
                      Row(
                        children: [
                          _tag(w.tur),
                          if (w.cinsiyet != null) const SizedBox(width: 8),
                          if (w.cinsiyet != null) _tag(_cinsiyet(w.cinsiyet!)),
                        ],
                      ),

                      // örnek cümle varsa
                      if (w.ornek != null && w.ornek!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "Örnek: ${w.ornek}",
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.grey.withOpacity(0.9),
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
    );
  }

  String _cinsiyet(String raw) {
    switch (raw) {
      case "m":
        return "Eril";
      case "f":
        return "Dişil";
      case "n":
        return "Nötr";
      default:
        return raw;
    }
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// EZBER YAP SAYFASI
/// - Çoktan seçmeli
/// - Anında Tačno / Netačno snackbar
/// - Otomatik sonraki soru
/// - Skor yukarıda
/// ------------------------------------------------------------
class EzberYapPage extends StatefulWidget {
  const EzberYapPage({super.key});

  @override
  State<EzberYapPage> createState() => _EzberYapPageState();
}

class _EzberYapPageState extends State<EzberYapPage> {
  final Random _rnd = Random();

  QuizQuestion? current;
  int correctCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    current = _nextQuestion();
  }

  QuizQuestion _nextQuestion() {
    return ezberSorular[_rnd.nextInt(ezberSorular.length)];
  }

  String _questionHeader(QuizQuestion q) {
    switch (q.mode) {
      case QuizMode.bsToTr:
        return "Boşnakça kelime:";
      case QuizMode.trToBs:
        return "Türkçe kelime:";
      default:
        return "";
    }
  }

  String _questionBody(QuizQuestion q) {
    switch (q.mode) {
      case QuizMode.bsToTr:
        return "Bu kelimenin Türkçesi nedir?";
      case QuizMode.trToBs:
        return "Bu kelimenin Boşnakçası nedir?";
      default:
        return "";
    }
  }

  void _answer(int index) {
    if (current == null) return;
    final bool isCorrect = (index == current!.correct);

    setState(() {
      totalCount++;
      if (isCorrect) correctCount++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "Tačno ✅" : "Netačno ❌"),
        duration: const Duration(milliseconds: 800),
      ),
    );

    setState(() {
      current = _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Center(child: Text("Soru yok"));
    }

    final q = current!;
    final pct =
        totalCount == 0 ? 0 : ((correctCount / totalCount) * 100).round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // skor
          Text(
            "Doğru: $correctCount / Toplam: $totalCount (%$pct)",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),

          // soru kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _questionHeader(q),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.prompt,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _questionBody(q),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // şıklar
          for (int i = 0; i < q.options.length; i++)
            Card(
              child: ListTile(
                title: Text(q.options[i]),
                onTap: () => _answer(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// BOŞLUK DOLDUR SAYFASI
/// - Cümle içinde boşluk: Ja pijem ____.
/// - Kullanıcı yazıyor
/// - Kontrol Et -> Tačno / Netačno + doğru cevap
/// - Sonra otomatik yenisine geç
/// ------------------------------------------------------------
class BoslukDoldurPage extends StatefulWidget {
  const BoslukDoldurPage({super.key});

  @override
  State<BoslukDoldurPage> createState() => _BoslukDoldurPageState();
}

class _BoslukDoldurPageState extends State<BoslukDoldurPage> {
  final Random _rnd = Random();
  final TextEditingController _ctrl = TextEditingController();

  late ClozeQuestion current;

  @override
  void initState() {
    super.initState();
    current = _nextQ();
  }

  ClozeQuestion _nextQ() {
    return boslukSorular[_rnd.nextInt(boslukSorular.length)];
  }

  void _check() {
    final guess = _ctrl.text.trim().toLowerCase();
    final ans = current.answer.trim().toLowerCase();
    final ok = (guess == ans);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Tačno ✅"
              : "Netačno ❌ / Doğru cevap: ${current.answer}",
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );

    setState(() {
      current = _nextQ();
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                current.questionText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: "Cevabın",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.check),
            label: const Text("Kontrol Et"),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// SORU SOR SAYFASI
/// - Yapı Ezber Yap gibi
/// - Şıklar soru zarfları: Gdje / Kada / Kako / Zašto
/// - Türkçe şık YOK artık (sen öyle istedin)
/// ------------------------------------------------------------
class SoruSorPage extends StatefulWidget {
  const SoruSorPage({super.key});

  @override
  State<SoruSorPage> createState() => _SoruSorPageState();
}

class _SoruSorPageState extends State<SoruSorPage> {
  final Random _rnd = Random();

  QuizQuestion? current;
  int dogruSay = 0;
  int toplamSay = 0;

  @override
  void initState() {
    super.initState();
    current = _nextQuestion();
  }

  QuizQuestion _nextQuestion() {
    return soruZarfSorular[_rnd.nextInt(soruZarfSorular.length)];
  }

  void _answer(int i) {
    if (current == null) return;
    final bool isCorrect = (i == current!.correct);

    setState(() {
      toplamSay++;
      if (isCorrect) dogruSay++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "Tačno ✅" : "Netačno ❌"),
        duration: const Duration(milliseconds: 800),
      ),
    );

    setState(() {
      current = _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Center(child: Text("Soru yok"));
    }

    final q = current!;
    final pct =
        toplamSay == 0 ? 0 : ((dogruSay / toplamSay) * 100).round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Doğru: $dogruSay / Toplam: $toplamSay (%$pct)",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                q.prompt,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),

          for (int i = 0; i < q.options.length; i++)
            Card(
              child: ListTile(
                title: Text(q.options[i]),
                onTap: () => _answer(i),
              ),
            ),
        ],
      ),
    );
  }
}
/// ------------------------------------------------------------
/// ÇEVİRİ YAP SAYFASI
///
/// - bsToTr = true ise:
///   Üstte Boşnakça metin gösterilir, kullanıcı altta Türkçe çeviri yazar.
///   Doğrulama yaparken hocanın Türkçe metniyle kıyaslar.
/// - bsToTr = false ise tam tersi.
///
/// - "Kontrol Et" tıklayınca:
///   Kelime bazlı basit eşleşme -> Doğru / Toplam / %Başarı ve
///   yanlış görülen kelimeler listesi.
/// - Kullanıcının cevabı + skor kartı ekranda kalır.
/// - En son Admin'de eklenmiş paragrafı gösterir (ceviriParagraflari.last).
/// ------------------------------------------------------------
class CeviriYapPage extends StatefulWidget {
  const CeviriYapPage({super.key});

  @override
  State<CeviriYapPage> createState() => _CeviriYapPageState();
}

class _CeviriYapPageState extends State<CeviriYapPage> {
  bool bsToTr = true; // true: Boşnakça -> Türkçe, false: Türkçe -> Boşnakça
  final TextEditingController _cevapCtrl = TextEditingController();

  // son sonuçları aşağıda göstermek için
  String _lastUserAnswer = "";
  String _lastScoreText = "";

  StudyParagraph get aktifParagraf => ceviriParagraflari.isNotEmpty
      ? ceviriParagraflari.last
      : StudyParagraph(
          bosText: "Paragraf yok. Admin panelinden Çeviri sekmesine metin ekle.",
          trText: "Paragraf yok. Admin panelinden Çeviri sekmesine metin ekle.",
        );

  void _toggleMode() {
    setState(() {
      bsToTr = !bsToTr;
      _lastUserAnswer = "";
      _lastScoreText = "";
      _cevapCtrl.clear();
    });
  }

  // kelime bazlı basit puanlama
  Map<String, dynamic> _hesaplaSkor({
    required String userAnswer,
    required String dogruMetin,
  }) {
    // normalize et: noktalama ve büyük-küçük farkını sil
    final cleanUser = userAnswer
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');
    final cleanTrue = dogruMetin
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');

    final userWords = cleanUser
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final trueWords = cleanTrue
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    int correct = 0;
    final wrongWords = <String>[];

    for (final w in userWords) {
      if (trueWords.contains(w)) {
        correct++;
      } else {
        wrongWords.add(w);
      }
    }

    final total = userWords.length;
    final pct = total == 0 ? 0 : ((correct / total) * 100).round();

    return {
      "correct": correct,
      "total": total,
      "pct": pct,
      "wrong": wrongWords,
    };
  }

  void _kontrolEt() {
    final girilen = _cevapCtrl.text.trim();
    if (girilen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cevabını yazmadın ❌"),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    // Hangi taraf referans olacak?
    // bsToTr TRUE ise:
    //   kullanıcı TR yazıyor, doğru cevap = aktifParagraf.trText
    // bsToTr FALSE ise:
    //   kullanıcı BS yazıyor, doğru cevap = aktifParagraf.bosText
    final dogruMetin = bsToTr ? aktifParagraf.trText : aktifParagraf.bosText;

    final skor = _hesaplaSkor(
      userAnswer: girilen,
      dogruMetin: dogruMetin,
    );

    final c = skor["correct"];
    final t = skor["total"];
    final p = skor["pct"];
    final wrong = (skor["wrong"] as List<String>);

    final rapor = "Doğru: $c / Toplam: $t (%$p)\n"
        "Zayıf / farklı kelimeler: ${wrong.isEmpty ? "-" : wrong.join(", ")}";

    setState(() {
      _lastUserAnswer = girilen;
      _lastScoreText = rapor;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kontrol edildi ✅"),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaynakMetin = bsToTr ? aktifParagraf.bosText : aktifParagraf.trText;
    final hedefBaslik = bsToTr
        ? "→ Türkçe çevirini yaz"
        : "→ Boşnakça / BHS çevirini yaz";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // mod değiştir
          Row(
            children: [
              Expanded(
                child: Text(
                  bsToTr
                      ? "Boşnakça → Türkçe"
                      : "Türkçe → Boşnakça",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _toggleMode,
                child: const Text("Yönü Değiştir"),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kaynak paragraf kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kaynak Metin:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kaynakMetin,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hedefBaslik,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Senin çevirin
          SizedBox(
            height: 120,
            child: TextField(
              controller: _cevapCtrl,
              expands: true,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Senin çevirin / cevabın",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _kontrolEt,
            icon: const Icon(Icons.check),
            label: const Text("Kontrol Et"),
          ),
          const SizedBox(height: 16),

          // Sonuç kartları
          if (_lastUserAnswer.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Senin Cevabın:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastUserAnswer,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Skor:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastScoreText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
/// ------------------------------------------------------------
/// PADEŽ ALANI SAYFASI
/// - Çoktan seçmeli
/// - Yanlışta açıklama gösteriyor (ör: u + akuzativ = nereye?)
/// - Skor sayacı var
/// ------------------------------------------------------------
class PadezPage extends StatefulWidget {
  const PadezPage({super.key});

  @override
  State<PadezPage> createState() => _PadezPageState();
}

class _PadezPageState extends State<PadezPage> {
  final Random _rnd = Random();

  QuizQuestion? current;
  int dogru = 0;
  int toplam = 0;

  @override
  void initState() {
    super.initState();
    current = _next();
  }

  QuizQuestion _next() {
    return padezSorular[_rnd.nextInt(padezSorular.length)];
  }

  void _answer(int idx) {
    if (current == null) return;
    final ok = idx == current!.correct;

    setState(() {
      toplam++;
      if (ok) dogru++;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tačno ✅"),
          duration: Duration(milliseconds: 800),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Netačno ❌ Doğru: ${current!.options[current!.correct]}\nNot: ${current!.explanation ?? ""}",
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    setState(() {
      current = _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Center(child: Text("Soru yok"));
    }

    final q = current!;
    final pct = toplam == 0 ? 0 : ((dogru / toplam) * 100).round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Doğru: $dogru / Toplam: $toplam (%$pct)",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                q.prompt,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < q.options.length; i++)
            Card(
              child: ListTile(
                title: Text(q.options[i]),
                onTap: () => _answer(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ADMIN PANELİ
/// Herkes admin gibi. Buradan veri ekleniyor.
/// Sekmeler:
///  - Kelime
///  - Ezber (çoktan seçmeli kelime sorusu)
///  - Boşluk Doldur
///  - Soru Zarfı
///  - Padež
///  - Çeviri (paragraf ekleme)
///
/// Not:
///  - Boş bırakılamaz alanlar için basic kontrol koydum:
///    eğer boşsa SnackBar ile uyarı veriyoruz ("Bu alan boş bırakılamaz")
/// ------------------------------------------------------------
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // --- Kelime ekleme controllerları ---
  final TextEditingController kelimeBosCtrl = TextEditingController();
  final TextEditingController kelimeTrCtrl = TextEditingController();
  final TextEditingController kelimeTurCtrl = TextEditingController();
  final TextEditingController kelimeCinsCtrl = TextEditingController();
  final TextEditingController kelimeOrnekCtrl = TextEditingController();

  // toplu kelime ekleme (format: bs; tr; tür; örnek; cinsiyet)
  final TextEditingController kelimeTopluCtrl = TextEditingController();

  // --- Ezber Yap soru ekleme (çoktan seçmeli) ---
  final TextEditingController ezberSoruCtrl = TextEditingController();
  final TextEditingController ezberOpt1Ctrl = TextEditingController();
  final TextEditingController ezberOpt2Ctrl = TextEditingController();
  final TextEditingController ezberOpt3Ctrl = TextEditingController();
  final TextEditingController ezberOpt4Ctrl = TextEditingController();
  final TextEditingController ezberDogruIndexCtrl = TextEditingController();
  // mode seçimi: bsToTr mı trToBs mi?
  QuizMode ezberMode = QuizMode.bsToTr;

  // toplu quiz ekleme
  final TextEditingController ezberTopluCtrl = TextEditingController();

  // --- Boşluk Doldur ekleme ---
  final TextEditingController boslukSoruCtrl = TextEditingController();
  final TextEditingController boslukCevapCtrl = TextEditingController();

  // toplu boşluk doldur ekleme (sen istedin)
  // format: soru|||cevap (her satır bir tane)
  final TextEditingController boslukTopluCtrl = TextEditingController();

  // --- Soru Zarfı ekleme ---
  final TextEditingController soruZarfSoruCtrl = TextEditingController();
  final TextEditingController soruZarf1Ctrl = TextEditingController();
  final TextEditingController soruZarf2Ctrl = TextEditingController();
  final TextEditingController soruZarf3Ctrl = TextEditingController();
  final TextEditingController soruZarf4Ctrl = TextEditingController();
  final TextEditingController soruZarfDogruCtrl = TextEditingController();

  // --- Padež soru ekleme ---
  final TextEditingController padezSoruCtrl = TextEditingController();
  final TextEditingController padez1Ctrl = TextEditingController();
  final TextEditingController padez2Ctrl = TextEditingController();
  final TextEditingController padez3Ctrl = TextEditingController();
  final TextEditingController padez4Ctrl = TextEditingController();
  final TextEditingController padezDogruCtrl = TextEditingController();
  final TextEditingController padezAciklamaCtrl = TextEditingController();

  // toplu padez ekleme
  // format: soru | şık1 | şık2 | şık3 | şık4 | doğruIndex | açıklama
  final TextEditingController padezTopluCtrl = TextEditingController();

  // --- Çeviri paragraf ekleme (senin uzun metnin) ---
  final TextEditingController parBosCtrl = TextEditingController();
  final TextEditingController parTrCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    // dispose controllerlar
    kelimeBosCtrl.dispose();
    kelimeTrCtrl.dispose();
    kelimeTurCtrl.dispose();
    kelimeCinsCtrl.dispose();
    kelimeOrnekCtrl.dispose();
    kelimeTopluCtrl.dispose();

    ezberSoruCtrl.dispose();
    ezberOpt1Ctrl.dispose();
    ezberOpt2Ctrl.dispose();
    ezberOpt3Ctrl.dispose();
    ezberOpt4Ctrl.dispose();
    ezberDogruIndexCtrl.dispose();
    ezberTopluCtrl.dispose();

    boslukSoruCtrl.dispose();
    boslukCevapCtrl.dispose();
    boslukTopluCtrl.dispose();

    soruZarfSoruCtrl.dispose();
    soruZarf1Ctrl.dispose();
    soruZarf2Ctrl.dispose();
    soruZarf3Ctrl.dispose();
    soruZarf4Ctrl.dispose();
    soruZarfDogruCtrl.dispose();

    padezSoruCtrl.dispose();
    padez1Ctrl.dispose();
    padez2Ctrl.dispose();
    padez3Ctrl.dispose();
    padez4Ctrl.dispose();
    padezDogruCtrl.dispose();
    padezAciklamaCtrl.dispose();
    padezTopluCtrl.dispose();

    parBosCtrl.dispose();
    parTrCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  // ---------- Kelime ekle (tekli)
  void _ekleKelimeTekli() {
    if (kelimeBosCtrl.text.trim().isEmpty ||
        kelimeTrCtrl.text.trim().isEmpty ||
        kelimeTurCtrl.text.trim().isEmpty) {
      _snack("Boşnakça / Türkçe / tür boş bırakılamaz");
      return;
    }

    kelimeListesi.add(
      KelimeEntry(
        bos: kelimeBosCtrl.text.trim(),
        tr: kelimeTrCtrl.text.trim(),
        tur: kelimeTurCtrl.text.trim(),
        cinsiyet: kelimeCinsCtrl.text.trim().isEmpty
            ? null
            : kelimeCinsCtrl.text.trim(),
        ornek: kelimeOrnekCtrl.text.trim().isEmpty
            ? null
            : kelimeOrnekCtrl.text.trim(),
      ),
    );

    kelimeBosCtrl.clear();
    kelimeTrCtrl.clear();
    kelimeTurCtrl.clear();
    kelimeCinsCtrl.clear();
    kelimeOrnekCtrl.clear();

    _snack("Kelime eklendi ✅");
    setState(() {});
  }

  // ---------- Kelime ekle (toplu)
  // format her satır:
  // bos; tr; tür; örnek cümle; cinsiyet
  void _ekleKelimeToplu() {
    final raw = kelimeTopluCtrl.text.trim();
    if (raw.isEmpty) {
      _snack("Toplu alan boş");
      return;
    }

    final lines = raw.split('\n');
    for (final line in lines) {
      final parts = line.split(';');
      if (parts.length < 3) {
        // en az bos,tr,tür lazım
        continue;
      }
      final bos = parts[0].trim();
      final tr = parts[1].trim();
      final tur = parts[2].trim();
      final ornek = parts.length > 3 ? parts[3].trim() : "";
      final cins = parts.length > 4 ? parts[4].trim() : "";

      if (bos.isEmpty || tr.isEmpty || tur.isEmpty) {
        // zorunlu boşsa atla
        continue;
      }

      kelimeListesi.add(
        KelimeEntry(
          bos: bos,
          tr: tr,
          tur: tur,
          ornek: ornek.isEmpty ? null : ornek,
          cinsiyet: cins.isEmpty ? null : cins,
        ),
      );
    }

    kelimeTopluCtrl.clear();
    _snack("Toplu kelime eklendi ✅");
    setState(() {});
  }

  // ---------- Ezber Yap soru ekle (tekli)
  void _ekleEzberTekli() {
    if (ezberSoruCtrl.text.trim().isEmpty ||
        ezberOpt1Ctrl.text.trim().isEmpty ||
        ezberOpt2Ctrl.text.trim().isEmpty ||
        ezberOpt3Ctrl.text.trim().isEmpty ||
        ezberOpt4Ctrl.text.trim().isEmpty ||
        ezberDogruIndexCtrl.text.trim().isEmpty) {
      _snack("Boş alan var (soru/4 şık/doğru index)");
      return;
    }

    final idx = int.tryParse(ezberDogruIndexCtrl.text.trim());
    if (idx == null || idx < 0 || idx > 3) {
      _snack("Doğru index 0-3 olmalı");
      return;
    }

    ezberSorular.add(
      QuizQuestion(
        prompt: ezberSoruCtrl.text.trim(),
        options: [
          ezberOpt1Ctrl.text.trim(),
          ezberOpt2Ctrl.text.trim(),
          ezberOpt3Ctrl.text.trim(),
          ezberOpt4Ctrl.text.trim(),
        ],
        correct: idx,
        mode: ezberMode,
      ),
    );

    ezberSoruCtrl.clear();
    ezberOpt1Ctrl.clear();
    ezberOpt2Ctrl.clear();
    ezberOpt3Ctrl.clear();
    ezberOpt4Ctrl.clear();
    ezberDogruIndexCtrl.clear();

    _snack("Ezber sorusu eklendi ✅");
    setState(() {});
  }

  // ---------- Ezber Yap soru ekle (toplu)
  // format:
  // soru | şık1 | şık2 | şık3 | şık4 | doğruIndex(0-3)
  void _ekleEzberToplu() {
    final raw = ezberTopluCtrl.text.trim();
    if (raw.isEmpty) {
      _snack("Toplu alan boş");
      return;
    }
    final lines = raw.split('\n');
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length < 6) continue;

      final soru = parts[0].trim();
      final o1 = parts[1].trim();
      final o2 = parts[2].trim();
      final o3 = parts[3].trim();
      final o4 = parts[4].trim();
      final idx = int.tryParse(parts[5].trim()) ?? -1;
      if (soru.isEmpty || o1.isEmpty || o2.isEmpty || o3.isEmpty || o4.isEmpty) {
        continue;
      }
      if (idx < 0 || idx > 3) continue;

      ezberSorular.add(
        QuizQuestion(
          prompt: soru,
          options: [o1, o2, o3, o4],
          correct: idx,
          mode: ezberMode,
        ),
      );
    }

    ezberTopluCtrl.clear();
    _snack("Toplu Ezber soruları eklendi ✅");
    setState(() {});
  }

  // ---------- Boşluk Doldur ekle (tekli)
  void _ekleBoslukTekli() {
    if (boslukSoruCtrl.text.trim().isEmpty ||
        boslukCevapCtrl.text.trim().isEmpty) {
      _snack("Soru veya cevap boş olamaz");
      return;
    }

    boslukSorular.add(
      ClozeQuestion(
        questionText: boslukSoruCtrl.text.trim(),
        answer: boslukCevapCtrl.text.trim(),
      ),
    );

    boslukSoruCtrl.clear();
    boslukCevapCtrl.clear();

    _snack("Boşluk doldur sorusu eklendi ✅");
    setState(() {});
  }

  // ---------- Boşluk Doldur ekle (toplu)
  // her satır: SORU|||CEVAP
  void _ekleBoslukToplu() {
    final raw = boslukTopluCtrl.text.trim();
    if (raw.isEmpty) {
      _snack("Toplu boşluk doldur alanı boş");
      return;
    }
    final lines = raw.split('\n');
    for (final line in lines) {
      final parts = line.split("|||");
      if (parts.length < 2) continue;
      final soru = parts[0].trim();
      final cevap = parts[1].trim();
      if (soru.isEmpty || cevap.isEmpty) continue;
      boslukSorular.add(
        ClozeQuestion(
          questionText: soru,
          answer: cevap,
        ),
      );
    }

    boslukTopluCtrl.clear();
    _snack("Toplu boşluk doldur soruları eklendi ✅");
    setState(() {});
  }

  // ---------- Soru Zarfı ekle (tekli)
  void _ekleSoruZarfiTekli() {
    if (soruZarfSoruCtrl.text.trim().isEmpty ||
        soruZarf1Ctrl.text.trim().isEmpty ||
        soruZarf2Ctrl.text.trim().isEmpty ||
        soruZarf3Ctrl.text.trim().isEmpty ||
        soruZarf4Ctrl.text.trim().isEmpty ||
        soruZarfDogruCtrl.text.trim().isEmpty) {
      _snack("Boş alan var (soru/4 şık/doğru index)");
      return;
    }

    final idx = int.tryParse(soruZarfDogruCtrl.text.trim());
    if (idx == null || idx < 0 || idx > 3) {
      _snack("Doğru index 0-3 olmalı");
      return;
    }

    soruZarfSorular.add(
      QuizQuestion(
        prompt: soruZarfSoruCtrl.text.trim(),
        options: [
          soruZarf1Ctrl.text.trim(),
          soruZarf2Ctrl.text.trim(),
          soruZarf3Ctrl.text.trim(),
          soruZarf4Ctrl.text.trim(),
        ],
        correct: idx,
        mode: QuizMode.soruZarfi,
      ),
    );

    soruZarfSoruCtrl.clear();
    soruZarf1Ctrl.clear();
    soruZarf2Ctrl.clear();
    soruZarf3Ctrl.clear();
    soruZarf4Ctrl.clear();
    soruZarfDogruCtrl.clear();

    _snack("Soru Zarfı sorusu eklendi ✅");
    setState(() {});
  }

  // ---------- Padež ekle (tekli)
  void _eklePadezTekli() {
    if (padezSoruCtrl.text.trim().isEmpty ||
        padez1Ctrl.text.trim().isEmpty ||
        padez2Ctrl.text.trim().isEmpty ||
        padez3Ctrl.text.trim().isEmpty ||
        padez4Ctrl.text.trim().isEmpty ||
        padezDogruCtrl.text.trim().isEmpty) {
      _snack("Boş alan var (soru/4 şık/doğru index)");
      return;
    }

    final idx = int.tryParse(padezDogruCtrl.text.trim());
    if (idx == null || idx < 0 || idx > 3) {
      _snack("Doğru index 0-3 olmalı");
      return;
    }

    padezSorular.add(
      QuizQuestion(
        prompt: padezSoruCtrl.text.trim(),
        options: [
          padez1Ctrl.text.trim(),
          padez2Ctrl.text.trim(),
          padez3Ctrl.text.trim(),
          padez4Ctrl.text.trim(),
        ],
        correct: idx,
        mode: QuizMode.padez,
        explanation: padezAciklamaCtrl.text.trim(),
      ),
    );

    padezSoruCtrl.clear();
    padez1Ctrl.clear();
    padez2Ctrl.clear();
    padez3Ctrl.clear();
    padez4Ctrl.clear();
    padezDogruCtrl.clear();
    padezAciklamaCtrl.clear();

    _snack("Padež sorusu eklendi ✅");
    setState(() {});
  }

  // ---------- Padež ekle (toplu)
  // format:
  // soru | şık1 | şık2 | şık3 | şık4 | doğruIndex(0-3) | açıklama
  void _eklePadezToplu() {
    final raw = padezTopluCtrl.text.trim();
    if (raw.isEmpty) {
      _snack("Toplu padež alanı boş");
      return;
    }

    final lines = raw.split('\n');
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length < 7) continue;

      final soru = parts[0].trim();
      final o1 = parts[1].trim();
      final o2 = parts[2].trim();
      final o3 = parts[3].trim();
      final o4 = parts[4].trim();
      final idx = int.tryParse(parts[5].trim()) ?? -1;
      final acik = parts[6].trim();

      if (soru.isEmpty ||
          o1.isEmpty ||
          o2.isEmpty ||
          o3.isEmpty ||
          o4.isEmpty ||
          idx < 0 ||
          idx > 3) {
        continue;
      }

      padezSorular.add(
        QuizQuestion(
          prompt: soru,
          options: [o1, o2, o3, o4],
          correct: idx,
          mode: QuizMode.padez,
          explanation: acik,
        ),
      );
    }

    padezTopluCtrl.clear();
    _snack("Toplu Padež soruları eklendi ✅");
    setState(() {});
  }

  // ---------- Çeviri paragraf ekle
  // Burada 2 alan da zorunlu!
  void _ekleParagraf() {
    if (parBosCtrl.text.trim().isEmpty ||
        parTrCtrl.text.trim().isEmpty) {
      _snack("Bu alan boş bırakılamaz (iki dil de lazım)");
      return;
    }

    ceviriParagraflari.add(
      StudyParagraph(
        bosText: parBosCtrl.text.trim(),
        trText: parTrCtrl.text.trim(),
      ),
    );

    parBosCtrl.clear();
    parTrCtrl.clear();

    _snack("Paragraf eklendi ✅ (Çeviri Yap sekmesinde göreceksin)");
    setState(() {});
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController c,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Paneli"),
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: const [
              Tab(text: "Kelime"),
              Tab(text: "Ezber"),
              Tab(text: "Boşluk"),
              Tab(text: "Zarf"),
              Tab(text: "Padež"),
              Tab(text: "Çeviri"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            // ---- TAB 1: Kelime ----
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Tekli Kelime Ekle"),
                _textField(kelimeBosCtrl, "Boşnakça"),
                const SizedBox(height: 8),
                _textField(kelimeTrCtrl, "Türkçe"),
                const SizedBox(height: 8),
                _textField(kelimeTurCtrl, "Tür (isim/fiil/sıfat/zarf/ifade)"),
                const SizedBox(height: 8),
                _textField(kelimeCinsCtrl, "Cinsiyet (m/f/n) opsiyonel"),
                const SizedBox(height: 8),
                _textField(kelimeOrnekCtrl, "Örnek cümle (opsiyonel)",
                    maxLines: 2),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _ekleKelimeTekli,
                  icon: const Icon(Icons.add),
                  label: const Text("Kelimeyi Ekle"),
                ),
                const SizedBox(height: 24),

                _sectionTitle("Toplu Kelime Ekle"),
                const Text(
                    "Format (her satır): bos; tr; tür; örnek; cinsiyet\n"
                    "örnek ve cinsiyet opsiyonel"),
                const SizedBox(height: 8),
                _textField(kelimeTopluCtrl, "Çoklu giriş", maxLines: 5),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleKelimeToplu,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Toplu Kelime Yükle"),
                ),
              ],
            ),

            // ---- TAB 2: Ezber ----
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Tekli Ezber Sorusu Ekle"),
                _textField(ezberSoruCtrl, "Soru (ör: hljeb / ekmek ...)"),
                const SizedBox(height: 8),
                _textField(ezberOpt1Ctrl, "Şık 1"),
                const SizedBox(height: 8),
                _textField(ezberOpt2Ctrl, "Şık 2"),
                const SizedBox(height: 8),
                _textField(ezberOpt3Ctrl, "Şık 3"),
                const SizedBox(height: 8),
                _textField(ezberOpt4Ctrl, "Şık 4"),
                const SizedBox(height: 8),
                _textField(ezberDogruIndexCtrl, "Doğru index (0-3)"),
                const SizedBox(height: 8),

                // mode seçimi
                Row(
                  children: [
                    const Text("Soru Tipi: "),
                    DropdownButton<QuizMode>(
                      value: ezberMode,
                      items: const [
                        DropdownMenuItem(
                          value: QuizMode.bsToTr,
                          child: Text("Boşnakça → Türkçe"),
                        ),
                        DropdownMenuItem(
                          value: QuizMode.trToBs,
                          child: Text("Türkçe → Boşnakça"),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            ezberMode = v;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleEzberTekli,
                  icon: const Icon(Icons.add),
                  label: const Text("Ezber Sorusunu Ekle"),
                ),
                const SizedBox(height: 24),

                _sectionTitle("Toplu Ezber Sorusu Ekle"),
                const Text(
                    "Format (her satır):\n"
                    "soru | şık1 | şık2 | şık3 | şık4 | doğruIndex(0-3)\n"
                    "Bu, seçili mod (Boşnakça→TR / Türkçe→BS) ile kaydedilir."),
                const SizedBox(height: 8),
                _textField(ezberTopluCtrl, "Çoklu giriş", maxLines: 5),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleEzberToplu,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Toplu Ezber Sorusu Yükle"),
                ),
              ],
            ),

            // ---- TAB 3: Boşluk ----
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Boşluk Doldur (Tekli)"),
                _textField(boslukSoruCtrl, "Soru metni (Ja pijem ____.)",
                    maxLines: 2),
                const SizedBox(height: 8),
                _textField(boslukCevapCtrl, "Doğru cevap"),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleBoslukTekli,
                  icon: const Icon(Icons.add),
                  label: const Text("Boşluk Sorusunu Ekle"),
                ),
                const SizedBox(height: 24),

                _sectionTitle("Boşluk Doldur (Toplu)"),
                const Text(
                    "Format (her satır):\n"
                    "SORU|||CEVAP\n"
                    "Örnek:\n"
                    "Ja pijem ____.|||vodu"),
                const SizedBox(height: 8),
                _textField(boslukTopluCtrl, "Çoklu giriş", maxLines: 5),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleBoslukToplu,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Toplu Boşluk Sorusu Yükle"),
                ),
              ],
            ),

            // ---- TAB 4: Zarf ----
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Soru Zarfı Sorusu (Tekli)"),
                _textField(
                    soruZarfSoruCtrl, "Soru (_____ živiš? gibi)", maxLines: 2),
                const SizedBox(height: 8),
                _textField(soruZarf1Ctrl, "Şık 1 (Gdje vb)"),
                const SizedBox(height: 8),
                _textField(soruZarf2Ctrl, "Şık 2"),
                const SizedBox(height: 8),
                _textField(soruZarf3Ctrl, "Şık 3"),
                const SizedBox(height: 8),
                _textField(soruZarf4Ctrl, "Şık 4"),
                const SizedBox(height: 8),
                _textField(soruZarfDogruCtrl, "Doğru index (0-3)"),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleSoruZarfiTekli,
                  icon: const Icon(Icons.add),
                  label: const Text("Zarf Sorusunu Ekle"),
                ),
              ],
            ),

            // ---- TAB 5: Padež ----
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Padež Sorusu (Tekli)"),
                _textField(padezSoruCtrl, "Soru (Idem u školu. Hangi hâl?)",
                    maxLines: 2),
                const SizedBox(height: 8),
                _textField(padez1Ctrl, "Şık 1"),
                const SizedBox(height: 8),
                _textField(padez2Ctrl, "Şık 2"),
                const SizedBox(height: 8),
                _textField(padez3Ctrl, "Şık 3"),
                const SizedBox(height: 8),
                _textField(padez4Ctrl, "Şık 4"),
                const SizedBox(height: 8),
                _textField(padezDogruCtrl, "Doğru index (0-3)"),
                const SizedBox(height: 8),
                _textField(padezAciklamaCtrl, "Açıklama (u + akuzativ ...)",
                    maxLines: 2),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _eklePadezTekli,
                  icon: const Icon(Icons.add),
                  label: const Text("Padež Sorusunu Ekle"),
                ),
                const SizedBox(height: 24),

                _sectionTitle("Padež Sorusu (Toplu)"),
                const Text(
                    "Format (her satır):\n"
                    "soru | şık1 | şık2 | şık3 | şık4 | doğruIndex(0-3) | açıklama"),
                const SizedBox(height: 8),
                _textField(padezTopluCtrl, "Çoklu giriş", maxLines: 5),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _eklePadezToplu,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Toplu Padež Yükle"),
                ),
              ],
            ),

            // ---- TAB 6: Çeviri ----
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Paragraf Ekle (Çeviri Pratiği)"),
                const Text(
                    "ÜST alan: Boşnakça / BHS metin\n"
                    "ALT alan: Türkçe doğru çeviri\n"
                    "İkisi de boş OLAMAZ."),
                const SizedBox(height: 8),
                _textField(parBosCtrl, "Boşnakça / BHS paragraf", maxLines: 5),
                const SizedBox(height: 8),
                _textField(parTrCtrl, "Türkçe paragraf", maxLines: 5),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _ekleParagraf,
                  icon: const Icon(Icons.add),
                  label: const Text("Paragrafı Kaydet"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
