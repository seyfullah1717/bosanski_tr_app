import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  // Tekli ekleme alanları
  final _bosCtrl = TextEditingController();
  final _trCtrl = TextEditingController();
  final _turCtrl = TextEditingController(text: 'isim'); // isim/fiil/sıfat/zarf/ifade
  final _ornekCtrl = TextEditingController();
  final _cinsCtrl = TextEditingController(); // m/f/n (opsiyonel)

  // Toplu ekleme alanı
  final _bulkCtrl = TextEditingController();

  bool _busy = false;

  // ------------------------------------------------------------
  // Yardımcılar
  // ------------------------------------------------------------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _normalizeTur(String raw) {
    final v = raw.trim().toLowerCase();
    const allowed = {'isim', 'fiil', 'sıfat', 'zarf', 'ifade', 'sifat'}; // 'sıfat' yazılamazsa 'sifat' da kabul
    if (!allowed.contains(v)) return 'isim';
    return v == 'sifat' ? 'sıfat' : v;
  }

  String? _normalizeCinsiyet(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == 'm' || v == 'f' || v == 'n') return v;
    return null; // yanlışsa boş say
  }

  Map<String, dynamic>? _parseLineToRow(String line, int index) {
    // Yorum/boş satırları at
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('#') || trimmed.startsWith('//')) return null;

    final parts = trimmed.split(';');
    if (parts.length < 3) {
      // En az bos; tr; tur olmalı
      debugPrint('[SKIP] Satır $index → 3 alandan az: "$line"');
      return null;
    }

    final bos = parts[0].trim();
    final tr = parts[1].trim();
    final tur = _normalizeTur(parts[2]);

    if (bos.isEmpty || tr.isEmpty || tur.isEmpty) {
      debugPrint('[SKIP] Satır $index → boş zorunlu alan var: "$line"');
      return null;
    }

    final ornek = (parts.length > 3 ? parts[3].trim() : '');
    final cins = (parts.length > 4 ? _normalizeCinsiyet(parts[4]) : null);

    return {
      'bos': bos,
      'tr': tr,
      'tur': tur,
      if (ornek.isNotEmpty) 'ornek': ornek,
      if (cins != null) 'cinsiyet': cins,
    };
  }

  List<Map<String, dynamic>> _parseBulk(String raw) {
    final rows = <Map<String, dynamic>>[];
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    var i = 0;
    for (final line in lines) {
      i++;
      final row = _parseLineToRow(line, i);
      if (row != null) rows.add(row);
    }
    return rows;
  }

  // ------------------------------------------------------------
  // Supabase işlemleri
  // ------------------------------------------------------------
  Future<void> _insertSingle() async {
    final bos = _bosCtrl.text.trim();
    final tr = _trCtrl.text.trim();
    final tur = _normalizeTur(_turCtrl.text);
    final ornek = _ornekCtrl.text.trim();
    final cins = _normalizeCinsiyet(_cinsCtrl.text);

    if (bos.isEmpty || tr.isEmpty || tur.isEmpty) {
      _snack('Boş alan var (bos/tr/tur zorunlu).');
      return;
    }

    final payload = <String, dynamic>{
      'bos': bos,
      'tr': tr,
      'tur': tur,
      if (ornek.isNotEmpty) 'ornek': ornek,
      if (cins != null) 'cinsiyet': cins,
    };

    setState(() => _busy = true);
    try {
      final supa = Supabase.instance.client;
      await supa.from('words').insert(payload);
      _snack('Tekli kayıt eklendi ✅');

      _bosCtrl.clear();
      _trCtrl.clear();
      _ornekCtrl.clear();
      _cinsCtrl.clear();
    } catch (e, st) {
      debugPrint('Tekli insert hata: $e\n$st');
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _insertBulk() async {
    final raw = _bulkCtrl.text.trim();
    if (raw.isEmpty) {
      _snack('Toplu alan boş.');
      return;
    }

    setState(() => _busy = true);
    try {
      final allRows = _parseBulk(raw);
      if (allRows.isEmpty) {
        _snack('Geçerli satır bulunamadı (formatı kontrol et).');
        return;
      }

      final supa = Supabase.instance.client;
      const chunkSize = 300; // güvenli payload
      int ok = 0;
      int fail = 0;

      for (int i = 0; i < allRows.length; i += chunkSize) {
        final chunk = allRows.sublist(i, min(i + chunkSize, allRows.length));
        try {
          await supa.from('words').insert(chunk);
          ok += chunk.length;
        } catch (e) {
          fail += chunk.length;
          debugPrint('Chunk insert hata: $e (satırlar ${i + 1}-${i + chunk.length})');
        }
      }

      _snack('Toplu ekleme bitti: $ok ok ✅ / $fail fail ❌');
      if (ok > 0) _bulkCtrl.clear();
    } catch (e, st) {
      debugPrint('Toplu insert genel hata: $e\n$st');
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli — Supabase'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Tekli Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field('Boşnakça (bos)*', _bosCtrl, width: 280),
                _field('Türkçe (tr)*', _trCtrl, width: 280),
                _field('Tür (isim/fiil/sıfat/zarf/ifade)*', _turCtrl, width: 260),
                _field('Cinsiyet (m/f/n)', _cinsCtrl, width: 160),
              ],
            ),
            const SizedBox(height: 8),
            _field('Örnek cümle (opsiyonel)', _ornekCtrl, maxLines: 2),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _insertSingle,
              icon: const Icon(Icons.add),
              label: const Text('Tekli Ekle (Supabase)'),
            ),
            const Divider(height: 32),

            const Text('Toplu Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Her satır şu formatta olmalı:\n'
              'bos; tr; tur; [ornek]; [cinsiyet]\n'
              '• tur: isim | fiil | sıfat | zarf | ifade\n'
              '• cinsiyet (opsiyonel): m | f | n\n'
              'Örnek:\n'
              'voda; su; isim; Voda je hladna.; f\n'
              'brat; erkek kardeş; isim; Imam jednog brata.; m\n'
              'učiti; öğrenmek; fiil; Svaki dan učim Bosanski.;\n',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            _field('Toplu yapıştır (binlerce satır olabilir)', _bulkCtrl, maxLines: 10),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _insertBulk,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Toplu Ekle (Supabase)'),
            ),
            const SizedBox(height: 12),
            Text(
              'İpucu: Çok büyük listelerde eklemeler anlık gerçekleşir; tüm kullanıcılar **sayfayı yenilemeden** bile yeni verileri görür (senin stream/yeniden yükleme mantığına bağlı).',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1, double? width}) {
    final tf = TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
    if (width == null) return tf;
    return SizedBox(width: width, child: tf);
  }

  @override
  void dispose() {
    _bosCtrl.dispose();
    _trCtrl.dispose();
    _turCtrl.dispose();
    _ornekCtrl.dispose();
    _cinsCtrl.dispose();
    _bulkCtrl.dispose();
    super.dispose();
  }
}
