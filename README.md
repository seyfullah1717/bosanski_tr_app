\# Bosanski TR 🇧🇦➡🇹🇷



Boşnakça ↔ Türkçe öğrenme uygulaması.



Flutter ile yazıldı, hedef: günlük konuşma + refleks + gramer pratiği.

Uygulama web'de çalışıyor ve Firebase ile paylaşılabilir hale geliyor.



---



\## 🧠 Özellikler



\### 1. Kelime Öğren

\- Boşnakça → Türkçe sözlük kartları

\- tür: isim / fiil / sıfat / zarf / ifade

\- cinsiyet etiketi (Eril / Dişil / Nötr)

\- örnek cümle gösterimi

\- arama (hem Boşnakça hem Türkçe)

\- kategori filtreleme

\- toplu kelime ekleme (admin paneli)



\### 2. Ezber Yap

\- Çoktan seçmeli refleks quiz

\- 1 soru + 4 şık formatı

\- cevap seçince "Tačno ✅" / "Netačno ❌"

\- otomatik sıradaki soruya geçiyor

\- skor takibi: Doğru / Toplam / %



\### 3. Boşluk Doldur

\- Cloze test tipi: "Ja pijem \_\_\_\_."

\- serbest yazıyorsun, butonla kontrol ediyorsun

\- yanlışsa doğru cevabı gösteriyor

\- otomatik yeni soruya atlıyor



\### 4. Soru Sor

\- Soru zarfları pratiği (Gdje / Kada / Kako / Zašto…)

\- boşluklu soru formatı: "\_\_\_\_\_ živiš?"

\- şıklar Boşnakça (Türkçe değil)

\- skor takibi var



\### 5. Çeviri Yap

\- Mod seçimi: Boşnakça→Türkçe / Türkçe→Boşnakça

\- üstte referans paragraf (hocanın metni)

\- altta senin çevirin için alan

\- "Kontrol Et" deyince:

&nbsp; - kaç kelime doğru

&nbsp; - yüzde başarı

&nbsp; - zayıf kelimeleri listeliyor



\### 6. Padež Alanı

\- Dilbilgisi / hâl çekimi pratiği (akuzativ, lokativ vs.)

\- 1 soru + 4 şık

\- yanlışta açıklama gösteriyor:

&nbsp; - ör: "u + lokativ = nerede?"

\- skor takibi var



---



\## 🎛 Tema Desteği

\- Açık mod

\- Koyu mod

\- Soft / göz yormayan morumsu tema

\- AppBar’daki ikonla anlık değiştirilebiliyor



---



\## 🛠 Admin Paneli

Uygulamada dahili "Ekle" ekranı var. Her kullanıcı şu anda admin gibi davranabiliyor (lokal kayıt).



Buradan şunlar ekleniyor:

\- Kelime listesi (tekli veya toplu)

\- Ezber sorusu (tekli / toplu)

\- Boşluk doldurma sorusu (tekli)

\- Soru zarfı sorusu

\- Padež sorusu (tekli / toplu)

\- Çeviri paragrafı (Boşnakça metin + Türkçe referans çeviri)



Veriler şu anda cihazda/local saklanıyor. İleride Firestore ile paylaşılacak.



---



\## 🚀 Teknoloji

\- Flutter

\- Web build (flutter run -d web-server)

\- Firebase Hosting (planlandı)

\- SharedPreferences / lokal state (şu an)

\- Firestore senkronizasyon (gelecek sürüm)



---



\## Durum

Bu proje Boşnakça öğrenen Türk kullanıcı için pratik hızlı uygulama.

Odak: hız, tekrar, refleks. Ezber zorlamak. 



