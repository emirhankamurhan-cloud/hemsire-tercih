import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HemsireTercihApp());
}

class HemsireTercihApp extends StatelessWidget {
  const HemsireTercihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hemşire Tercih Rehberi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0D9488),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0D9488),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class Hospital {
  final String id, name, city, district, type, workLoad, incentive, shift, rentRange, review;
  final double kpss2024, kpss2025;

  Hospital({
    required this.id, required this.name, required this.city, required this.district,
    required this.type, required this.kpss2024, required this.kpss2025,
    required this.workLoad, required this.incentive, required this.shift,
    required this.rentRange, required this.review,
  });
}

// --- DEVASA VERİ HAVUZU ---
final List<String> rawData = [
  "tokat_devlet|Tokat Devlet Hastanesi|Tokat|Merkez|Devlet Hastanesi|73.2|72.8|6/10|7.500-11.000 TL|24 Saat Nöbet|10.000-15.000 TL|Merkezde yaşam çok rahat, masraflar düşük. Nöbet ve ekip uyumu iyi.",
  "tokat_zile|Tokat Zile Devlet Hastanesi|Tokat|Zile|Devlet Hastanesi|72.4|72.0|5/10|5.500-8.500 TL|24 Saat & Blok Off|8.000-12.000 TL|Sakin ve stressiz bir ortam. Blok nöbetlerle uzun izinler ayarlanabiliyor.",
  "tokat_turhal|Tokat Turhal Devlet Hastanesi|Tokat|Turhal|Devlet Hastanesi|72.5|72.1|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Merkeze 20 dk. İkinci basamak düzenli ilçe hastanesi.",
  "tokat_resadiye|Tokat Reşadiye Devlet Hastanesi|Tokat|Reşadiye|Devlet Hastanesi|71.9|71.5|4/10|4.000-7.000 TL|24 Saat Nöbet|8.000-12.000 TL|İş yükü sakin, birikim yapmak için elverişli.",
  "tokat_niksar|Tokat Niksar Devlet Hastanesi|Tokat|Niksar|Devlet Hastanesi|72.2|71.8|5/10|5.000-8.000 TL|24 Saat Nöbet|8.500-12.500 TL|Yeşillikler içinde sakin bir ilçe.",
  "tokat_erbaa|Tokat Erbaa Devlet Hastanesi|Tokat|Erbaa|Devlet Hastanesi|72.6|72.1|6/10|6.500-9.500 TL|24 Saat Nöbet|10.000-14.000 TL|Tokat’ın en büyük ilçesi. Hareketli ve donanımlı.",
  "tokat_almus|Tokat Almus Devlet Hastanesi|Tokat|Almus|Devlet Hastanesi|71.8|71.4|4/10|4.000-6.500 TL|24 Saat Nöbet|7.000-10.000 TL|Göl kenarında doğa harikası küçük ilçe.",
  "samsun_sehir|Samsun Şehir Hastanesi|Samsun|Canik|Şehir Hastanesi|74.2|73.8|8/10|12.000-16.000 TL|24 Saat & 16-8|15.000-22.000 TL|Bina ve donanım son teknoloji. Canik bölgesinde ev kiraları uygun.",
  "samsun_eah|Samsun Eğitim ve Araştırma Hastanesi|Samsun|İlkadım|Eğitim ve Araştırma|73.8|73.5|7/10|8.000-12.000 TL|24 Saat Nöbet|14.000-20.000 TL|Merkezi konumda, köklü kadro.",
  "samsun_gazi|Samsun Gazi Devlet Hastanesi|Samsun|İlkadım|Devlet Hastanesi|73.5|73.1|6/10|7.000-10.000 TL|08:00-08:00 & 8-16|13.000-18.000 TL|Ağır vakalar sevk edildiği için nöbet temposu daha sakindir.",
  "samsun_carsamba|Samsun Çarşamba Devlet Hastanesi|Samsun|Çarşamba|Devlet Hastanesi|73.2|72.7|6/10|6.500-9.500 TL|24 Saat Nöbet|10.000-15.000 TL|Merkeze dolmuşla 30 dk.",
  "samsun_bafra|Samsun Bafra Devlet Hastanesi|Samsun|Bafra|Devlet Hastanesi|73.4|72.9|7/10|7.000-10.000 TL|24 Saat Nöbet|11.000-16.000 TL|Büyük ilçe hastanesi, acili hareketli.",
  "samsun_vezirkopru|Samsun Vezirköprü Devlet Hastanesi|Samsun|Vezirköprü|Devlet Hastanesi|72.8|72.3|5/10|5.500-8.500 TL|24 Saat Nöbet|8.500-12.000 TL|Yeni binasında hizmet veriyor.",
  "sinop_ataturk|Sinop Atatürk Devlet Hastanesi|Sinop|Merkez|Devlet Hastanesi|73.1|72.7|5/10|7.000-10.500 TL|24 Saat Nöbet|12.000-17.000 TL|Deniz kenarında huzurlu şehir. Sahil yaşamı sevenlere birebir.",
  "sinop_boyabat|Sinop Boyabat 75. Yıl Devlet Hastanesi|Sinop|Boyabat|Devlet Hastanesi|72.4|71.9|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Gelişmiş ilçe, hastane ortamı rahat.",
  "sinop_ayancik|Sinop Ayancık Devlet Hastanesi|Sinop|Ayancık|Devlet Hastanesi|72.2|71.8|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-12.000 TL|Sahil şeridinde küçük şirin bir kurum.",
  "adana_sehir|Adana Şehir Hastanesi|Adana|Yüreğir|Şehir Hastanesi|74.2|73.8|8/10|11.000-14.000 TL|24 Saat|15.000-20.000 TL|Bölgenin ana referans merkezi.",
  "adana_seyhan|Adana Seyhan Devlet Hastanesi|Adana|Seyhan|Devlet Hastanesi|73.9|73.5|6/10|8.000-10.000 TL|24 Saat|13.000-18.000 TL|Şehir merkezinde rahat kurum.",
  "adiyaman_eah|Adıyaman Eğitim ve Araştırma Hastanesi|Adıyaman|Merkez|Eğitim ve Araştırma|71.2|70.7|7/10|9.000-12.000 TL|24 Saat|12.000-16.000 TL|Acili dinamik ve öğretici.",
  "afyon_devlet|Afyonkarahisar Devlet Hastanesi|Afyonkarahisar|Merkez|Devlet Hastanesi|72.8|72.3|6/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Termal başkenti, sakin yaşam.",
  "agri_eah|Ağrı Eğitim ve Araştırma Hastanesi|Ağrı|Merkez|Eğitim ve Araştırma|68.5|67.9|7/10|10.000-14.000 TL|24 Saat|9.000-13.000 TL|Hizmet puanı avantajı.",
  "aksaray_eah|Aksaray Eğitim ve Araştırma Hastanesi|Aksaray|Merkez|Eğitim ve Araştırma|72.5|72.0|7/10|9.000-12.000 TL|24 Saat|11.000-15.000 TL|İç Anadolu kavşak noktası.",
  "amasya_eah|Amasya Sabuncuoğlu Şerefeddin EAH|Amasya|Merkez|Eğitim ve Araştırma|73.4|72.9|6/10|8.000-11.000 TL|24 Saat|12.000-16.000 TL|Tarihi şehir, personel memnuniyeti iyi.",
  "ankara_bilkent|Ankara Bilkent Şehir Hastanesi|Ankara|Çankaya|Şehir Hastanesi|74.5|74.0|9/10|12.000-15.000 TL|24 Saat|25.000-35.000 TL|Devasa kampüs, yoğun klinik deneyim.",
  "ankara_etlik|Ankara Etlik Şehir Hastanesi|Ankara|Keçiören|Şehir Hastanesi|74.2|73.7|8/10|11.000-14.000 TL|24 Saat|20.000-28.000 TL|Teşvikler düzenli.",
  "ankara_gulhane|Ankara Gülhane EAH (GATA)|Ankara|Keçiören|Eğitim ve Araştırma|74.3|73.8|7/10|10.000-13.000 TL|24 Saat|20.000-26.000 TL|Köklü kurum disiplini.",
  "ankara_sincan|Ankara Sincan EAH|Ankara|Sincan|Eğitim ve Araştırma|73.6|73.1|7/10|9.000-12.000 TL|24 Saat|15.000-20.000 TL|Kiralar Ankara merkezine göre uygun.",
  "antalya_sehir|Antalya Şehir Hastanesi|Antalya|Kepez|Şehir Hastanesi|75.1|74.6|7/10|10.000-14.000 TL|24 Saat|18.000-25.000 TL|Yeni tesis, sosyal imkanlar harika.",
  "antalya_eah|Antalya Eğitim ve Araştırma Hastanesi|Antalya|Muratpaşa|Eğitim ve Araştırma|75.6|75.1|8/10|10.000-13.000 TL|24 Saat|20.000-28.000 TL|Denize yakın merkezi konum.",
  "ardahan_devlet|Ardahan Devlet Hastanesi|Ardahan|Merkez|Devlet Hastanesi|68.8|68.3|5/10|7.000-10.000 TL|24 Saat|9.000-13.000 TL|Doğu görevi ve puan için ideal.",
  "artvin_devlet|Artvin Devlet Hastanesi|Artvin|Merkez|Devlet Hastanesi|71.5|71.0|5/10|7.000-10.000 TL|24 Saat|10.000-14.000 TL|Doğa harikası, sakin hastane.",
  "aydin_ataturk|Aydın Atatürk Devlet Hastanesi|Aydın|Efeler|Devlet Hastanesi|74.5|74.0|6/10|8.000-11.000 TL|24 Saat|14.000-20.000 TL|Ege'nin sıcak ve sosyal ili.",
  "balikesir_devlet|Balıkesir Devlet Hastanesi|Balıkesir|Karesi|Devlet Hastanesi|73.8|73.3|6/10|8.000-11.000 TL|24 Saat|13.000-18.000 TL|Merkezi ve huzurlu lokasyon.",
  "bartin_devlet|Bartın Devlet Hastanesi|Bartın|Merkez|Devlet Hastanesi|72.3|71.8|6/10|7.000-10.000 TL|24 Saat|11.000-16.000 TL|Sakin Karadeniz kenti.",
  "batman_eah|Batman Eğitim ve Araştırma Hastanesi|Batman|Merkez|Eğitim ve Araştırma|69.8|69.2|7/10|9.000-12.000 TL|24 Saat|10.000-15.000 TL|Güneydoğunun dinamik şehirlerinden.",
  "bayburt_devlet|Bayburt Devlet Hastanesi|Bayburt|Merkez|Devlet Hastanesi|70.5|70.0|5/10|6.000-9.000 TL|24 Saat|9.000-13.000 TL|Sakinlik arayanlar için tasarruf imkanı.",
  "bilecik_eah|Bilecik Eğitim ve Araştırma Hastanesi|Bilecik|Merkez|Eğitim ve Araştırma|72.6|72.1|6/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Hızlı tren hattı üstünde pratik ulaşım.",
  "bolu_eah|Bolu İzzet Baysal EAH|Bolu|Merkez|Eğitim ve Araştırma|73.4|72.9|7/10|8.000-11.500 TL|24 Saat|13.000-18.000 TL|Ankara-İstanbul arası muazzam doğa.",
  "burdur_devlet|Burdur Devlet Hastanesi|Burdur|Merkez|Devlet Hastanesi|73.7|73.2|6/10|7.000-10.000 TL|24 Saat|12.000-16.000 TL|Antalya'ya komşu öğrenci kenti.",
  "bursa_sehir|Bursa Şehir Hastanesi|Bursa|Nilüfer|Şehir Hastanesi|73.8|73.3|7/10|11.000-14.000 TL|24 Saat|16.000-22.000 TL|Nilüfer gibi nezih bir ilçede modern kampüs.",
  "bursa_ihtisas|Bursa Yüksek İhtisas EAH|Bursa|Yıldırım|Eğitim ve Araştırma|73.5|73.0|8/10|10.000-13.000 TL|24 Saat|15.000-20.000 TL|Bursa'nın en köklü ve yoğun hastanelerinden.",
  "canakkale_mehmet_akif|Çanakkale Mehmet Akif Ersoy DH|Çanakkale|Merkez|Devlet Hastanesi|74.5|74.0|6/10|8.000-11.000 TL|24 Saat|16.000-22.000 TL|Boğaz manzaralı harika konum.",
  "cankiri_devlet|Çankırı Devlet Hastanesi|Çankırı|Merkez|Devlet Hastanesi|72.1|71.6|5/10|6.000-9.000 TL|24 Saat|10.000-14.000 TL|Ankara'ya yakınlığıyla avantajlı.",
  "corum_eah|Çorum Erol Olçok EAH|Çorum|Merkez|Eğitim ve Araştırma|72.6|72.1|7/10|8.000-12.000 TL|24 Saat|11.000-16.000 TL|Teşvikler düzenli, yaşam masrafı düşük.",
  "denizli_devlet|Denizli Devlet Hastanesi|Denizli|Merkezefendi|Devlet Hastanesi|74.6|74.1|7/10|8.000-11.500 TL|24 Saat|14.000-19.000 TL|Ege'nin en gelişmiş illerinden.",
  "diyarbakir_gazi|Diyarbakır Gazi Yaşargil EAH|Diyarbakır|Yenişehir|Eğitim ve Araştırma|70.3|69.8|8/10|9.000-13.000 TL|24 Saat|11.000-16.000 TL|Bölgenin ana sevk merkezi.",
  "duzce_ataturk|Düzce Atatürk Devlet Hastanesi|Düzce|Merkez|Devlet Hastanesi|72.8|72.3|6/10|8.000-11.000 TL|24 Saat|12.000-16.000 TL|Otoban kenarında, ulaşımı rahat.",
  "edirne_sultan_murat|Edirne Sultan 1. Murat Devlet Hastanesi|Edirne|Merkez|Devlet Hastanesi|73.4|72.9|6/10|8.000-11.000 TL|24 Saat|14.000-19.000 TL|Modern Trakya şehri.",
  "elazig_sehir|Elazığ Fethi Sekin Şehir Hastanesi|Elazığ|Merkez|Şehir Hastanesi|71.0|70.5|7/10|10.000-13.000 TL|24 Saat|11.000-15.000 TL|Bölge hastanesi, altyapı güçlü.",
  "erzincan_eah|Erzincan Mengücek Gazi EAH|Erzincan|Merkez|Eğitim ve Araştırma|71.2|70.7|6/10|8.000-11.000 TL|24 Saat|10.000-14.000 TL|Doğa sporları ve sakin yaşam.",
  "erzurum_sehir|Erzurum Şehir Hastanesi|Erzurum|Palandöken|Şehir Hastanesi|71.4|70.9|8/10|10.000-14.000 TL|24 Saat|11.000-16.000 TL|Kışın kapalı tüp geçitler kurtarıcı.",
  "eskisehir_sehir|Eskişehir Şehir Hastanesi|Eskişehir|Odunpazarı|Şehir Hastanesi|74.8|74.3|7/10|10.000-13.000 TL|24 Saat|14.000-20.000 TL|Tramvay hattı ve öğrenci sosyal ortamı.",
  "gaziantep_sehir|Gaziantep Şehir Hastanesi|Gaziantep|Şahinbey|Şehir Hastanesi|71.8|71.3|8/10|10.000-14.000 TL|24 Saat|14.000-20.000 TL|Yeni kampüs, yoğun vaka.",
  "giresun_eah|Giresun Eğitim ve Araştırma Hastanesi|Giresun|Merkez|Eğitim ve Araştırma|73.1|72.6|7/10|8.000-11.500 TL|24 Saat|12.000-17.000 TL|Denize sıfır, Karadeniz huzuru.",
  "gumushane_devlet|Gümüşhane Devlet Hastanesi|Gümüşhane|Merkez|Devlet Hastanesi|71.2|70.7|5/10|6.000-9.000 TL|24 Saat|9.000-13.000 TL|Yeni tünellerle Trabzon'a çok yakın.",
  "hakkari_devlet|Hakkari Devlet Hastanesi|Hakkari|Merkez|Devlet Hastanesi|67.9|67.4|5/10|8.000-12.000 TL|24 Saat|8.000-12.000 TL|En yüksek hizmet puanı avantajı.",
  "hatay_dortyol|Hatay Dörtyol Devlet Hastanesi|Hatay|Dörtyol|Devlet Hastanesi|71.8|71.3|6/10|7.000-10.000 TL|24 Saat|10.000-14.000 TL|Sahil şeridinde.",
  "igdir_devlet|Iğdır Dr. Nevruz Erez Devlet Hastanesi|Iğdır|Merkez|Devlet Hastanesi|68.9|68.4|6/10|7.000-10.000 TL|24 Saat|9.000-13.000 TL|Mikroklima iklimli doğu kenti.",
  "isparta_sehir|Isparta Şehir Hastanesi|Isparta|Merkez|Şehir Hastanesi|74.1|73.6|7/10|10.000-13.000 TL|24 Saat|12.000-17.000 TL|Güller diyarı sakin ve temiz şehir.",
  "istanbul_cam_sakura|Başakşehir Çam ve Sakura Şehir H.|İstanbul|Başakşehir|Şehir Hastanesi|69.3|68.9|9/10|12.000-15.000 TL|24 Saat|25.000-35.000 TL|Kağıtsız hastane, metroyla içine kadar ulaşım.",
  "istanbul_sadi_konuk|Bakırköy Dr. Sadi Konuk EAH|İstanbul|Bakırköy|Eğitim ve Araştırma|69.6|69.0|9/10|11.000-14.000 TL|24 Saat|25.000-35.000 TL|Metrobüs dibinde yoğun tecrübe merkezi.",
  "izmir_sehir|İzmir Şehir Hastanesi|İzmir|Bayraklı|Şehir Hastanesi|75.5|75.0|8/10|11.000-15.000 TL|24 Saat|20.000-28.000 TL|Ege'nin tepesinde devasa yapı.",
  "maras_necil|Kahramanmaraş Necip Fazıl Şehir Hastanesi|Kahramanmaraş|Dulkadiroğlu|Şehir Hastanesi|72.3|71.8|7/10|9.000-12.000 TL|24 Saat|12.000-16.000 TL|Düzenli işleyiş.",
  "karabuk_eah|Karabük Eğitim ve Araştırma Hastanesi|Karabük|Merkez|Eğitim ve Araştırma|73.1|72.6|7/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Üniversite kenti, ekonomik.",
  "karaman_eah|Karaman Eğitim ve Araştırma Hastanesi|Karaman|Merkez|Eğitim ve Araştırma|72.6|72.1|6/10|8.000-11.000 TL|24 Saat|10.000-14.000 TL|Hızlı trenle ulaşım kolay.",
  "kars_harakani|Kars Harakani Devlet Hastanesi|Kars|Merkez|Devlet Hastanesi|69.4|68.9|6/10|8.000-11.000 TL|24 Saat|10.000-14.000 TL|Doğu ekspresi ile turistik yapı.",
  "kastamonu_eah|Kastamonu Eğitim ve Araştırma Hastanesi|Kastamonu|Merkez|Eğitim ve Araştırma|72.7|72.2|7/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Ormanlık ve ferah bir il.",
  "kayseri_sehir|Kayseri Şehir Hastanesi|Kayseri|Kocasinan|Şehir Hastanesi|74.1|73.6|7/10|10.000-13.500 TL|24 Saat|12.000-18.000 TL|Tramvay tam önünden geçer.",
  "kirikkale_ihtisas|Kırıkkale Yüksek İhtisas Hastanesi|Kırıkkale|Merkez|Devlet Hastanesi|72.8|72.3|6/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Ankara'ya çok yakın.",
  "kirklareli_eah|Kırklareli Eğitim ve Araştırma Hastanesi|Kırklareli|Merkez|Eğitim ve Araştırma|73.4|72.9|6/10|8.000-11.000 TL|24 Saat|12.000-17.000 TL|Trakya'da medeni ve sakin yaşam.",
  "kirsehir_eah|Kırşehir Eğitim ve Araştırma Hastanesi|Kırşehir|Merkez|Eğitim ve Araştırma|72.7|72.2|6/10|8.000-11.000 TL|24 Saat|10.000-14.000 TL|Maddi birikim için çok uygun.",
  "kilis_alaeddin|Kilis Prof. Dr. Alaeddin Yavaşca DH|Kilis|Merkez|Devlet Hastanesi|71.3|70.8|6/10|7.000-10.000 TL|24 Saat|9.000-13.000 TL|Yeni yapılan modern bina.",
  "kocaeli_sehir|Kocaeli Şehir Hastanesi|Kocaeli|İzmit|Şehir Hastanesi|73.1|72.6|8/10|11.000-14.500 TL|24 Saat|15.000-22.000 TL|İstanbul'a 1 saat mesafede.",
  "konya_sehir|Konya Şehir Hastanesi|Konya|Karatay|Şehir Hastanesi|74.1|73.6|7/10|10.000-14.000 TL|24 Saat|12.000-17.000 TL|Düzenli ulaşım ve tramvay ağı.",
  "kutahya_sehir|Kütahya Şehir Hastanesi|Kütahya|Merkez|Şehir Hastanesi|73.4|72.9|7/10|10.000-13.000 TL|24 Saat|12.000-16.000 TL|Eskişehir'e 45 dakika.",
  "malatya_eah|Malatya Eğitim ve Araştırma Hastanesi|Malatya|Battalgazi|Eğitim ve Araştırma|71.6|71.1|7/10|9.000-12.000 TL|24 Saat|11.000-15.000 TL|Personel dayanışması yüksek.",
  "manisa_sehir|Manisa Şehir Hastanesi|Manisa|Şehzadeler|Şehir Hastanesi|74.3|73.8|7/10|11.000-14.000 TL|24 Saat|14.000-19.000 TL|İzmir'den gidiş geliş imkanı.",
  "mardin_eah|Mardin Eğitim ve Araştırma Hastanesi|Mardin|Artuklu|Eğitim ve Araştırma|70.2|69.7|7/10|9.000-12.000 TL|24 Saat|11.000-16.000 TL|Tarihi şehir.",
  "mersin_sehir|Mersin Şehir Hastanesi|Mersin|Toroslar|Şehir Hastanesi|74.4|73.9|7/10|10.000-13.000 TL|24 Saat|14.000-20.000 TL|Sahil kenti, iklimi sıcak.",
  "mugla_eah|Muğla Eğitim ve Araştırma Hastanesi|Muğla|Menteşe|Eğitim ve Araştırma|75.3|74.8|8/10|10.000-13.000 TL|24 Saat|18.000-25.000 TL|Turizm kenti, prestijli kurum.",
  "mus_devlet|Muş Devlet Hastanesi|Muş|Merkez|Devlet Hastanesi|68.8|68.3|6/10|8.000-11.000 TL|24 Saat|9.000-13.000 TL|Hizmet puanı çok yüksek.",
  "nevsehir_devlet|Nevşehir Devlet Hastanesi|Nevşehir|Merkez|Devlet Hastanesi|73.5|73.0|6/10|8.000-11.000 TL|24 Saat|11.000-16.000 TL|Turistik Kapadokya bölgesinde nezih şehir.",
  "nigde_omer|Niğde Ömer Halisdemir EAH|Niğde|Merkez|Eğitim ve Araştırma|72.6|72.1|6/10|8.000-11.000 TL|24 Saat|10.000-14.000 TL|Sakin öğrenci kenti.",
  "ordu_eah|Ordu Eğitim ve Araştırma Hastanesi|Ordu|Altınordu|Eğitim ve Araştırma|73.6|73.1|7/10|8.000-12.000 TL|24 Saat|13.000-18.000 TL|Karadeniz'in en güzel sahil şeridi.",
  "osmaniye_devlet|Osmaniye Devlet Hastanesi|Osmaniye|Merkez|Devlet Hastanesi|72.9|72.4|6/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Adana'ya 1 saat mesafede.",
  "rize_eah|Rize Eğitim ve Araştırma Hastanesi|Rize|Merkez|Eğitim ve Araştırma|72.8|72.3|7/10|8.000-11.000 TL|24 Saat|12.000-17.000 TL|Doğa ve yayla hayatı.",
  "sakarya_eah|Sakarya Eğitim ve Araştırma Hastanesi|Sakarya|Adapazarı|Eğitim ve Araştırma|73.2|72.7|7/10|9.000-12.000 TL|24 Saat|14.000-20.000 TL|İstanbul'a çok yakın.",
  "siirt_eah|Siirt Eğitim ve Araştırma Hastanesi|Siirt|Merkez|Eğitim ve Araştırma|69.3|68.8|6/10|8.000-11.000 TL|24 Saat|9.000-13.000 TL|Tasarruf için ideal.",
  "sivas_numune|Sivas Numune Hastanesi|Sivas|Merkez|Devlet Hastanesi|73.1|72.6|6/10|8.000-11.000 TL|24 Saat|11.000-15.000 TL|Hızlı trenle Ankara bağlantısı.",
  "sanliurfa_eah|Şanlıurfa Eğitim ve Araştırma Hastanesi|Şanlıurfa|Eyyübiye|Eğitim ve Araştırma|69.8|69.3|8/10|9.000-13.000 TL|24 Saat|10.000-15.000 TL|Puan ve klinik tecrübesi yüksek.",
  "sirnak_cizre|Şırnak Cizre Dr. Selahattin Cizrelioğlu DH|Şırnak|Cizre|Devlet Hastanesi|68.2|67.7|6/10|9.000-12.000 TL|24 Saat|8.000-12.000 TL|İl merkezinden daha hareketli, havalimanı var.",
  "tekirdag_sehir|Tekirdağ Dr. İsmail Fehmi Cumalıoğlu Şehir H.|Tekirdağ|Süleymanpaşa|Şehir Hastanesi|73.5|73.0|7/10|10.000-13.000 TL|24 Saat|15.000-20.000 TL|Deniz kenarı modern kampüs.",
  "trabzon_kanuni|Trabzon Kanuni EAH|Trabzon|Yomra|Eğitim ve Araştırma|73.7|73.2|7/10|9.000-13.000 TL|24 Saat|14.000-20.000 TL|Doğu Karadeniz ana üssü.",
  "tunceli_devlet|Tunceli Devlet Hastanesi|Tunceli|Merkez|Devlet Hastanesi|70.8|70.3|5/10|7.000-10.000 TL|24 Saat|10.000-14.000 TL|Çok sakin ve doğa ile iç içe.",
  "usak_eah|Uşak Eğitim ve Araştırma Hastanesi|Uşak|Merkez|Eğitim ve Araştırma|73.8|73.3|6/10|8.000-11.000 TL|24 Saat|12.000-16.000 TL|Ege'nin iç kısımlarında sakin il.",
  "van_eah|Van Eğitim ve Araştırma Hastanesi|Van|Edremit|Eğitim ve Araştırma|69.6|69.1|7/10|9.000-13.000 TL|24 Saat|10.000-15.000 TL|Göl kenarında ferah kampüs.",
  "yalova_eah|Yalova Eğitim ve Araştırma Hastanesi|Yalova|Merkez|Eğitim ve Araştırma|73.9|73.4|7/10|9.000-13.000 TL|24 Saat|15.000-22.000 TL|Marmara'da sayfiye yeri rahatlığı.",
  "yozgat_sehir|Yozgat Şehir Hastanesi|Yozgat|Merkez|Şehir Hastanesi|72.4|71.9|6/10|10.000-13.000 TL|24 Saat|10.000-14.000 TL|Ankara'ya çok yakın.",
  "zonguldak_ataturk|Zonguldak Atatürk Devlet Hastanesi|Zonguldak|Merkez|Devlet Hastanesi|73.2|72.7|6/10|8.000-11.000 TL|24 Saat|12.000-17.000 TL|Tecrübeli kadrosuyla bilinen merkez."
];

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Hospital> _hospitals = [];
  List<String> _favoriteIds = [];
  Map<String, String> _notes = {};
  Map<String, String> _images = {};
  String _searchQuery = '';
  String _activeCity = 'Tümü';
  double _userScore = 72.0;

  @override
  void initState() {
    super.initState();
    _parseData();
    _loadPrefs();
  }

  void _parseData() {
    for (var item in rawData) {
      final p = item.split('|');
      _hospitals.add(Hospital(
        id: p[0], name: p[1], city: p[2], district: p[3], type: p[4],
        kpss2024: double.parse(p[5]), kpss2025: double.parse(p[6]),
        workLoad: p[7], incentive: p[8], shift: p[9], rentRange: p[10], review: p[11],
      ));
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favs') ?? [];
      _notes = Map<String, String>.from(json.decode(prefs.getString('notes') ?? '{}'));
      _images = Map<String, String>.from(json.decode(prefs.getString('images') ?? '{}'));
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favs', _favoriteIds);
    await prefs.setString('notes', json.encode(_notes));
    await prefs.setString('images', json.encode(_images));
  }

  void _toggleFav(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) _favoriteIds.remove(id);
      else _favoriteIds.add(id);
    });
    _savePrefs();
  }

  void _moveFav(int index, int dir) {
    setState(() {
      final newIndex = index + dir;
      if (newIndex >= 0 && newIndex < _favoriteIds.length) {
        final item = _favoriteIds.removeAt(index);
        _favoriteIds.insert(newIndex, item);
      }
    });
    _savePrefs();
  }

  Future<void> _pickImage(String id) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _images[id] = pickedFile.path);
      _savePrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mega Atama (10.000 Kişi) Rehberi', style: TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'İl, İlçe veya Hastane Ara...',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Text('Puan:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (v) => setState(() => _userScore = double.tryParse(v) ?? 0.0),
                          controller: TextEditingController(text: _userScore.toString())..selection = TextSelection.collapsed(offset: _userScore.toString().length),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: _currentIndex == 0 ? _buildAllList() : _buildFavList(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Tüm Kurumlar'),
          NavigationDestination(
            icon: Badge(label: Text('${_favoriteIds.length}'), child: const Icon(Icons.star)),
            label: 'Tercih Listem',
          ),
        ],
      ),
    );
  }

  Widget _buildAllList() {
    final cities = ['Tümü', ..._hospitals.map((h) => h.city).toSet().toList()..sort()];
    final filtered = _hospitals.where((h) {
      final mSearch = h.name.toLowerCase().contains(_searchQuery.toLowerCase()) || h.city.toLowerCase().contains(_searchQuery.toLowerCase());
      final mCity = _activeCity == 'Tümü' || h.city == _activeCity;
      return mSearch && mCity;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: cities.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(c),
                selected: _activeCity == c,
                onSelected: (val) { if(val) setState(() => _activeCity = c); },
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _buildCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFavList() {
    if (_favoriteIds.isEmpty) {
      return const Center(child: Text("Listeniz Boş. Kalp ikonuna basarak hastane ekleyin.", style: TextStyle(color: Colors.grey)));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _favoriteIds.length,
      onReorder: (oldI, newI) {
        if (newI > oldI) newI -= 1;
        setState(() {
          final item = _favoriteIds.removeAt(oldI);
          _favoriteIds.insert(newI, item);
        });
        _savePrefs();
      },
      itemBuilder: (ctx, i) {
        final h = _hospitals.firstWhere((x) => x.id == _favoriteIds[i]);
        return Card(
          key: ValueKey(h.id),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF0D9488), child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
            title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('${h.city} • Son Taban: ${h.kpss2025}'),
            trailing: const Icon(Icons.drag_handle),
            onTap: () => _showDetails(h),
          ),
        );
      },
    );
  }

  Widget _buildCard(Hospital h) {
    final isFav = _favoriteIds.contains(h.id);
    final imgPath = _images[h.id];
    final diff = _userScore - h.kpss2025;
    
    Color badgeColor;
    String badgeText;
    if (diff >= 0) { badgeColor = Colors.green; badgeText = "Kesin Gelir"; }
    else if (diff >= -1.5) { badgeColor = Colors.orange; badgeText = "Sınırda"; }
    else { badgeColor = Colors.red; badgeText = "Zor / Gelmez"; }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140, width: double.infinity,
                  color: Colors.teal.shade700,
                  child: imgPath != null && File(imgPath).existsSync()
                      ? Image.file(File(imgPath), fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.white54, size: 40),
                            SizedBox(height: 8),
                            Text("GÖRSEL EKLENEBİLİR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))
                          ],
                        ),
                ),
                Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(h.type, style: const TextStyle(color: Colors.white, fontSize: 11)))),
                Positioned(top: 8, right: 8, child: InkWell(onTap: () => _toggleFav(h.id), child: CircleAvatar(backgroundColor: Colors.black54, child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white)))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${h.city} / ${h.district}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("2024 Taban", style: TextStyle(fontSize: 10, color: Colors.grey)), Text("${h.kpss2024}", style: const TextStyle(fontWeight: FontWeight.bold))]),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Son Atama", style: TextStyle(fontSize: 10, color: Colors.grey)), Text("${h.kpss2025}", style: const TextStyle(fontWeight: FontWeight.bold))]),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor)), child: Text(badgeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor))),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDetails(Hospital h) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final noteCtrl = TextEditingController(text: _notes[h.id] ?? '');
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _detailRow("İş Yükü", h.workLoad),
                  _detailRow("Teşvik", h.incentive),
                  _detailRow("Nöbet", h.shift),
                  _detailRow("Kira", h.rentRange),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text("💡 Saha Notu: ${h.review}", style: TextStyle(color: Colors.blue.shade900, fontSize: 13))),
                  const SizedBox(height: 16),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: "Kişisel notunuz...", border: OutlineInputBorder()), maxLines: 2, onChanged: (v) { _notes[h.id] = v; _savePrefs(); }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_a_photo), label: const Text("Galeriden Fotoğraf Ekle"),
                      onPressed: () async {
                        await _pickImage(h.id);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  Widget _detailRow(String label, String val) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Text(val))]));
}
