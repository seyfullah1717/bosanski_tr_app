// PART-1 ─────────────────────────────────────────────────────────────────────
// Bosanski-TR (tek dosya) — 7 sekmeli, Supabase ile
// Not: pubspec.yaml -> supabase_flutter: ^2.5.0

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // <-- debounce için

// ── Supabase ayarları (DEĞİŞTİR)
const SUPABASE_URL = 'https://zrgxjsagacmkkgkqhlig.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_8mws0LUrHJod5_4qyAY1gw_fWzrMkAv';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  runApp(const BosanskiTRApp());
}

// ── Modeller
class Word {
  final String bos, tr, tur, gender, example;
  Word({
    required this.bos,
    required this.tr,
    required this.tur,      // isim/fiil/sıfat/zarf/ifade
    required this.gender,   // m/f/n
    required this.example,
  });
  Map<String, dynamic> toMap() => {
    'bos': bos, 'tr': tr, 'tur': tur, 'gender': gender, 'example': example,
  };
  static Word fromMap(Map<String,dynamic> m) => Word(
    bos: (m['bos']??'').toString(),
    tr: (m['tr']??'').toString(),
    tur: (m['tur']??'').toString(),
    gender: (m['gender']??'').toString(),
    example: (m['example']??'').toString(),
  );
}

class TextPair {
  final String bos, tr;
  TextPair({required this.bos, required this.tr});
  Map<String,dynamic> toMap()=>{'bos':bos,'tr':tr};
  static TextPair fromMap(Map<String,dynamic> m)=>
    TextPair(bos:(m['bos']??'').toString(), tr:(m['tr']??'').toString());
}

// ── Repo (Supabase erişimi)
class Repo {
  final SupabaseClient s = Supabase.instance.client;

  Map<String,dynamic> _toMap(dynamic e)=>Map<String,dynamic>.from(e as Map);
  String _sigWord(Word w)=>'${w.bos.trim().toLowerCase()}|'
                           '${w.tr.trim().toLowerCase()}|'
                           '${w.tur.trim().toLowerCase()}';

  // Kelimeler
  Future<List<Word>> fetchWords({
    String kategori='Hepsi', String search='', int limit=1000,
  }) async {
    var q = s.from('kelimeler').select('*');
    if (kategori!='Hepsi') { q = q.eq('tur', kategori); }
    if (search.trim().isNotEmpty) {
      final t = search.trim();
      q = q.or('bos.ilike.%$t%,tr.ilike.%$t%');
    }
    final res = await q.order('bos', ascending:true).limit(limit);
    return (res as List).map(_toMap).map(Word.fromMap).toList();
  }

  Future<bool> existsWord({required String bos, required String tr, required String tur}) async {
    final b=bos.trim(), t=tr.trim(), u=tur.trim();
    final res = await s.from('kelimeler').select('bos,tr,tur')
      .or('bos.eq.$b,tr.eq.$t').limit(1000);
    for (final m in (res as List).map(_toMap)) {
      if ((m['bos']??'').toString().trim().toLowerCase()==b.toLowerCase() &&
          (m['tr']??'').toString().trim().toLowerCase()==t.toLowerCase() &&
          (m['tur']??'').toString().trim().toLowerCase()==u.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Future<void> addWord(Word w) async {
    if (await existsWord(bos:w.bos,tr:w.tr,tur:w.tur)) {
      throw 'Bu kelime zaten var: ${w.bos} → ${w.tr} (${w.tur})';
    }
    await s.from('kelimeler').insert(w.toMap());
  }

  Future<void> updateWord({
    required String oldBos, required String oldTr, required String oldTur,
    required Word newWord,
  }) async {
    final clash = await existsWord(bos:newWord.bos,tr:newWord.tr,tur:newWord.tur);
    final sameKey = _sigWord(newWord) ==
        '${oldBos.toLowerCase()}|${oldTr.toLowerCase()}|${oldTur.toLowerCase()}';
    if (clash && !sameKey) throw 'Aynı anahtar (bos+tr+tur) mevcut!';
    await s.from('kelimeler').update(newWord.toMap())
      .match({'bos':oldBos,'tr':oldTr,'tur':oldTur});
  }

  Future<void> deleteWord({required String bos, required String tr, required String tur}) async {
    await s.from('kelimeler').delete().match({'bos':bos,'tr':tr,'tur':tur});
  }

  Future<void> addWordsBulkSafe(List<Word> items) async {
    if (items.isEmpty) return;
    final seen=<String>{}; final toInsert=<Word>[];
    for (final w in items) {
      final sig=_sigWord(w);
      if (seen.contains(sig)) continue;
      seen.add(sig);
      if (!await existsWord(bos:w.bos,tr:w.tr,tur:w.tur)) toInsert.add(w);
    }
    if (toInsert.isNotEmpty) {
      await s.from('kelimeler').insert(toInsert.map((e)=>e.toMap()).toList());
    }
  }

  // Metin çiftleri
  Future<List<TextPair>> fetchTextPairs({int limit=500}) async {
    final res = await s.from('text_pairs').select('*')
      .order('created_at',ascending:false).limit(limit);
    return (res as List).map(_toMap).map(TextPair.fromMap).toList();
  }
  Future<void> addTextPair({required String bos, required String tr}) async {
    await s.from('text_pairs').insert({'bos':bos,'tr':tr});
  }
  Future<void> addTextPairsBulk(List<TextPair> items) async {
    if (items.isEmpty) return;
    await s.from('text_pairs').insert(items.map((e)=>e.toMap()).toList());
  }

  // Boşluk Doldurma (cloze)
  Future<List<Map<String,String>>> fetchCloze({int limit=500}) async {
    final res = await s.from('cloze').select('*').limit(limit);
    final list = (res as List).map(_toMap).toList();
    return list.map((m)=>{'sentence': (m['sentence']??'').toString(),
                          'lang': (m['lang']??'bos').toString()}).toList();
  }
  Future<void> addClozeOne({required String sentence, String lang='bos'}) async {
    await s.from('cloze').insert({'sentence':sentence,'lang':lang});
  }
  Future<void> addClozeBulk(List<Map<String,String>> items) async {
    if (items.isEmpty) return;
    await s.from('cloze').insert(items);
  }
}

// ── App & Navigation
class BosanskiTRApp extends StatefulWidget { const BosanskiTRApp({super.key});
  @override State<BosanskiTRApp> createState()=>_BosanskiTRAppState(); }

class _BosanskiTRAppState extends State<BosanskiTRApp>{
  ThemeMode _mode=ThemeMode.system;
  void _toggleTheme()=>setState(()=>_mode=_mode==ThemeMode.dark?ThemeMode.light:ThemeMode.dark);
  @override Widget build(BuildContext context){
    return MaterialApp(
      title:'Bosanski TR', debugShowCheckedModeBanner:false,
      themeMode:_mode,
      theme: ThemeData(useMaterial3:true, colorSchemeSeed:Colors.blue),
      darkTheme: ThemeData(brightness:Brightness.dark,useMaterial3:true,colorSchemeSeed:Colors.blue),
      home: HomeScreen(onToggleTheme:_toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>{
  int _idx=0; final repo=Repo();
  @override Widget build(BuildContext context){
    final pages=[
      KelimeOgrenPage(repo:repo),
      EzberYapPage(repo:repo),
      BoslukDoldurPage(repo:repo),
      SoruSorPage(),
      CeviriYapPage(repo:repo),
      PadezAlaniPage(),
      KelimeEklePage(repo:repo),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Bosanski TR'), actions:[
        IconButton(icon: const Icon(Icons.brightness_6), onPressed: widget.onToggleTheme, tooltip:'Tema Değiştir')
      ]),
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex:_idx, onDestinationSelected:(i)=>setState(()=>_idx=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Kelime Öğren'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'Ezber Yap'),
          NavigationDestination(icon: Icon(Icons.edit), label: 'Boşluk Doldur'),
          NavigationDestination(icon: Icon(Icons.help_center), label: 'Soru Sor'),
          NavigationDestination(icon: Icon(Icons.translate), label: 'Çeviri Yap'),
          NavigationDestination(icon: Icon(Icons.rule), label: 'Padej Alanı'),
          NavigationDestination(icon: Icon(Icons.playlist_add), label: 'Kelime Ekle'),
        ],
      ),
    );
  }
}

// Helpers
void _snack(BuildContext ctx,String msg){
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
}
String _norm(String s){
  final lower=s.toLowerCase();
  final cleaned=lower.replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode:true),' ');
  return cleaned.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).join(' ');
}
// PART-2 ─────────────────────────────────────────────────────────────────────
// Kelime Öğren

// Canlı arama (debounce) eklenmiş KELİME ÖĞREN sayfası
class KelimeOgrenPage extends StatefulWidget {
  final Repo repo;
  const KelimeOgrenPage({super.key, required this.repo});
  @override
  State<KelimeOgrenPage> createState() => _KelimeOgrenPageState();
}

class _KelimeOgrenPageState extends State<KelimeOgrenPage> {
  String kategori = 'Hepsi';
  String search = '';
  bool loading = false;

  final _searchCtrl = TextEditingController();
  final chips = const ['Hepsi', 'isim', 'fiil', 'sıfat', 'zarf', 'ifade'];

  List<Word> words = [];

  // 🔹 canlı arama için debounce timer
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _deb?.cancel();        // timer’ı iptal et
    _searchCtrl.dispose(); // controller’ı kapat
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      words = await widget.repo.fetchWords(kategori: kategori, search: search);
    } catch (e) {
      _snack(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Üstte yatay chip filtreleri
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final label = chips[i];
              final selected = kategori == label;
              final ui = i == 0 ? 'Hepsi' : label[0].toUpperCase() + label.substring(1);
              return ChoiceChip(
                label: Text(ui),
                selected: selected,
                onSelected: (_) {
                  setState(() => kategori = label);
                  _deb?.cancel();
                  _load();
                },
              );
            },
          ),
        ),

        // Arama kutusu + toplam
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ara (Boşnakça/Türkçe)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        search = '';
                        _deb?.cancel();
                        _load(); // anında yenile
                      },
                    ),
                  ),
                  // 🔹 canlı arama: 250 ms sonra sorgu at
                  onChanged: (v) {
                    search = v;
                    _deb?.cancel();
                    _deb = Timer(const Duration(milliseconds: 250), _load);
                  },
                  // enter’a basılırsa da çalışsın
                  onSubmitted: (v) {
                    search = v;
                    _deb?.cancel();
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text('Toplam: ${words.length}'),
            ],
          ),
        ),
        const Divider(height: 0),

        // Liste
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (_, i) {
                    final w = words[i];
                    return ListTile(
                      title: Text('${w.bos}  →  ${w.tr}'),
                      subtitle: Text(
                        'Tür: ${w.tur}  |  Cinsiyet: ${w.gender}  |  Örnek: ${w.example.isEmpty ? "-" : w.example}',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// PART-3 ─────────────────────────────────────────────────────────────────────
// Ezber Yap — kelime havuzundan (tüm türler)

class EzberYapPage extends StatefulWidget{
  final Repo repo; const EzberYapPage({super.key, required this.repo});
  @override State<EzberYapPage> createState()=>_EzberYapPageState();
}
class _EzberYapPageState extends State<EzberYapPage>{
  final rnd=Random(); bool loading=false;
  List<Word> pool=[]; Word? current; List<String> options=[]; String? selected;
  bool bosToTr=true; int correct=0,total=0; final asked=<int>{};

  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async{
    if(!mounted) return;
    setState(()=>loading=true);
    try{
      pool=await widget.repo.fetchWords(limit:1000);
      if (pool.length<2){ _snack(context,'Ezber için en az 2 kelime ekleyin.'); return; }
      _next();
    }catch(e){ _snack(context,'Hata: $e'); }
    finally{ if(mounted) setState(()=>loading=false); }
  }

  void _next(){
    if(!mounted || pool.isEmpty) return;
    if (asked.length==pool.length) asked.clear();
    bosToTr=rnd.nextBool();

    int idx=rnd.nextInt(pool.length), guard=0;
    while(asked.contains(idx) && guard<50){ idx=rnd.nextInt(pool.length); guard++; }
    asked.add(idx); current=pool[idx];

    final correctAns = bosToTr? current!.tr : current!.bos;
    final answers = <String>{correctAns};
    while (answers.length<4 && answers.length<pool.length){
      final other=pool[rnd.nextInt(pool.length)];
      answers.add(bosToTr? other.tr : other.bos);
    }
    options=answers.toList()..shuffle();
    if (options.length<2) { options=[correctAns]; }
    selected=null; setState((){});
  }

  void _answer(String choice){
    final correctAns = bosToTr? current!.tr : current!.bos;
    final ok = choice.trim().toLowerCase()==correctAns.trim().toLowerCase();
    setState(()=>total++); if (ok) setState(()=>correct++);
    _snack(context, ok? 'Tačno ✅' : 'Ne tačno ❌');
    Future.delayed(const Duration(milliseconds:400), _next);
  }

  @override Widget build(BuildContext context){
    final percent = total==0?0:((correct*100)/total).round();
    if (loading || current==null) return const Center(child:CircularProgressIndicator());
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth:600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children:[
            Text('Doğru: $correct / $total  |  %$percent'),
            const SizedBox(height:12),
            Text(
              bosToTr? '“${current!.bos}” kelimesinin Türkçesi nedir?'
                      : '“${current!.tr}” kelimesinin Boşnakçası nedir?',
              style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,
            ),
            const SizedBox(height:16),
            for (final o in options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical:6),
                child: FilledButton.tonal(
                  onPressed: ()=>_answer(o),
                  child: Padding(padding: const EdgeInsets.all(12), child: Text(o, textAlign: TextAlign.center)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// Boşluk Doldurma — cloze tablosu (yoksa gömülü default)
class BoslukDoldurPage extends StatefulWidget{
  final Repo repo; const BoslukDoldurPage({super.key, required this.repo});
  @override State<BoslukDoldurPage> createState()=>_BoslukDoldurPageState();
}
class _BoslukDoldurPageState extends State<BoslukDoldurPage> {
  final rnd = Random();
  List<Map<String, dynamic>> cloze = [];
  String shown = '';
  String answer = '';
  String result = '';
  final ctrl = TextEditingController();
  List<String> options = [];
  bool loading = false;

  // ✅ Sayaç değişkenleri
  int correct = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await Supabase.instance.client.from('cloze').select();
      cloze = (data as List).cast<Map<String, dynamic>>();
      _newQuestion();
    } catch (e) {
      shown = 'Hata: $e';
    }
    setState(() => loading = false);
  }

  void _newQuestion() {
    if (cloze.isEmpty) {
      shown = 'Önce Kelime Ekle > Boşluk’tan içerik ekle.';
      setState(() {});
      return;
    }

    final item = cloze[rnd.nextInt(cloze.length)];
    final raw = (item['sentence'] ?? '').trim();

    // [[işaretli]] kelime kontrolü
    final marked = RegExp(r'\[\[(.+?)\]\]');
    final m = marked.firstMatch(raw);
    if (m != null) {
      answer = m.group(1)!;
      shown = raw.replaceAll(marked, '______');
    } else {
      final tokens = raw.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      if (tokens.length < 2) {
        shown = raw;
      } else {
        final idx = rnd.nextInt(tokens.length);
        answer = tokens[idx];
        tokens[idx] = '______';
        shown = tokens.join(' ');
      }
    }

    // 4 şık üret
    final allWords = cloze.map((e) {
      final match = RegExp(r'\[\[(.+?)\]\]').firstMatch(e['sentence'] ?? '');
      return match?.group(1);
    }).whereType<String>().toList();
    allWords.shuffle();

    final wrongs = allWords.where((w) => w != answer).take(3).toList();
    options = ([answer, ...wrongs]..shuffle());

    ctrl.clear();
    result = '';
    setState(() {});
  }

  void _check(String guess) {
    total++; // toplam soru
    final ok = guess.trim().toLowerCase() == answer.trim().toLowerCase();
    if (ok) correct++;

    result = ok ? '✅ Tačno!' : '❌ Netačno! Cevap: $answer';
    setState(() {});
    Future.delayed(const Duration(seconds: 1), () {
      _newQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    double percent = total == 0 ? 0 : (correct / total * 100);
    return loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Skor göstergesi
                Text(
                  'Skor: $correct / $total  (${percent.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 20),

                Text(
                  shown,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: options
                      .map((opt) => ElevatedButton(
                            onPressed: () => _check(opt),
                            child: Text(opt, style: const TextStyle(fontSize: 18)),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: ctrl,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Cevabı yaz (istersen)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (val) => _check(val),
                ),

                const SizedBox(height: 20),
                Text(
                  result,
                  style: TextStyle(
                      fontSize: 20,
                      color: result.startsWith('✅')
                          ? Colors.green
                          : result.startsWith('❌')
                              ? Colors.red
                              : Colors.black),
                ),
              ],
            ),
          );
  }
}



// ========================= SORU SOR (Gelişmiş) ===============================
class SoruSorPage extends StatefulWidget {
  const SoruSorPage({super.key});
  @override
  State<SoruSorPage> createState() => _SoruSorPageState();
}

class _SoruSorPageState extends State<SoruSorPage> {
  // Soru modeli: soru, şıklar, doğruIndex, ipucu, açıklama, etiket
  final List<({String q, List<String> a, int c, String hint, String exp, String tag})> bank = [
    // tag: "zaman", "yer", "sebep", "yön", "kişi", "miktar", "karışık"
    (q:'“Gdje?” ne demektir?', a:['Nerede?','Ne zaman?','Niçin?','Nasıl?'], c:0, hint:'Mekan sorar.', exp:'Gdje = Nerede?', tag:'yer'),
    (q:'“Kada?” ne demektir?', a:['Ne kadar?','Ne zaman?','Nereden?','Kimin?'], c:1, hint:'Zaman sorar.', exp:'Kada = Ne zaman?', tag:'zaman'),
    (q:'“Zašto?” ne demektir?', a:['Niçin?','Neden?','İkisi de','Hiçbiri'], c:2, hint:'Sebep/amaç.', exp:'Zašto = Neden/Niçin.', tag:'sebep'),
    (q:'“Kako?” ne demektir?', a:['Ne?','Nasıl?','Nerede?','Kim?'], c:1, hint:'Yöntem/biçim.', exp:'Kako = Nasıl?', tag:'karışık'),
    (q:'“Ko?” ne demektir?', a:['Kim?','Ne?','Hangisi?','Neden?'], c:0, hint:'Kişi sorar.', exp:'Ko = Kim?', tag:'kişi'),
    (q:'“Šta?” ne demektir?', a:['Ne?','Ne zaman?','Nereye?','Neden?'], c:0, hint:'Nesne/şey.', exp:'Šta = Ne?', tag:'karışık'),
    (q:'“Kuda?” ne demektir?', a:['Nereye?','Nereden?','Ne kadar?','Niçin?'], c:0, hint:'Yön (hedef).', exp:'Kuda = Nereye?', tag:'yön'),
    (q:'“Odakle?” ne demektir?', a:['Neredeydi?','Nereden?','Ne kadar?','Hangi?'], c:1, hint:'Kaynak/çıkış.', exp:'Odakle = Nereden?', tag:'yön'),
    (q:'“Koliko?” ne demektir?', a:['Ne kadar?','Kaçta?','Kaçıncı?','Ne zaman?'], c:0, hint:'Miktar/sayı.', exp:'Koliko = Ne kadar?/Kaç?', tag:'miktar'),
    (q:'“Čiji?” ne demektir?', a:['Kimin?','Neden?','Hangi?','Nasıl?'], c:0, hint:'Sahiplik.', exp:'Čiji/čija/čije = Kimin?', tag:'kişi'),
    // Kolay örnek cümleli sorular:
    (q:'Cümlede eksik soru zarfı: “___ ideš u školu?”', a:['Kada','Gdje','Kuda','Kako'], c:2, hint:'Yön/hedef.', exp:'“Kuda ideš?” = Nereye gidiyorsun?', tag:'yön'),
    (q:'“___ počinje čas?” (Ders ne zaman başlıyor?)', a:['Kada','Gdje','Zašto','Koliko'], c:0, hint:'Zaman.', exp:'Kada počinje čas?', tag:'zaman'),
    (q:'“___ živiš?” (Nerede yaşıyorsun?)', a:['Kako','Gdje','Zašto','Kuda'], c:1, hint:'Mekan.', exp:'Gdje živiš?', tag:'yer'),
    (q:'“___ učiš bosanski?” (Neden Boşnakça öğreniyorsun?)', a:['Koliko','Zašto','Kako','Odakle'], c:1, hint:'Sebep.', exp:'Zašto učiš bosanski?', tag:'sebep'),
    (q:'“___ ide voz?” (Tren nereye gidiyor?)', a:['Kuda','Odakle','Kada','Gdje'], c:0, hint:'Yön.', exp:'Kuda ide voz?', tag:'yön'),
    (q:'“___ dolaziš?” (Nereden geliyorsun?)', a:['Odakle','Kuda','Koliko','Kako'], c:0, hint:'Kaynak.', exp:'Odakle dolaziš?', tag:'yön'),
    (q:'“___ košta hljeb?” (Ekmek ne kadar?)', a:['Koliko','Kada','Zašto','Gdje'], c:0, hint:'Miktar.', exp:'Koliko košta hljeb?', tag:'miktar'),
    (q:'“___ se zoveš?” (Adın ne?)', a:['Šta','Ko','Kako','Čiji'], c:2, hint:'Biçim/isim sorma kalıbı.', exp:'Kako se zoveš? = Adın ne?', tag:'karışık'),
    (q:'“___ ti je to auto?” (Bu araba kimin?)', a:['Čiji','Ko','Gdje','Kako'], c:0, hint:'Sahiplik.', exp:'Čiji ti je to auto?', tag:'kişi'),
    (q:'“___ radiš doma?” (Evde ne yapıyorsun?)', a:['Šta','Kako','Gdje','Zašto'], c:0, hint:'Nesne.', exp:'Šta radiš doma?', tag:'karışık'),
    // Biraz daha
    (q:'“___ sati je?”', a:['Koliko','Kada','Ko','Gdje'], c:0, hint:'Saat/miktar.', exp:'Koliko je sati?', tag:'miktar'),
    (q:'“___ si umoran?”', a:['Zašto','Kada','Kako','Ko'], c:0, hint:'Sebep.', exp:'Zašto si umoran?', tag:'sebep'),
    (q:'“___ autobus polazi?”', a:['Kada','Gdje','Odakle','Kuda'], c:0, hint:'Zaman.', exp:'Kada autobus polazi?', tag:'zaman'),
    (q:'“___ ideš poslije posla?”', a:['Kuda','Odakle','Gdje','Kako'], c:0, hint:'Yön/hedef.', exp:'Kuda ideš poslije posla?', tag:'yön'),
    (q:'“___ radi učitelj?”', a:['Ko','Šta','Kako','Gdje'], c:1, hint:'Nesne/eylem.', exp:'Šta radi učitelj?', tag:'karışık'),
    (q:'“___ je restoran?”', a:['Gdje','Kada','Kako','Zašto'], c:0, hint:'Mekan.', exp:'Gdje je restoran?', tag:'yer'),
    (q:'“___ si došao?”', a:['Odakle','Kada','Kako','Zašto'], c:0, hint:'Kaynak.', exp:'Odakle si došao?', tag:'yön'),
    (q:'“___ učiš — sam ili s prijateljem?”', a:['Kako','Ko','Šta','Kada'], c:0, hint:'Biçim/yöntem.', exp:'Kako učiš?', tag:'karışık'),
  ];

  // Durum
  late List<int> order;       // karıştırılmış indeksler
  int i = 0;                  // şu anki soru indeksinin sırası (order içinde)
  int? chosen;                // seçilen şık
  bool showHint = false;
  bool showExp  = false;

  // Sayaç/puan
  int correct = 0;
  int total   = 0;
  int streak  = 0;
  int best    = 0;

  // Süre
  static const int limitSec = 20;
  int left = limitSec;
  Timer? t;

  // Joker: 50-50 (her soruda 1 kez)
  bool fiftyUsed = false;
  Set<int> disabled = {};

  // Filtre (etiketler)
  final tags = const ['tümü','zaman','yer','sebep','yön','kişi','miktar','karışık'];
  String activeTag = 'tümü';
  late List<int> filtered;

  @override
  void initState() {
    super.initState();
    _applyFilter();
    _startQuestion();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  void _applyFilter() {
    filtered = [];
    for (int idx=0; idx<bank.length; idx++) {
      if (activeTag == 'tümü' || bank[idx].tag == activeTag) {
        filtered.add(idx);
      }
    }
    filtered.shuffle();
    order = filtered;
    i = 0;
  }

  void _startTimer() {
    t?.cancel();
    left = limitSec;
    t = Timer.periodic(const Duration(seconds:1), (timer) {
      if (!mounted) return;
      if (left <= 0) {
        timer.cancel();
        _finalizeAnswer(-1); // süreden kaybetti
      } else {
        setState(()=> left--);
      }
    });
  }

  void _startQuestion() {
    if (order.isEmpty) {
      // filtre çok dar olabilir
      _snack(context, 'Bu filtrede soru yok. Filtreyi genişlet.');
      return;
    }
    chosen = null;
    showHint = false;
    showExp  = false;
    fiftyUsed = false;
    disabled.clear();
    _startTimer();
    setState((){});
  }

  void _nextQuestion() {
    i++;
    if (i >= order.length) {
      // test bitti: baştan karıştır
      order.shuffle();
      i = 0;
    }
    _startQuestion();
  }

  void _finalizeAnswer(int selected) {
    // -1 = süre bitti / cevap verilmedi
    t?.cancel();
    final q = bank[order[i]];
    final ok = (selected == q.c);
    total++;
    if (ok) {
      correct++;
      streak++;
      if (streak > best) best = streak;
      _snack(context, 'Tačno ✅');
    } else {
      streak = 0;
      final ans = q.a[q.c];
      _snack(context, 'Ne tačno ❌  (Doğru: $ans)');
    }
    // 900ms sonra sonraki soru
    Future.delayed(const Duration(milliseconds:900), _nextQuestion);
    setState((){ chosen = selected; });
  }

  void _useFifty() {
    if (fiftyUsed) return;
    final q = bank[order[i]];
    final wrongs = <int>[];
    for (var k=0; k<q.a.length; k++) {
      if (k != q.c) wrongs.add(k);
    }
    wrongs.shuffle();
    // iki yanlış şıkkı pasifleştir
    disabled = wrongs.take(2).toSet();
    fiftyUsed = true;
    setState((){});
  }

  void _skip() {
    _finalizeAnswer(-1); // cezalı atla (yanlış sayılmaz istiyorsan total++ etme)
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (order.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Bu filtrede soru yok.'),
            const SizedBox(height:8),
            FilledButton(
              onPressed: (){
                activeTag = 'tümü';
                _applyFilter();
                _startQuestion();
              },
              child: const Text('Filtreyi sıfırla'),
            )
          ]),
        ),
      );
    }

    final q = bank[order[i]];
    final percent = total==0 ? 0 : ((correct*100)/total).round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst bar: skor / süre / ilerleme
              Row(
                children: [
                  Text('Skor: $correct/$total  (%$percent)'),
                  const SizedBox(width:12),
                  Text('Seri: $streak  | Rekor: $best'),
                  const Spacer(),
                  // süre göstergesi
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 26, width: 26,
                        child: CircularProgressIndicator(
                          value: left/limitSec,
                        ),
                      ),
                      Text('$left', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filtre chipleri
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in tags) Padding(
                      padding: const EdgeInsets.only(right:8),
                      child: _chip(t, activeTag==t, (){
                        activeTag = t;
                        _applyFilter();
                        _startQuestion();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Soru metni
              Text(
                q.q,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Şıklar
              for (int k=0; k<q.a.length; k++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical:6),
                  child: FilledButton.tonal(
                    onPressed: (chosen==null && !disabled.contains(k))
                        ? ()=>_finalizeAnswer(k)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        q.a[k],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Kontrol butonları
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: '50-50',
                    onPressed: (!fiftyUsed && chosen==null) ? _useFifty : null,
                    icon: const Icon(Icons.percent),
                  ),
                  const SizedBox(width:8),
                  IconButton.filledTonal(
                    tooltip: 'Atla',
                    onPressed: (chosen==null) ? _skip : null,
                    icon: const Icon(Icons.skip_next),
                  ),
                  const Spacer(),
                  // ipucu / açıklama
                  TextButton.icon(
                    onPressed: ()=>setState(()=>showHint=!showHint),
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('İpucu'),
                  ),
                  const SizedBox(width:8),
                  TextButton.icon(
                    onPressed: ()=>setState(()=>showExp=!showExp),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Açıklama'),
                  ),
                ],
              ),

              if (showHint) Padding(
                padding: const EdgeInsets.only(top:8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('İpucu: ${q.hint}'),
                ),
              ),
              if (showExp) Padding(
                padding: const EdgeInsets.only(top:4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Açıklama: ${q.exp}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PART-4 ─────────────────────────────────────────────────────────────────────
// Çeviri Yap — yön seçimi, doğruluk %, yanlış/eksik; listede sadece kaynak taraf

// Çeviri Yap — sade akış: yön seç, ref'ten getir → kaynak dolsun,
// kullanıcı hedefi yazar, Kontrol Et ile referans hedefle karşılaştır.
// Listeleme YOK, sadece iki giriş alanı + sonuç.

class CeviriYapPage extends StatefulWidget {
  final Repo repo;
  const CeviriYapPage({super.key, required this.repo});
  @override
  State<CeviriYapPage> createState() => _CeviriYapPageState();
}

class _CeviriYapPageState extends State<CeviriYapPage> {
  final src = TextEditingController();   // Kaynak metin (ref'ten gelir)
  final user = TextEditingController();  // Kullanıcının çevirisi
  bool bosToTr = true;                   // true: Bos→Tr, false: Tr→Bos
  List<TextPair> pairs = [];
  bool loading = false;

  // Seçili referansın hedef tarafını burada tutuyoruz (karşılaştırma için)
  String? _currentTargetRaw;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      pairs = await widget.repo.fetchTextPairs(limit: 1000);
    } catch (e) {
      _snack(context, 'Hata: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _pickRef() {
    if (pairs.isEmpty) {
      _snack(context, 'Önce Kelime Ekle > Çeviri’den örnek metin ekleyin.');
      return;
    }
    final p = pairs[Random().nextInt(pairs.length)];
    // Yöne göre kaynak ve hedef belirle
    final source = bosToTr ? p.bos : p.tr;
    final target = bosToTr ? p.tr : p.bos;

    src.text = source;
    _currentTargetRaw = target;

    // Yeni örnekle başlıyoruz: kullanıcı alanını ve sonucu temizle
    user.clear();
    setState(() {});
  }

  // Temiz normalizasyon: noktalama, büyük/küçük harf farkını yok say
  String _norm(String s) {
    final lower = s.toLowerCase();
    final cleaned =
        lower.replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ');
    return cleaned.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).join(' ');
  }

  String _langName(bool isBos) => isBos ? 'Boşnakça' : 'Türkçe';

  void _check() {
    if (src.text.trim().isEmpty || _currentTargetRaw == null) {
      _snack(context, 'Önce “Ref’ten getir” ile kaynak metni çekin.');
      return;
    }
    if (user.text.trim().isEmpty) {
      _snack(context, 'Lütfen çevirinizi yazın.');
      return;
    }

    final userN = _norm(user.text);
    final targetN = _norm(_currentTargetRaw!);

    final uTok = userN.split(' ');
    final tTok = targetN.split(' ');
    final uSet = Set<String>.from(uTok);
    final tSet = Set<String>.from(tTok);

    final correct = uSet.intersection(tSet).length;
    final total = tSet.isEmpty ? 1 : tSet.length;
    final percent = ((correct * 100) / total).round();

    final wrong = uSet.difference(tSet).toList();
    final missing = tSet.difference(uSet).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sonuç'),
        content: SingleChildScrollView(
          child: Text(
            'Doğruluk: %$percent\n'
            'Yanlış/Yabancı: ${wrong.isEmpty ? '-' : wrong.join(', ')}\n'
            'Eksik: ${missing.isEmpty ? '-' : missing.join(', ')}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        ],
      ),
    );
  }

  void _onDirectionChanged(bool toBosFromTr) {
    // yön değişince alanları temizle, karışıklık olmasın
    bosToTr = toBosFromTr;
    src.clear();
    user.clear();
    _currentTargetRaw = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final srcLangName = _langName(bosToTr);        // Bos→Tr ise kaynak Boşnakça
    final dstLangName = _langName(!bosToTr);       // hedef Türkçe
    return loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Yön seçimi + Ref'ten getir
                Row(
                  children: [
                    const Text('Yön:'),
                    const SizedBox(width: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Bos → Tr')),
                        ButtonSegment(value: false, label: Text('Tr → Bos')),
                      ],
                      selected: {bosToTr},
                      onSelectionChanged: (s) => _onDirectionChanged(s.first),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.auto_fix_high),
                      onPressed: _pickRef,
                      label: const Text('Ref’ten getir'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Kaynak ve Kullanıcı Çevirisi alanları (sade, geniş)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: src,
                        minLines: 5,
                        maxLines: 10,
                        readOnly: true, // Kaynak kullanıcı tarafından yazılmıyor
                        decoration: InputDecoration(
                          labelText: 'Kaynak metin ($srcLangName)',
                          hintText: '“Ref’ten getir”e basarak doldurun',
                          border: const OutlineInputBorder(),
                          suffixIcon: src.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () => setState(() => src.clear()),
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Temizle',
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: user,
                        minLines: 5,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: 'Çeviriniz (${dstLangName})',
                          hintText: '${srcLangName} metni buraya ${dstLangName} olarak çevirin',
                          border: const OutlineInputBorder(),
                          suffixIcon: user.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () => setState(() => user.clear()),
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Temizle',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _check,
                  child: const Text('Kontrol Et'),
                ),

                // İstenerek boş bırakıldı: altta referans listesi yok.
                // Ekran sade kalsın; sadece kaynak, çeviri, kontrol.
              ],
            ),
          );
  }
}


// Kelime Ekle — 3 alt form: Kelime / Çeviri / Boşluk
class KelimeEklePage extends StatefulWidget{
  final Repo repo; const KelimeEklePage({super.key, required this.repo});
  @override State<KelimeEklePage> createState()=>_KelimeEklePageState();
}
class _KelimeEklePageState extends State<KelimeEklePage>{
  int tab=0;
  @override Widget build(BuildContext context){
    final tabs=['Kelime','Çeviri','Boşluk'];
    return Column(children:[
      const SizedBox(height:8),
      ToggleButtons(
        isSelected:[tab==0,tab==1,tab==2],
        onPressed:(i)=>setState(()=>tab=i),
        children: tabs.map((e)=>Padding(
          padding: const EdgeInsets.symmetric(horizontal:16), child: Text(e))).toList(),
      ),
      const Divider(),
      Expanded(child: switch(tab){
        0 => _KelimeForm(repo:widget.repo),
        1 => _TextPairForm(repo:widget.repo),
        _ => _ClozeForm(repo:widget.repo),
      }),
    ]);
  }
}

// Kelime formu
class _KelimeForm extends StatefulWidget{
  final Repo repo; const _KelimeForm({required this.repo});
  @override State<_KelimeForm> createState()=>_KelimeFormState();
}
class _KelimeFormState extends State<_KelimeForm>{
  final bos=TextEditingController(), tr=TextEditingController(),
        gender=TextEditingController(), example=TextEditingController(),
        bulk=TextEditingController();
  String tur='isim';

  @override Widget build(BuildContext context){
    return ListView(padding: const EdgeInsets.all(12), children:[
      Text('Tekli Kelime Ekle', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      TextField(controller:bos, decoration: const InputDecoration(labelText:'Boşnakça')),
      TextField(controller:tr, decoration: const InputDecoration(labelText:'Türkçe')),
      DropdownButtonFormField<String>(
        value:tur, items: const [
          DropdownMenuItem(value:'isim', child: Text('isim')),
          DropdownMenuItem(value:'fiil', child: Text('fiil')),
          DropdownMenuItem(value:'sıfat', child: Text('sıfat')),
          DropdownMenuItem(value:'zarf', child: Text('zarf')),
          DropdownMenuItem(value:'ifade', child: Text('ifade')),
        ],
        onChanged:(v)=>setState(()=>tur=v??'isim'),
        decoration: const InputDecoration(labelText:'Tür'),
      ),
      TextField(controller:gender, decoration: const InputDecoration(labelText:'Cinsiyet (m/f/n, opsiyonel)')),
      TextField(controller:example, decoration: const InputDecoration(labelText:'Örnek cümle (opsiyonel)')),
      const SizedBox(height:6),
      Align(alignment: Alignment.centerRight, child:
        FilledButton(onPressed:() async{
          if (bos.text.trim().isEmpty || tr.text.trim().isEmpty) return;
          try{
            await widget.repo.addWord(Word(
              bos:bos.text.trim(), tr:tr.text.trim(), tur:tur,
              gender:gender.text.trim(), example:example.text.trim(),
            ));
            _snack(context,'Kelime eklendi'); bos.clear(); tr.clear(); gender.clear(); example.clear();
          }catch(e){ _snack(context,'Hata: $e'); }
        }, child: const Text('Kelimeyi Ekle')),
      ),
      const Divider(height:28),
      Text('Toplu Kelime Ekle', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      Text('Format (her satır): bos; tr; tür; örnek; cinsiyet (son ikisi opsiyonel)',
        style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height:6),
      TextField(controller:bulk, minLines:6, maxLines:10,
        decoration: const InputDecoration(border: OutlineInputBorder(), hintText:'Çoklu giriş')),
      const SizedBox(height:6),
      Align(alignment: Alignment.centerRight, child:
        FilledButton.icon(icon: const Icon(Icons.upload), label: const Text('Toplu Kelime Yükle'),
          onPressed:() async{
            final lines=bulk.text.split('\n').where((e)=>e.trim().isNotEmpty).toList();
            final list=<Word>[];
            for(final line in lines){
              final sep=line.contains(';')?';':',';
              final p=line.split(sep).map((e)=>e.trim()).toList();
              if (p.length<3) continue;
              list.add(Word(
                bos:p[0], tr:p[1], tur:p[2],
                example:p.length>3?p[3]:'', gender:p.length>4?p[4]:'',
              ));
            }
            await widget.repo.addWordsBulkSafe(list);
            _snack(context,'Toplu kelime tamam');
          }),
      ),
    ]);
  }
}

// Çeviri formu
class _TextPairForm extends StatefulWidget{
  final Repo repo; const _TextPairForm({required this.repo});
  @override State<_TextPairForm> createState()=>_TextPairFormState();
}
class _TextPairFormState extends State<_TextPairForm>{
  final bos=TextEditingController(), tr=TextEditingController(), bulk=TextEditingController();
  @override Widget build(BuildContext context){
    return ListView(padding: const EdgeInsets.all(12), children:[
      Text('Tekli Metin Ekle', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      TextField(controller:bos, decoration: const InputDecoration(labelText:'Boşnakça')),
      TextField(controller:tr, decoration: const InputDecoration(labelText:'Türkçe')),
      const SizedBox(height:6),
      Align(alignment: Alignment.centerRight, child:
        FilledButton(onPressed:() async{
          if (bos.text.trim().isEmpty || tr.text.trim().isEmpty) return;
          await widget.repo.addTextPair(bos:bos.text.trim(), tr:tr.text.trim());
          _snack(context,'Metin eklendi'); bos.clear(); tr.clear();
        }, child: const Text('Metni Ekle')),
      ),
      const Divider(height:28),
      Text('Toplu Metin Ekle (satır: bos; tr)', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      TextField(controller:bulk, minLines:6, maxLines:10,
        decoration: const InputDecoration(border: OutlineInputBorder(), hintText:'Çoklu giriş')),
      const SizedBox(height:6),
      Align(alignment: Alignment.centerRight, child:
        FilledButton.icon(icon: const Icon(Icons.upload), label: const Text('Toplu Metin Yükle'),
          onPressed:() async{
            final lines=bulk.text.split('\n').where((e)=>e.trim().isNotEmpty).toList();
            final items=<TextPair>[];
            for(final line in lines){
              final sep=line.contains(';')?';':',';
              final p=line.split(sep).map((e)=>e.trim()).toList();
              if (p.length<2) continue;
              items.add(TextPair(bos:p[0], tr:p[1]));
            }
            await widget.repo.addTextPairsBulk(items);
            _snack(context,'Toplu metin tamam');
          }),
      ),
    ]);
  }
}

// Boşluk Doldurma formu
class _ClozeForm extends StatefulWidget{
  final Repo repo; const _ClozeForm({required this.repo});
  @override State<_ClozeForm> createState()=>_ClozeFormState();
}
class _ClozeFormState extends State<_ClozeForm>{
  final sentence=TextEditingController(), bulk=TextEditingController();
  String lang='bos';
  @override Widget build(BuildContext context){
    return ListView(padding: const EdgeInsets.all(12), children:[
      Text('Boşluk Doldurma – Tekli', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      TextField(controller:sentence, decoration: const InputDecoration(labelText:'Cümle')),
      DropdownButtonFormField<String>(
        value:lang, items: const [
          DropdownMenuItem(value:'bos', child: Text('Boşnakça')),
          DropdownMenuItem(value:'tr',  child: Text('Türkçe')),
        ],
        onChanged:(v)=>setState(()=>lang=v??'bos'),
        decoration: const InputDecoration(labelText:'Dil'),
      ),
      const SizedBox(height:6),
      Align(alignment: Alignment.centerRight, child:
        FilledButton(onPressed:() async{
          if (sentence.text.trim().isEmpty) return;
          await widget.repo.addClozeOne(sentence:sentence.text.trim(), lang:lang);
          _snack(context,'Cümle eklendi'); sentence.clear();
        }, child: const Text('Cümleyi Ekle')),
      ),
      const Divider(height:28),
      Text('Boşluk Doldurma – Toplu (satır: cümle; dil(bos|tr))',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      TextField(controller:bulk, minLines:6, maxLines:10,
        decoration: const InputDecoration(border: OutlineInputBorder(), hintText:'Çoklu giriş')),
      const SizedBox(height:6),
      Align(alignment: Alignment.centerRight, child:
        FilledButton.icon(icon: const Icon(Icons.upload), label: const Text('Toplu Yükle'),
          onPressed:() async{
            final lines=bulk.text.split('\n').where((e)=>e.trim().isNotEmpty).toList();
            final items=<Map<String,String>>[];
            for(final line in lines){
              final sep=line.contains(';')?';':',';
              final p=line.split(sep).map((e)=>e.trim()).toList();
              if (p.isEmpty) continue;
              final s=p[0]; final l=p.length>1?(p[1].isEmpty?'bos':p[1]):'bos';
              items.add({'sentence':s,'lang':l});
            }
            await widget.repo.addClozeBulk(items);
            _snack(context,'Toplu cloze tamam');
          }),
      ),
    ]);
  }
}

// Padej Alanı — kısa özet + MCQ
class PadezAlaniPage extends StatefulWidget{ const PadezAlaniPage({super.key});
  @override State<PadezAlaniPage> createState()=>_PadezAlaniPageState(); }
class _PadezAlaniPageState extends State<PadezAlaniPage>{
  final rnd=Random();
  final rules=[
    'Akuzativ: koga/šta? – yönelim/nesne. Ör: Vidim (koga?) brata.',
    'Genitiv: koga/čega? – sahiplik/yokluk/miktar. Ör: Nema (čega?) vremena.',
    'Dativ: kome/čemu? – yönelme/alıcı. Ör: Pomažem (kome?) prijatelju.',
    'Lokativ: o kome/čemu? – yer/konu (prepozisyonla). Ör: Govorim o (čemu?) poslu.',
  ];
  final questions=<(String,List<String>,int)>[
    ('Hangi padež nesneyi belirtir?',['Genitiv','Akuzativ','Dativ','Lokativ'],1),
    ('“Govorim o poslu.” cümlesinde padež?',['Akuzativ','Genitiv','Lokativ','Dativ'],2),
    ('“Pomažem prijatelju.” cümlesinde padež?',['Dativ','Akuzativ','Genitiv','Lokativ'],0),
    ('“Nema vremena.” cümlesinde padež?',['Genitiv','Akuzativ','Dativ','Lokativ'],0),
  ];
  late (String,List<String>,int) current;
  @override void initState(){ super.initState(); _pick(); }
  void _pick(){ current=questions[rnd.nextInt(questions.length)]; setState((){}); }

  @override Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(children:[
        Text('Kısa Özet', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        for(final r in rules) Padding(padding: const EdgeInsets.only(bottom:6), child: Text('• $r')),
        const Divider(height:24),
        Text('Soru', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        Text(current.$1),
        const SizedBox(height:8),
        for(int i=0;i<current.$2.length;i++)
          Padding(padding: const EdgeInsets.symmetric(vertical:6),
            child: FilledButton.tonal(
              onPressed: (){
                final ok=i==current.$3;
                _snack(context, ok? 'Tačno ✅':'Ne tačno ❌');
                Future.delayed(const Duration(milliseconds:300), _pick);
              },
              child: Padding(padding: const EdgeInsets.all(12), child: Text(current.$2[i])),
            ),
          ),
      ]),
    );
  }
}
