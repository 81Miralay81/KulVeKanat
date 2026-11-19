# Kanatix: Kül ve Kanat

Yukarıdan eğik kameralı bir aksiyon RPG: düşmanları kesip seviye atlıyorsun, yeteneklerin güçleniyor, eşya topluyorsun.
Kanatix yazılım ailesinin bir parçası. Godot 4.6 ile yapıldı; Windows (exe) ve Android (APK) için derlenir.

## İndir

[Son sürüm](https://github.com/81Miralay81/KulVeKanat/releases/latest): `KulVeKanat.exe` (Windows) ve `KulVeKanat.apk` (Android).

Oyun her açılışta yeni sürüm olup olmadığına bakar; varsa ana menüde "YENİ SÜRÜMÜ İNDİR" düğmesi çıkar.

## Bu sürümde neler var (0.2)

- **Sınıflar:** Kılıç Muhafızı (yakın dövüş), Gölge Avcı (arbalet, uzaktan), Kül Büyücü (alan büyüleri); her sınıfın ayrı kaydı
- **Kasaba (Son Sığınak):** demirci (eşya yükseltme), simyacı (iksir), tüccar (gizemli sandıklar)
- **Sandıklar:** köşelerde, yanına gelince açılır, her 5 dalgada dolar
- **Kayıt:** kaldığın dalgadan devam; ölünce son kontrol noktasından
- **Harita:** 1. bölüm, Kül Ovaları - Yıkık Mahzen
- **Düşmanlar:** Kül İskeleti, Kül Haydudu, Kül Muhafızı, Kül Büyücüsü (uzaktan büyü atar), elit düşmanlar,
  her 10. dalgada boss: **Kor Avcısı Garran**
- **Yetenekler:** Kılıç Darbesi (3'lü kombo), Kor Kasırgası (seviye 1), Kanat Atılımı (seviye 2),
  Yer Yarma (seviye 3), Meteor Yağmuru (seviye 5), Kanat Açılımı (son vuruş, düşman kestikçe dolar)
- **İlerleme:** tecrübe ve seviye, rastgele özellikli eşyalar (Sıradan, Büyülü, Nadir, Efsanevi), altın, iksir
- **Harita:** köşede küçük harita; dokununca / tıklayınca (ya da M tuşu) büyük harita açılır

## Kontroller

| İşlem | Bilgisayar | Telefon |
| --- | --- | --- |
| Yürü | W A S D | Sol yarıda parmağını koyduğun yerden kayan joystick |
| Saldır | Sol tık / J (basılı tut) | Büyük kılıç düğmesi (basılı tut) |
| Kor Kasırgası | Sağ tık / 1 | Sarmal simgeli düğme |
| Yer Yarma | 2 | Çatlak simgeli düğme |
| Kanat Atılımı | Boşluk / 3 | Kanat simgeli düğme |
| Meteor Yağmuru | 4 | Meteor simgeli düğme |
| Kanat Açılımı | R | Yaydaki altın kanat (dolunca parlar) |
| İksir | Q | Kırmızı şişe |
| Harita | M / Tab | Sağ üstteki küçük haritaya dokun |
| Duraklat | ESC | Sağ üstteki ‖ düğmesi |

Oyun kolu (Xbox tipi) da çalışır.

## Telefon dokunmatiği nasıl çalışıyor

- Her parmak kendi numarasıyla izlenir: aynı anda yürüyüp saldırabilir, yetenek kullanabilirsin; bir parmağı kaldırmak diğerini etkilemez.
- Ekran boyutu ve oranı ne olursa olsun düğmeler yeniden yerleşir; dokunma noktası ile görüntü hep aynı yerdedir.
- Uygulama arka plana geçerse ya da bir bırakma olayı kaybolursa bütün düğmeler bırakılır: karakter kendi kendine yürümez.
- Dokunmatikten üretilen sahte fare olayları oyunda yok sayılır, çift tetikleme olmaz.

## Geliştirme

- Motor: Godot 4.6.2. Kodlar `kodlar/`, ana sahne `sahneler/ana.tscn`.
- Otomatik test: `godot --path . -- --otomatik-test` (oyunu başlatır, yetenekleri ve dokunmatiği dener, ekran görüntüsü alır).
- Derleme: `main` dalına her gönderimde GitHub Actions exe ve APK'yı derleyip sürüm olarak yayınlar; APK ayrıca Android öykünücüsünde açılıp denenir.
- Simge: `python marka/kulkanat.py`, yetenek simgeleri `python marka/ikonlar.py`, sesler `python marka/sesler.py`.

## Teşekkürler ve lisanslar

- 3B modeller ve animasyonlar: [KayKit](https://kaylousberg.itch.io/) (Kay Lousberg) - Adventurers, Skeletons ve Dungeon Remastered paketleri, **CC0** lisanslı.
- Yazı tipleri: Cinzel ve Rajdhani, **SIL Open Font License** (Google Fonts).
- Sesler ve müzik bu proje için kodla üretildi (`marka/sesler.py`).
