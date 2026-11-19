# Sürüm notları

## 0.2.1
- Donma düzeltmeleri (özellikle telefon): telefonda ek ışıklar kapalı (meşale, sandık, eşya, mermi ışıkları; uyumluluk çiziminde her ışık ek bir çizim turu demek), 3B çözünürlük telefonda %75 (Düşük: %60), telefonda gölge kapalı (Yüksek hariç).
- Altın artık yere düşmüyor, doğrudan sana geçiyor (yüzlerce altın yığını birikip oyunu yavaşlatıyordu). Yerde en fazla 15 eşya kalır, fazlası çantaya gider.
- Bir dalgada en fazla 30 düşman (sonrası daha güçlü düşmanlarla zorlaşır); aynı anda ekranda telefonda 16, bilgisayarda 30 düşman.
- Duraklatma menüsü iki sütun: telefonda tüm düğmeler görünüyor. "KARAKTER DEĞİŞTİR" eklendi.
- Ana menü tek ekran: üç karakter kartı doğrudan seçilip oynanır.
- Neden: Telefonda 24. dalgada FPS 24'e düşüyordu ve duraklatma menüsünün alt düğmeleri ekrana sığmıyordu.

## 0.2.0
- **Karakter seçimi:** Kılıç Muhafızı, Gölge Avcı (arbalet, Çoklu Atış, Ok Yağmuru, Gölge Adımı, Zehir Bombası, Gölge Fırtınası) ve Kül Büyücü (Ateş Topu, Alev Halkası, Buz Fırtınası, Işınlanma, Meteor Yağmuru, Kül Kıyameti). Her sınıfın kendi kanat rengi var.
- **Kayıt ve devam:** Her sınıfın ayrı kaydı var. Ana menüde "DEVAM ET" kaldığın dalgadan başlatır; seviye, eşya, çanta ve altın saklanır. Ana menüye dönünce, uygulama kapanınca ya da arka plana geçince otomatik kayıt. Ölünce ilerleme kaybolmaz, son kontrol noktasından (1, 6, 11. dalga...) devam edilir.
- **Sandıklar:** Duvar diplerindeki 4 altın sandık yanına gelince açılır (altın, iksir, eşya). Her 5 dalgada yeniden dolar; haritada sarı kare olarak görünür.
- **Son Sığınak (kasaba):** Her 5 dalgadan sonra ve duraklatma menüsünden açılır. Demirci Haldun eşyaları +10'a kadar yükseltir; Simyacı Nevra iksir, Kanat Tüyü ve tam iyileşme satar; Tüccar Kerem gizemli eşya sandıkları satar.
- Neden: Karakter seçimi yoktu, ana menüye dönünce ilerleme kayboluyordu, sandıklar açılmıyordu ve toplanan altının kullanılacağı bir yer yoktu.

## 0.1.2
- Takılma düzeltmeleri: kritik vuruşta oyunu bir anlığına durduran efekt kaldırıldı; parçacık efektleri önbellekten kullanılıyor ve aynı anda çalışan efekt sayısı sınırlı; açılışta efektler önceden yükleniyor; altın yığınlarındaki ışıklar kaldırıldı.
- Grafik kalitesi ayarı: Düşük / Orta / Yüksek (ana menü ve duraklatma menüsü). F3: FPS göstergesi.
- Envanter: toplanan eşyalar artık çantaya giriyor (24 yer). I tuşu, telefonda sağ üstteki çanta düğmesi ya da duraklatma menüsünden açılır. Eşyayı tak, çıkar, sat; takılı olanla karşılaştırma (yeşil ▲ daha iyi). Sıradan eşyaları tek düğmeyle satma.
- Neden: Oyun parça parça donuyordu ve toplanan eşyaların nereye gittiği görünmüyordu.

## 0.1.1
- Telefonda grafik sistemi OpenGL ES 3'e (Godot "Compatibility") geçirildi; bilgisayar Vulkan ile devam ediyor.
- Neden: Android öykünücü testinde oyun açılıp çalıştı ama Vulkan sürücüsü yüzünden ekran siyah kaldı; aynı sorun bazı telefonlarda da görülebiliyor. OpenGL ES 3 hemen her telefonda çalışır.

## 0.1.0 - İlk oynanabilir sürüm
- Kılıç Muhafızı, 1. bölüm haritası (Kül Ovaları - Yıkık Mahzen), dalga dalga gelen iskeletler, 10. dalgada Kor Avcısı Garran.
- 5 yetenek + son vuruş (Kanat Açılımı), seviye ve tecrübe, rastgele özellikli eşyalar, altın ve iksir.
- Telefon için çoklu dokunuş destekli kayan joystick ve yay şeklinde dizilmiş, birbirine binmeyen düğmeler.
- Küçük harita ve dokununca açılan büyük harita.
- Açılışta yeni sürüm kontrolü.
- Neden: Kanatix Arcade'den daha uzun soluklu, ilerlemeli bir oyun istendi; tasarım belgesindeki Aşama 0 ve Aşama 1'in ilk parçası.
