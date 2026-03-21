# Dijital Dini Takvim Geliştirme Planı

Bu belge, uygulamanın teknik ve tasarımsal olarak iyileştirilmesi, tamamen Diyanet API altyapısına geçilmesi ve genel kullanıcı deneyiminin (UX/UI) artırılmasını amaçlayan yol haritasıdır.

## ✅ TAMAMLANANLAR (Faz 1 - Faz 5)
1. **Diyanet API Kapsam Matrisi:** Diyanet Awqat Salah API'den alınabilecek tüm veriler (namaz vakitleri, dini günler vs.) incelendi ve belgelendi.
2. **Node.js Sync Script & Fallbacks:** Aylık Diyanet verilerini çekip JSON olarak kaydedecek `sync-diyanet-to-json.js` Node.js betiği yazıldı.
3. **GitHub Actions (No-Blaze) Mimari:** Sunucusuz bir yapı kurularak aylık senkronizasyon otomatik hale getirildi. Veriler GitHub üzerinden ham (raw) JSON olarak sunulmaya başlandı. Firebase gibi backend sistemleri tamamen iptal edildi.
4. **Mobil App JSON Cache-First Mimari:** Uygulama, açılışta veya güncellemelerde statik JSON dosyasını çekip yerel cihazda loglayacak (cache) duruma getirildi.
5. **Bildirim Sistemi (Dakika, Ezan, Vecize):** Kullanıcının ayarladığı dakika öncesinde hatırlatma yapma, ezan saatinde istenilen sesi çalma ve "Günün İçerikleri" (Vecize/Ayet/Hadis) için zamanlanmış bildirim altyapısı geliştirildi.

---

## 🚀 YAPILACAKLAR (Kalan İşler)

### [ ] Faz 6: Ana Namaz Vakitleri ve Takvim Ekranı Revizyonu
- **Tasarım Yenileme:** Namaz vakitleri ekranındaki sekmeli yapı kaldırılacak. O günkü vakitler modern tasarımla (ikonlar vb.) ve renk uyumuyla sunulup, ekranın altında sonraki 3 günün de listelenmesi sağlanacak. Dini yapıya uygun profesyonel semboller kullanılacak.
- **Hicri Takvim Optimizasyonu:** Günler arası geçiş yaparken hicri takvim metninin yüklenme/gecikme yapma sorunu çözülecek. Veri önden yüklendiği için "loading" durumu kaldırılacak.
- **Kıble Pusulası:** Diyanet API'nin sağladığı kıble açıları değerlendirilip pusula ekranı/verisi güncellenecek.
- **Konum Senkronizasyonu:** Tüm lokasyonlar Diyanet şehir/ilçe listesiyle tam eşgüdümlü çalışacak.
- **Ana Ekran Widget'ları:** Çok daha göze hitap eden, uygulamanın temasına uygun şık widget'lar (namaz vakitleri vs.) tasarlanacak.

### [ ] Faz 7: Dini Günler ve İçerik Yenilemesi
- **Günün Yemek Menüsü:** Takvim sayfasındaki yemek kısmı `nurvakti_genel_takvim.json` verisi ile bağlanıp "gerçek menülerle" takvim yaprağı görünümü tamamlanacak.
- **Dini Günler ve Geceler Sistemi:** Dini Günler listesindeki "60 gün içinde yaklaşanlar" mekanizması; statik listeler veya mevcut yerel hesaplardan ziyade, **doğrudan Diyanet API'den elde edilen dini günler listesi** kullanılarak yıllar boyunca kusursuz çalışacak şekilde refaktör edilecek. Diyanet API'nin sağladığı her şey değerlendirilecek.

### [ ] Faz 8: Tema, Zikirmatik ve Ayarlar (UX/UI Fixes)
- **Ayarlar Ekranı:** Daha modern, göze hitap eden (UI) bir ayarlar ekranı yapılacak.
- **Tema ve Fontlar:** Açık / Koyu tema (Light/Dark mode) değişimini ve Font ayarlamalarını sistemi bozmadan, tam çalışan stabil bir yapıya kavuşturulacak.
- **Zikirmatik Hatası (Bug Fix):** Zikirmatik ekranında zikir eklerken (text input açıldığında klavye nedeniyle oluşan) **bottom overflowed by 72 pixels** hatası giderilecek.

### [ ] Faz 9: Genel Performans, Geçiş ve Hız (Optimizasyon)
- **Sistem İçi Geçişler:** Ekranlar menüler arası geçişlerdeki takılmalar kaldırılıp, daha pürüzsüz "yağ gibi" akan geçişler kodlanacak.
- **İlk Açılış Hızı (Cold Start):** Uygulama başlatılırken kasma/takılma olmadan rahatça açılması sağlanacak. Arayüz ve arka plan servislerindeki asenkron yüklenmeler optimize edilecek.
