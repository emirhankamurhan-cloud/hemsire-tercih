import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
          elevation: 0, centerTitle: true,
          backgroundColor: Color(0xFF0D9488), foregroundColor: Colors.white,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class Hospital {
  final String id, name, city, district, type, workLoad, incentive, shift, rentRange, pros, cons;
  final double kpss2024, kpss2025;

  Hospital({
    required this.id, required this.name, required this.city, required this.district,
    required this.type, required this.kpss2024, required this.kpss2025,
    required this.workLoad, required this.incentive, required this.shift,
    required this.rentRange, required this.pros, required this.cons,
  });

  String get egitimToleransi => (type.contains('Eğitim') || type.contains('Şehir')) ? 'Yüksek (Üniversite Protokolü)' : 'Orta / İdare İnsiyatifinde';
  String get lojmanDurumu => (type == 'Devlet Hastanesi' && !['Merkez', 'İlkadım', 'Çankaya', 'Kadıköy', 'Şişli', 'Seyhan'].contains(district)) ? 'Lojman Kısıtlı / Sırada Beklenebilir' : 'Genellikle Yok';
}

// === İŞTE O GERİ DÖNEN 270 KÜSÜR HASTANELİK DEV LİSTE ===
final List<String> rawData = [
  // ADANA (14)
  "adana_sehir|Adana Şehir Hastanesi|Adana|Yüreğir|Şehir Hastanesi|74.2|73.8|8/10|11.000-14.000 TL|24 Saat Nöbet|15.000-20.000 TL|Bölgenin ana referans merkezi, teşvikleri iyi.|Yaz aylarında inanılmaz sıcak. Acili hareketli.",
  "adana_seyhan|Adana Seyhan Devlet Hastanesi|Adana|Seyhan|Devlet Hastanesi|73.9|73.5|6/10|8.000-10.000 TL|24 Saat Nöbet|13.000-18.000 TL|Şehir merkezinde rahat kurum.|Çok özellikli vaka görülmez.",
  "adana_ceyhan|Adana Ceyhan Devlet Hastanesi|Adana|Ceyhan|Devlet Hastanesi|73.4|73.0|6/10|7.000-9.500 TL|24 Saat Nöbet|10.000-14.000 TL|Adana'nın en büyük ilçelerinden.|Hastane fiziki olarak eski.",
  "adana_kozan|Adana Kozan Devlet Hastanesi|Adana|Kozan|Devlet Hastanesi|72.8|72.4|5/10|6.500-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Merkeze göre sakin, maddi birikim imkanı.|Şehir merkezine biraz uzak.",
  "adana_çukurova|Adana Çukurova Devlet Hastanesi|Adana|Çukurova|Devlet Hastanesi|74.0|73.6|6/10|7.500-10.000 TL|24 Saat Nöbet|14.000-19.000 TL|Nezih ilçe, çalışma ortamı sakin.|Ev kiraları Adana geneline göre yüksek.",
  "adana_yuregir|Adana Yüreğir Devlet Hastanesi|Adana|Yüreğir|Devlet Hastanesi|73.2|72.8|7/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Gelişmiş ilçe.|Şehir hastanesinin gölgesinde kalıyor.",
  "adana_imamoglu|Adana İmamoğlu Devlet Hastanesi|Adana|İmamoğlu|Devlet Hastanesi|71.5|71.1|4/10|5.000-7.000 TL|24 Saat Nöbet|8.000-11.000 TL|Çok sakin, az vaka.|Mesleki gelişim zor.",
  "adana_karatas|Adana Karataş Devlet Hastanesi|Adana|Karataş|Devlet Hastanesi|72.1|71.6|5/10|5.500-8.000 TL|24 Saat Nöbet|9.000-12.000 TL|Deniz kenarında küçük ilçe.|Yazlık bölge olduğu için yazın yoğun.",
  "adana_pozantı|Adana Pozantı Devlet Hastanesi|Adana|Pozantı|Devlet Hastanesi|71.8|71.3|5/10|5.500-8.000 TL|24 Saat Nöbet|8.500-12.000 TL|Toroslar'da serin hava.|Merkeze uzak.",
  "adana_saimbeyli|Adana Saimbeyli Devlet Hastanesi|Adana|Saimbeyli|Devlet Hastanesi|70.5|70.0|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-10.000 TL|Tasarruf için uygun.|Çok küçük ve sosyal imkan yok.",
  "adana_tufanbeyli|Adana Tufanbeyli Devlet Hastanesi|Adana|Tufanbeyli|Devlet Hastanesi|70.2|69.7|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-10.000 TL|İş yükü çok hafif.|Merkeze oldukça uzak.",
  "adana_feke|Adana Feke Devlet Hastanesi|Adana|Feke|Devlet Hastanesi|70.8|70.3|4/10|4.500-6.500 TL|24 Saat Nöbet|7.500-10.500 TL|Sakin ortam.|Gelişmemiş ilçe.",
  "adana_aladag|Adana Aladağ Devlet Hastanesi|Adana|Aladağ|Devlet Hastanesi|71.1|70.6|4/10|5.000-7.000 TL|24 Saat Nöbet|8.000-11.000 TL|Doğa ile iç içe.|Ulaşım zorluğu.",
  "adana_yumurtalik|Adana Yumurtalık Devlet Hastanesi|Adana|Yumurtalık|Devlet Hastanesi|71.9|71.4|5/10|5.500-8.000 TL|24 Saat Nöbet|9.000-12.000 TL|Sahil ilçesi.|Küçük ve sakin.",

  // ADIYAMAN (8)
  "adiyaman_eah|Adıyaman Eğitim ve Araştırma Hastanesi|Adıyaman|Merkez|Eğitim ve Araştırma|71.2|70.7|7/10|9.000-12.000 TL|24 Saat Nöbet|12.000-16.000 TL|Acili dinamik ve öğretici.|Deprem sonrası toparlanma süreci.",
  "adiyaman_besni|Adıyaman Besni Devlet Hastanesi|Adıyaman|Besni|Devlet Hastanesi|70.5|70.0|5/10|6.000-9.000 TL|24 Saat Nöbet|10.000-13.000 TL|Gelişmiş ilçe.|Nöbet sonrası sosyal aktivite kısıtlı.",
  "adiyaman_golbasi|Adıyaman Gölbaşı Devlet Hastanesi|Adıyaman|Gölbaşı|Devlet Hastanesi|70.8|70.3|5/10|6.500-9.500 TL|24 Saat Nöbet|10.500-13.500 TL|Göl manzaralı güzel ilçe.|Merkeze nispeten uzak.",
  "adiyaman_kahta|Adıyaman Kahta Devlet Hastanesi|Adıyaman|Kahta|Devlet Hastanesi|71.0|70.5|6/10|7.000-10.000 TL|24 Saat Nöbet|11.000-14.000 TL|Büyük ilçe.|İş yükü merkeze yakın.",
  "adiyaman_tut|Adıyaman Tut Devlet Hastanesi|Adıyaman|Tut|Devlet Hastanesi|69.5|69.0|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-10.000 TL|Çok sakin.|Küçük yerleşim yeri.",
  "adiyaman_celikhan|Adıyaman Çelikhan Devlet Hastanesi|Adıyaman|Çelikhan|Devlet Hastanesi|69.8|69.3|4/10|4.500-6.500 TL|24 Saat Nöbet|7.500-10.500 TL|Sakin çalışma ortamı.|Dağlık ve ulaşımı kışın zor.",
  "adiyaman_gerger|Adıyaman Gerger Devlet Hastanesi|Adıyaman|Gerger|Devlet Hastanesi|69.2|68.7|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-9.000 TL|Hizmet puanı yüksek.|En ücra ilçe.",
  "adiyaman_sincik|Adıyaman Sincik Devlet Hastanesi|Adıyaman|Sincik|Devlet Hastanesi|69.0|68.5|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-9.000 TL|Tasarruf için uygun.|Sosyal hayat yok.",

  // AFYONKARAHİSAR (10)
  "afyon_devlet|Afyonkarahisar Devlet Hastanesi|Afyonkarahisar|Merkez|Devlet Hastanesi|72.8|72.3|6/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Termal başkenti, ulaşım kavşağı.|Kışları oldukça soğuk geçer.",
  "afyon_sandikli|Afyonkarahisar Sandıklı Devlet Hastanesi|Afyonkarahisar|Sandıklı|Devlet Hastanesi|71.9|71.4|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Kaplıcaları ile ünlü sakin ilçe.|Küçük yerleşim yeri dezavantajları.",
  "afyon_dinar|Afyonkarahisar Dinar Devlet Hastanesi|Afyonkarahisar|Dinar|Devlet Hastanesi|71.5|71.0|5/10|6.000-8.500 TL|24 Saat Nöbet|8.500-12.000 TL|Büyük ilçe.|Denizli ve Isparta'ya giden yol üstü karmaşası.",
  "afyon_emirdag|Afyonkarahisar Emirdağ Devlet Hastanesi|Afyonkarahisar|Emirdağ|Devlet Hastanesi|71.7|71.2|5/10|6.500-9.000 TL|24 Saat Nöbet|9.000-12.500 TL|Eskişehir'e yakın.|Yazın gurbetçilerle nüfus çok artar.",
  "afyon_cay|Afyonkarahisar Çay Devlet Hastanesi|Afyonkarahisar|Çay|Devlet Hastanesi|71.2|70.7|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin.|Gelişmemiş.",
  "afyon_bolvadin|Afyonkarahisar Bolvadin Devlet Hastanesi|Afyonkarahisar|Bolvadin|Devlet Hastanesi|71.6|71.1|5/10|5.500-8.000 TL|24 Saat Nöbet|8.500-11.500 TL|Düzenli ilçe.|Merkeze uzak.",
  "afyon_sultandagi|Afyonkarahisar Sultandağı Devlet Hastanesi|Afyonkarahisar|Sultandağı|Devlet Hastanesi|70.8|70.3|4/10|4.500-7.000 TL|24 Saat Nöbet|7.500-10.500 TL|Sakin ortam.|Küçük ilçe.",
  "afyon_suhut|Afyonkarahisar Şuhut Devlet Hastanesi|Afyonkarahisar|Şuhut|Devlet Hastanesi|71.0|70.5|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Merkeze yakın.|Sosyal imkan az.",
  "afyon_ihsaniye|Afyonkarahisar İhsaniye Devlet Hastanesi|Afyonkarahisar|İhsaniye|Devlet Hastanesi|70.5|70.0|4/10|4.500-6.500 TL|24 Saat Nöbet|7.500-10.000 TL|Afyon merkeze çok yakın.|Küçük kurum.",
  "afyon_hocalar|Afyonkarahisar Hocalar Devlet Hastanesi|Afyonkarahisar|Hocalar|Devlet Hastanesi|69.8|69.3|3/10|3.500-5.500 TL|24 Saat Nöbet|6.500-9.000 TL|İş yok denecek kadar az.|Çok ücra.",

  // AĞRI (5)
  "agri_eah|Ağrı Eğitim ve Araştırma Hastanesi|Ağrı|Merkez|Eğitim ve Araştırma|68.5|67.9|7/10|10.000-14.000 TL|24 Saat Nöbet|9.000-13.000 TL|Hizmet puanı çok yüksek, kısa sürede tayin hakkı.|İklim çok sert, kışlar çok uzun geçer.",
  "agri_patnos|Ağrı Patnos Devlet Hastanesi|Ağrı|Patnos|Devlet Hastanesi|67.8|67.3|6/10|8.000-11.000 TL|24 Saat Nöbet|8.000-11.000 TL|İlçenin nüfusu kalabalık.|Sosyal yaşam kısıtlı.",
  "agri_dogubayazit|Ağrı Doğubayazıt Devlet Hastanesi|Ağrı|Doğubayazıt|Devlet Hastanesi|68.1|67.6|6/10|8.500-11.500 TL|24 Saat Nöbet|8.500-12.000 TL|Tarihi ilçe, sınır ticareti.|Kışın ulaşım zorluğu.",
  "agri_diyadin|Ağrı Diyadin Devlet Hastanesi|Ağrı|Diyadin|Devlet Hastanesi|67.5|67.0|5/10|6.000-9.000 TL|24 Saat Nöbet|7.500-10.500 TL|Sakin kurum.|Çok soğuk.",
  "agri_eleskirt|Ağrı Eleşkirt Devlet Hastanesi|Ağrı|Eleşkirt|Devlet Hastanesi|67.2|66.7|4/10|5.000-8.000 TL|24 Saat Nöbet|7.000-10.000 TL|Maddi birikim için birebir.|Sosyal aktivite sıfır.",

  // AKSARAY (5)
  "aksaray_eah|Aksaray Eğitim ve Araştırma Hastanesi|Aksaray|Merkez|Eğitim ve Araştırma|72.5|72.0|7/10|9.000-12.000 TL|24 Saat Nöbet|11.000-15.000 TL|İç Anadolu kavşak noktası, gidiş geliş kolay.|Çok rüzgarlı ve kurak bir iklimi var.",
  "aksaray_ortakoy|Aksaray Ortaköy Devlet Hastanesi|Aksaray|Ortaköy|Devlet Hastanesi|71.8|71.3|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-12.000 TL|Düzenli ilçe.|Aktivite az.",
  "aksaray_eskil|Aksaray Eskil Devlet Hastanesi|Aksaray|Eskil|Devlet Hastanesi|71.2|70.7|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin.|Merkeze uzak.",
  "aksaray_agacoren|Aksaray Ağaçören Devlet Hastanesi|Aksaray|Ağaçören|Devlet Hastanesi|70.8|70.3|4/10|4.500-6.500 TL|24 Saat Nöbet|7.500-10.500 TL|İş yükü az.|Ufak ilçe.",
  "aksaray_guzelyurt|Aksaray Güzelyurt Devlet Hastanesi|Aksaray|Güzelyurt|Devlet Hastanesi|70.5|70.0|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-10.000 TL|Turistik Kapadokya bölgesi.|Çok küçük.",

  // AMASYA (5)
  "amasya_serefeddin|Amasya Sabuncuoğlu Şerefeddin EAH|Amasya|Merkez|Eğitim ve Araştırma|73.4|72.9|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Tarihi şehir, personel memnuniyeti iyi.|Çok spesifik vakalarda EAH kapasitesi yetersiz kalabilir.",
  "amasya_merzifon|Amasya Merzifon Devlet Hastanesi|Amasya|Merzifon|Devlet Hastanesi|72.8|72.3|5/10|6.000-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Amasya merkezden daha canlı kavşak ilçe.|Soğuk kışlar.",
  "amasya_suluova|Amasya Suluova Devlet Hastanesi|Amasya|Suluova|Devlet Hastanesi|72.2|71.7|5/10|5.500-8.000 TL|24 Saat Nöbet|9.000-12.000 TL|Sakin ve şirin ilçe.|Merkeze çok yakın ama imkanları kısıtlı.",
  "amasya_tasova|Amasya Taşova Devlet Hastanesi|Amasya|Taşova|Devlet Hastanesi|71.5|71.0|4/10|4.500-7.000 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin çalışma ortamı.|Ufak ilçe.",
  "amasya_gumushacikoy|Amasya Gümüşhacıköy Devlet Hastanesi|Amasya|Gümüşhacıköy|Devlet Hastanesi|71.0|70.5|4/10|4.000-6.000 TL|24 Saat Nöbet|7.000-10.000 TL|Tasarruf ilçesi.|Gelişmemiş.",

  // ANKARA (12)
  "ankara_bilkent|Ankara Bilkent Şehir Hastanesi|Ankara|Çankaya|Şehir Hastanesi|74.5|74.0|10/10|12.000-15.000 TL|24 Saat & 16-8|25.000-35.000 TL|Her türlü vaka görülür, en büyük akademi.|Hasta sirkülasyonu ve dev kampüs yorucudur.",
  "ankara_etlik|Ankara Etlik Şehir Hastanesi|Ankara|Keçiören|Şehir Hastanesi|74.2|73.7|8/10|11.000-14.000 TL|24 Saat Nöbet|20.000-28.000 TL|Malzeme sıkıntısı yok, modern ortam.|Birimler arası koordinasyon bazen zorlayıcı.",
  "ankara_gulhane|Ankara Gülhane EAH (GATA)|Ankara|Keçiören|Eğitim ve Araştırma|74.3|73.8|7/10|10.000-13.000 TL|24 Saat Nöbet|20.000-26.000 TL|Köklü kurum disiplini ve kalitesi.|Askeri kültürden gelen eski yapısı var.",
  "ankara_sincan|Ankara Sincan EAH|Ankara|Sincan|Eğitim ve Araştırma|73.6|73.1|7/10|9.000-12.000 TL|24 Saat Nöbet|15.000-20.000 TL|Ev kiraları Çankaya'ya göre çok daha uygun.|Şehir merkezine ulaşım metroyla vakit alır.",
  "ankara_polatli|Ankara Polatlı Duatepe Devlet Hastanesi|Ankara|Polatlı|Devlet Hastanesi|72.9|72.4|6/10|7.000-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|Ankara'ya trenle çok yakın.|İlçe hayatı biraz tekdüze.",
  "ankara_cubuk|Ankara Çubuk Halil Şıvgın Devlet Hastanesi|Ankara|Çubuk|Devlet Hastanesi|73.0|72.5|6/10|7.000-10.000 TL|24 Saat Nöbet|11.000-15.000 TL|Havalimanına yakın, gelişen ilçe.|Merkeze uzaklık.",
  "ankara_kahramankazan|Ankara Kahramankazan Devlet Hastanesi|Ankara|Kahramankazan|Devlet Hastanesi|73.2|72.7|6/10|7.500-10.500 TL|24 Saat Nöbet|12.000-16.000 TL|Sanayi bölgesi, düzenli ilçe.|Yoğunluk yaşanabilir.",
  "ankara_beypazari|Ankara Beypazarı Devlet Hastanesi|Ankara|Beypazarı|Devlet Hastanesi|72.5|72.0|5/10|6.000-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Turistik ve tarihi ilçe.|Ankara merkeze 1.5 saat.",
  "ankara_sereflikochisar|Ankara Şereflikoçhisar Devlet Hastanesi|Ankara|Şereflikoçhisar|Devlet Hastanesi|71.8|71.3|5/10|5.500-8.000 TL|24 Saat Nöbet|9.000-12.000 TL|Ankara-Aksaray yolu üzerinde.|Ankara'ya çok uzak (2 saat).",
  "ankara_kizilcahamam|Ankara Kızılcahamam Devlet Hastanesi|Ankara|Kızılcahamam|Devlet Hastanesi|72.2|71.7|5/10|6.000-8.500 TL|24 Saat Nöbet|10.000-13.000 TL|Doğası güzel, termal ilçe.|Sosyal imkanlar kısıtlı.",
  "ankara_haymana|Ankara Haymana Devlet Hastanesi|Ankara|Haymana|Devlet Hastanesi|71.5|71.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Kaplıcaları meşhur sakin ilçe.|Gelişmemiş ilçe.",
  "ankara_elmadas|Ankara Elmadağ Devlet Hastanesi|Ankara|Elmadağ|Devlet Hastanesi|72.0|71.5|5/10|5.500-8.000 TL|24 Saat Nöbet|9.000-12.000 TL|Ankara merkeze yakın.|Küçük hastane.",

  // ANTALYA (8)
  "antalya_sehir|Antalya Şehir Hastanesi|Antalya|Kepez|Şehir Hastanesi|75.1|74.6|7/10|10.000-14.000 TL|24 Saat Nöbet|18.000-25.000 TL|Yeni tesis, sosyal imkanlar harika.|Yaz aylarında turizm yoğunluğu iş yükünü katlar.",
  "antalya_eah|Antalya Eğitim ve Araştırma Hastanesi|Antalya|Muratpaşa|Eğitim ve Araştırma|75.6|75.1|8/10|10.000-13.000 TL|24 Saat Nöbet|20.000-28.000 TL|Merkezi konum ve oturmuş yapı.|Kiralar memur için ciddi külfet.",
  "antalya_alanya|Antalya Alanya EAH|Antalya|Alanya|Eğitim ve Araştırma|74.8|74.3|8/10|9.000-12.000 TL|24 Saat Nöbet|17.000-25.000 TL|Tatil beldesinde çalışmak keyifli.|Yabancı hasta iletişim zorlukları ve kira sorunu.",
  "antalya_manavgat|Antalya Manavgat Devlet Hastanesi|Antalya|Manavgat|Devlet Hastanesi|74.3|73.8|7/10|8.000-11.000 TL|24 Saat Nöbet|15.000-22.000 TL|Büyük ilçe, yaşam standartları iyi.|Turizm sezonunda acili çok yoğun.",
  "antalya_kemer|Antalya Kemer Devlet Hastanesi|Antalya|Kemer|Devlet Hastanesi|73.9|73.4|6/10|7.000-10.000 TL|24 Saat Nöbet|16.000-23.000 TL|Deniz kenarında şirin ilçe.|Kışın çok tenha, yazın aşırı kalabalık.",
  "antalya_kumluca|Antalya Kumluca Devlet Hastanesi|Antalya|Kumluca|Devlet Hastanesi|73.5|73.0|6/10|7.000-9.500 TL|24 Saat Nöbet|14.000-20.000 TL|Sakin, merkeze yakın ilçe.|Seracılık yaygın, yazları aşırı sıcak.",
  "antalya_korkuteli|Antalya Korkuteli Devlet Hastanesi|Antalya|Korkuteli|Devlet Hastanesi|73.0|72.5|5/10|6.000-8.500 TL|24 Saat Nöbet|12.000-16.000 TL|Antalya'nın yaylası, serin yazlar.|Merkeze nispeten uzak.",
  "antalya_kas|Antalya Kaş Devlet Hastanesi|Antalya|Kaş|Devlet Hastanesi|73.2|72.7|5/10|6.000-8.500 TL|24 Saat Nöbet|15.000-22.000 TL|Doğa harikası tatil beldesi.|Merkeze çok uzak (3 saat) ve ev bulmak zor.",

  // ARDAHAN (3)
  "ardahan_devlet|Ardahan Devlet Hastanesi|Ardahan|Merkez|Devlet Hastanesi|68.8|68.3|5/10|7.000-10.000 TL|24 Saat Nöbet|9.000-13.000 TL|Doğu görevi ve puan için ideal sakin hastane.|Erzurum'a bağımlılık yüksek.",
  "ardahan_gole|Ardahan Göle Devlet Hastanesi|Ardahan|Göle|Devlet Hastanesi|67.9|67.4|4/10|5.000-7.500 TL|24 Saat Nöbet|7.000-10.000 TL|Çok sakin.|Kışları eksi 30 dereceler görülür.",
  "ardahan_posof|Ardahan Posof Devlet Hastanesi|Ardahan|Posof|Devlet Hastanesi|67.5|67.0|3/10|4.000-6.000 TL|24 Saat Nöbet|6.000-9.000 TL|Yeşillikler içinde sınır ilçesi.|Çok uzak ve ulaşım zor.",

  // ARTVİN (5)
  "artvin_devlet|Artvin Devlet Hastanesi|Artvin|Merkez|Devlet Hastanesi|71.5|71.0|5/10|7.000-10.000 TL|24 Saat Nöbet|10.000-14.000 TL|Doğa harikası, sakin hastane.|Dağlık arazi ve çok kısıtlı sosyal yaşam.",
  "artvin_hopa|Artvin Hopa Devlet Hastanesi|Artvin|Hopa|Devlet Hastanesi|71.1|70.6|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Sarp sınır kapısına yakın sahil kenti.|Yüksek nem ve yağış.",
  "artvin_arhavi|Artvin Arhavi Devlet Hastanesi|Artvin|Arhavi|Devlet Hastanesi|70.8|70.3|4/10|5.000-8.000 TL|24 Saat Nöbet|8.500-12.000 TL|Şirin sahil ilçesi.|Küçük ve sakin.",
  "artvin_borcka|Artvin Borçka Devlet Hastanesi|Artvin|Borçka|Devlet Hastanesi|70.5|70.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Karagöl'e yakın doğa cenneti.|Dar bir vadide yer alır.",
  "artvin_savsat|Artvin Şavşat Devlet Hastanesi|Artvin|Şavşat|Devlet Hastanesi|70.0|69.5|3/10|4.000-6.000 TL|24 Saat Nöbet|7.000-10.000 TL|Cittaslow (Sakin Şehir) unvanlı.|Artvin merkeze virajlı ve uzun yollar.",

  // AYDIN (8)
  "aydin_ataturk|Aydın Atatürk Devlet Hastanesi|Aydın|Efeler|Devlet Hastanesi|74.5|74.0|6/10|8.000-11.000 TL|24 Saat Nöbet|14.000-20.000 TL|Ege'nin sıcak ve sosyal ili. Merkezi.|Yazın aşırı sıcaklar yorucu olabilir.",
  "aydin_soke|Aydın Söke Fehime Faik Kocagöz DH|Aydın|Söke|Devlet Hastanesi|73.9|73.4|6/10|7.500-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|Kuşadası ve Didim'e çok yakın.|Tarım bölgesi, spesifik vakalar kısıtlı.",
  "aydin_kusadasi|Aydın Kuşadası Devlet Hastanesi|Aydın|Kuşadası|Devlet Hastanesi|74.8|74.3|7/10|8.500-11.500 TL|24 Saat Nöbet|18.000-25.000 TL|Tatil beldesi, sosyal hayat çok renkli.|Yazın çok yoğun, kiralar aşırı yüksek.",
  "aydin_didim|Aydın Didim Devlet Hastanesi|Aydın|Didim|Devlet Hastanesi|74.3|73.8|7/10|8.000-11.000 TL|24 Saat Nöbet|16.000-22.000 TL|Deniz kenarı turistik ilçe.|Yaz/kış nüfus farkı çok fazla.",
  "aydin_nazilli|Aydın Nazilli Devlet Hastanesi|Aydın|Nazilli|Devlet Hastanesi|73.5|73.0|6/10|7.000-10.000 TL|24 Saat Nöbet|11.000-15.000 TL|Aydın'ın en büyük ilçelerinden.|Sıradan bir Anadolu ilçesi görünümünde.",
  "aydin_cine|Aydın Çine Devlet Hastanesi|Aydın|Çine|Devlet Hastanesi|72.8|72.3|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Muğla yolunda şirin ilçe.|Merkeze 45 dk mesafede.",
  "aydin_germencik|Aydın Germencik Devlet Hastanesi|Aydın|Germencik|Devlet Hastanesi|72.5|72.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.500-12.000 TL|Sakin, otoyol kenarında.|Gelişmemiş ilçe.",
  "aydin_bozdogan|Aydın Bozdoğan Devlet Hastanesi|Aydın|Bozdoğan|Devlet Hastanesi|71.9|71.4|4/10|4.500-6.500 TL|24 Saat Nöbet|8.000-11.000 TL|Doğası güzel.|Ulaşımı biraz ters.",

  // BALIKESİR (9)
  "balikesir_devlet|Balıkesir Devlet Hastanesi|Balıkesir|Karesi|Devlet Hastanesi|73.8|73.3|6/10|8.000-11.000 TL|24 Saat Nöbet|13.000-18.000 TL|Hem denize hem büyükşehirlere yakın kavşak.|Tesis yenilenme ihtiyacı duyuyor.",
  "balikesir_bandirma|Balıkesir Bandırma EAH|Balıkesir|Bandırma|Eğitim ve Araştırma|73.5|73.0|7/10|8.000-11.500 TL|24 Saat Nöbet|14.000-19.000 TL|Gelişmiş sahil ilçesi, İDO ile İstanbul'a direkt ulaşım.|İlçe olmasına rağmen yaşam pahalı.",
  "balikesir_edremit|Balıkesir Edremit Devlet Hastanesi|Balıkesir|Edremit|Devlet Hastanesi|74.2|73.7|7/10|8.500-12.000 TL|24 Saat Nöbet|15.000-22.000 TL|Körfezin merkezi, deniz ve Kazdağları.|Yazın trafik ve hasta yoğunluğu.",
  "balikesir_ayvalik|Balıkesir Ayvalık Devlet Hastanesi|Balıkesir|Ayvalık|Devlet Hastanesi|74.5|74.0|7/10|8.500-12.000 TL|24 Saat Nöbet|16.000-25.000 TL|Türkiye'nin en popüler tatil yörelerinden.|Çok pahalı.",
  "balikesir_burhaniye|Balıkesir Burhaniye Devlet Hastanesi|Balıkesir|Burhaniye|Devlet Hastanesi|73.9|73.4|6/10|7.500-10.500 TL|24 Saat Nöbet|13.000-18.000 TL|Sakin sahil ilçesi, Edremit'e komşu.|Yaz/kış nüfus dengesizliği.",
  "balikesir_susurluk|Balıkesir Susurluk Devlet Hastanesi|Balıkesir|Susurluk|Devlet Hastanesi|73.0|72.5|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Bursa-Balıkesir yolu üzerinde.|İlçe merkezinde sosyal hayat az.",
  "balikesir_bigadic|Balıkesir Bigadiç Devlet Hastanesi|Balıkesir|Bigadiç|Devlet Hastanesi|72.5|72.0|4/10|5.500-8.000 TL|24 Saat Nöbet|9.000-12.000 TL|Merkeze çok yakın (30 dk).|Sıradan bir ilçe.",
  "balikesir_sindirgi|Balıkesir Sındırgı Devlet Hastanesi|Balıkesir|Sındırgı|Devlet Hastanesi|72.1|71.6|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Termal turizm ve doğal güzellikler.|Ulaşımı biraz sapa.",
  "balikesir_dursunbey|Balıkesir Dursunbey Devlet Hastanesi|Balıkesir|Dursunbey|Devlet Hastanesi|71.5|71.0|4/10|5.000-7.000 TL|24 Saat Nöbet|7.500-10.000 TL|Sakin.|Balıkesir merkeze yolu virajlı ve uzun.",

  // BARTIN (2)
  "bartin_devlet|Bartın Devlet Hastanesi|Bartın|Merkez|Devlet Hastanesi|72.3|71.8|6/10|7.000-10.000 TL|24 Saat Nöbet|11.000-16.000 TL|Denize yakın şirin Karadeniz kenti.|Hastane fiziki şartları gelişime açık.",
  "bartin_ulus|Bartın Ulus Devlet Hastanesi|Bartın|Ulus|Devlet Hastanesi|71.2|70.7|4/10|4.500-7.000 TL|24 Saat Nöbet|8.000-11.000 TL|Yeşillikler içinde orman ilçesi.|Sosyalleşme sıfır.",

  // BATMAN (4)
  "batman_eah|Batman Eğitim ve Araştırma Hastanesi|Batman|Merkez|Eğitim ve Araştırma|69.8|69.2|7/10|9.000-12.000 TL|24 Saat Nöbet|10.000-15.000 TL|Güneydoğunun modern ve genç dinamik şehri.|Yaz aylarında kurak ve sıcak hava.",
  "batman_kozluk|Batman Kozluk Devlet Hastanesi|Batman|Kozluk|Devlet Hastanesi|68.5|68.0|5/10|6.000-9.000 TL|24 Saat Nöbet|8.000-11.000 TL|Tasarruf için uygun.|Küçük yerleşim.",
  "batman_besiri|Batman Beşiri Devlet Hastanesi|Batman|Beşiri|Devlet Hastanesi|68.8|68.3|4/10|5.000-7.500 TL|24 Saat Nöbet|7.500-10.500 TL|Merkeze çok yakın.|İlçe hayatı çok durgun.",
  "batman_sason|Batman Sason Devlet Hastanesi|Batman|Sason|Devlet Hastanesi|68.0|67.5|4/10|5.000-7.000 TL|24 Saat Nöbet|7.000-10.000 TL|Dağlık ve serin.|Yolu zorludur.",

  // BAYBURT (1)
  "bayburt_devlet|Bayburt Devlet Hastanesi|Bayburt|Merkez|Devlet Hastanesi|70.5|70.0|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Sakinlik arayanlar için tasarruf imkanı.|Kışları aşırı soğuk ve mahrumiyet.",

  // BİLECİK (4)
  "bilecik_eah|Bilecik Eğitim ve Araştırma Hastanesi|Bilecik|Merkez|Eğitim ve Araştırma|72.6|72.1|6/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Hızlı tren hattı üstünde pratik ulaşım.|Şehir küçük, coğrafi olarak engebeli.",
  "bilecik_bozuyuk|Bilecik Bozüyük Devlet Hastanesi|Bilecik|Bozüyük|Devlet Hastanesi|72.2|71.7|5/10|6.000-9.000 TL|24 Saat Nöbet|10.000-13.000 TL|Sanayi ilçesi, Eskişehir'e çok yakın.|İş çıkışı direkt Eskişehir'e gidenlerin çokluğu sosyalleşmeyi azaltır.",
  "bilecik_osmaneli|Bilecik Osmaneli Devlet Hastanesi|Bilecik|Osmaneli|Devlet Hastanesi|71.8|71.3|4/10|5.000-7.500 TL|24 Saat Nöbet|9.000-12.000 TL|Şirin ve düzenli.|Sakin.",
  "bilecik_sogut|Bilecik Söğüt Devlet Hastanesi|Bilecik|Söğüt|Devlet Hastanesi|71.5|71.0|4/10|4.500-7.000 TL|24 Saat Nöbet|8.000-11.000 TL|Tarihi Osmanlı ilçesi.|Sosyal olanaklar dar.",

  // BİNGÖL (4)
  "bingol_devlet|Bingöl Devlet Hastanesi|Bingöl|Merkez|Devlet Hastanesi|69.9|69.4|6/10|8.000-11.000 TL|24 Saat Nöbet|10.000-14.000 TL|Toplu taşıma kolay, kiralar nispeten uygun.|Klinik olarak büyük illere sevk sayısı çok.",
  "bingol_genc|Bingöl Genç Devlet Hastanesi|Bingöl|Genç|Devlet Hastanesi|68.8|68.3|5/10|6.000-8.500 TL|24 Saat Nöbet|8.000-11.000 TL|Merkeze çok yakın.|Tasarruf ilçesi.",
  "bingol_solhan|Bingöl Solhan Devlet Hastanesi|Bingöl|Solhan|Devlet Hastanesi|68.5|68.0|5/10|5.500-8.000 TL|24 Saat Nöbet|7.500-10.500 TL|Sakin.|Muş yolu üzerinde.",
  "bingol_karliova|Bingöl Karlıova Devlet Hastanesi|Bingöl|Karlıova|Devlet Hastanesi|67.8|67.3|4/10|5.000-7.500 TL|24 Saat Nöbet|7.000-10.000 TL|Doğası güzel.|Kışın yoğun kar yağışı yolları kapatabilir.",

  // BİTLİS (4)
  "bitlis_devlet|Bitlis Devlet Hastanesi|Bitlis|Merkez|Devlet Hastanesi|69.5|69.0|6/10|7.500-10.500 TL|24 Saat Nöbet|10.000-14.000 TL|Tarihi şehir.|Vadide yer aldığı için dar bir alan.",
  "bitlis_tatvan|Bitlis Tatvan Devlet Hastanesi|Bitlis|Tatvan|Devlet Hastanesi|70.1|69.6|6/10|7.500-10.500 TL|24 Saat Nöbet|11.000-15.000 TL|Van Gölü kıyısında, Bitlis merkezden daha güzel.|Kış ayları kar esareti yaşanabiliyor.",
  "bitlis_ahlat|Bitlis Ahlat Devlet Hastanesi|Bitlis|Ahlat|Devlet Hastanesi|69.2|68.7|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Tarihi Selçuklu mezarlığı ve göl kenarı.|Küçük ilçe.",
  "bitlis_adilcevaz|Bitlis Adilcevaz Devlet Hastanesi|Bitlis|Adilcevaz|Devlet Hastanesi|68.8|68.3|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-12.000 TL|Göl manzaralı sakin yer.|Ulaşım imkanları kısıtlı.",

  // BOLU (4)
  "bolu_eah|Bolu İzzet Baysal EAH|Bolu|Merkez|Eğitim ve Araştırma|73.4|72.9|7/10|8.000-11.500 TL|24 Saat Nöbet|13.000-18.000 TL|Muazzam doğa, Ankara-İstanbul arası ideal konum.|Kış sporları dışında aktivite kısıtlı.",
  "bolu_gerede|Bolu Gerede Devlet Hastanesi|Bolu|Gerede|Devlet Hastanesi|72.5|72.0|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Ankara'ya çok yakın.|Çok soğuk rüzgarları meşhurdur.",
  "bolu_mudurnu|Bolu Mudurnu Devlet Hastanesi|Bolu|Mudurnu|Devlet Hastanesi|71.8|71.3|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Tarihi ve şirin konaklar diyarı.|Sakinlik sıkar diyene gelmez.",
  "bolu_goynuk|Bolu Göynük Devlet Hastanesi|Bolu|Göynük|Devlet Hastanesi|71.5|71.0|4/10|4.500-7.000 TL|24 Saat Nöbet|7.500-10.500 TL|Sakin, tarihi doku.|Uzak ilçe.",

  // BURDUR (3)
  "burdur_devlet|Burdur Devlet Hastanesi|Burdur|Merkez|Devlet Hastanesi|73.7|73.2|6/10|7.000-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|Öğrenci kenti, sakin ve güvenli.|Büyükşehirlere göre aktivite kısıtlı.",
  "burdur_bucak|Burdur Bucak Devlet Hastanesi|Burdur|Bucak|Devlet Hastanesi|73.1|72.6|5/10|6.000-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Burdur merkezden daha hareketli ve gelişmiş.|Kiralar beklentinin üzerinde olabiliyor.",
  "burdur_golhisar|Burdur Gölhisar Devlet Hastanesi|Burdur|Gölhisar|Devlet Hastanesi|72.4|71.9|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Tasarruf için uygun.|Küçük yerleşim yeri.",

  // BURSA (10)
  "bursa_sehir|Bursa Şehir Hastanesi|Bursa|Nilüfer|Şehir Hastanesi|73.8|73.3|7/10|11.000-14.000 TL|24 Saat Nöbet|16.000-22.000 TL|Nilüfer gibi nezih bir ilçede modern kampüs.|Büyük şehir karmaşası merkeze giden yollarda yorucu olabilir.",
  "bursa_ihtisas|Bursa Yüksek İhtisas EAH|Bursa|Yıldırım|Eğitim ve Araştırma|73.5|73.0|8/10|10.000-13.000 TL|24 Saat Nöbet|15.000-20.000 TL|Bursa'nın en köklü ve yoğun hastanelerinden.|Hasta sirkülasyonu oldukça fazla.",
  "bursa_inegol|Bursa İnegöl Devlet Hastanesi|Bursa|İnegöl|Devlet Hastanesi|73.1|72.6|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Sanayisi güçlü büyük ilçe, ekonomik canlılık.|Hava kirliliği ciddi bir problem.",
  "bursa_mustafakemalpasa|Bursa Mustafakemalpaşa Devlet Hastanesi|Bursa|Mustafakemalpaşa|Devlet Hastanesi|72.8|72.3|5/10|7.000-9.500 TL|24 Saat Nöbet|11.000-15.000 TL|Bursa merkeze 1 saat mesafede, geniş ilçe.|Sıradan bir ilçe.",
  "bursa_karacabey|Bursa Karacabey Devlet Hastanesi|Bursa|Karacabey|Devlet Hastanesi|72.9|72.4|5/10|7.000-9.500 TL|24 Saat Nöbet|11.000-15.000 TL|İzmir yolu üzerinde, gelişmiş.|Merkeze nispeten uzak.",
  "bursa_gemlik|Bursa Gemlik Devlet Hastanesi|Bursa|Gemlik|Devlet Hastanesi|73.4|72.9|6/10|7.500-10.000 TL|24 Saat Nöbet|13.000-18.000 TL|Deniz kenarında, TOGG fabrikasıyla parlayan ilçe.|Deprem riski olan bölgelerden.",
  "bursa_mudanya|Bursa Mudanya Devlet Hastanesi|Bursa|Mudanya|Devlet Hastanesi|73.6|73.1|6/10|7.500-10.000 TL|24 Saat Nöbet|14.000-20.000 TL|Bursa'nın sayfiye yeri, BUDO ile İstanbul'a kolay ulaşım.|Kiralar yüksek.",
  "bursa_orhangazi|Bursa Orhangazi Devlet Hastanesi|Bursa|Orhangazi|Devlet Hastanesi|72.5|72.0|5/10|6.500-9.000 TL|24 Saat Nöbet|11.000-15.000 TL|İznik gölüne yakın, sanayi ilçesi.|Sosyal ortam kısıtlı.",
  "bursa_iznik|Bursa İznik Devlet Hastanesi|Bursa|İznik|Devlet Hastanesi|72.2|71.7|4/10|5.500-8.000 TL|24 Saat Nöbet|10.000-14.000 TL|Tarihi ve göl manzaralı.|Kışın çok sessiz.",
  "bursa_yenisehir|Bursa Yenişehir Devlet Hastanesi|Bursa|Yenişehir|Devlet Hastanesi|72.0|71.5|4/10|5.500-8.000 TL|24 Saat Nöbet|10.000-13.000 TL|Havalimanı var, sakin ilçe.|Merkeze uzak.",

  // ÇANAKKALE (6)
  "canakkale_mehmet_akif|Çanakkale Mehmet Akif Ersoy DH|Çanakkale|Merkez|Devlet Hastanesi|74.5|74.0|6/10|8.000-11.000 TL|24 Saat Nöbet|16.000-22.000 TL|Boğaz manzaralı, Türkiye'nin en yaşanabilir illerinden.|Yaz aylarında kiralar çok artıyor.",
  "canakkale_biga|Çanakkale Biga Devlet Hastanesi|Çanakkale|Biga|Devlet Hastanesi|73.8|73.3|6/10|7.500-10.500 TL|24 Saat Nöbet|12.000-17.000 TL|Sanayisiyle il merkezine kafa tutan ilçe.|Şehir içi trafik.",
  "canakkale_can|Çanakkale Çan Devlet Hastanesi|Çanakkale|Çan|Devlet Hastanesi|73.1|72.6|5/10|6.500-9.500 TL|24 Saat Nöbet|10.000-14.000 TL|Sakin, termal ilçe.|Merkeze uzaklık.",
  "canakkale_gelibolu|Çanakkale Gelibolu Devlet Hastanesi|Çanakkale|Gelibolu|Devlet Hastanesi|73.5|73.0|5/10|7.000-10.000 TL|24 Saat Nöbet|13.000-18.000 TL|Tarihi yarımadada, boğazın diğer yakası.|Kışın rüzgarlı ve sakin.",
  "canakkale_ezine|Çanakkale Ezine Devlet Hastanesi|Çanakkale|Ezine|Devlet Hastanesi|72.9|72.4|5/10|6.000-8.500 TL|24 Saat Nöbet|11.000-15.000 TL|İzmir yolu üzerinde.|Küçük.",
  "canakkale_ayvacik|Çanakkale Ayvacık Devlet Hastanesi|Çanakkale|Ayvacık|Devlet Hastanesi|72.6|72.1|4/10|5.500-8.000 TL|24 Saat Nöbet|10.000-14.000 TL|Assos'a yakın, doğa harikası.|Sosyalleşme alanları sınırlı.",

  // ÇANKIRI (3)
  "cankiri_devlet|Çankırı Devlet Hastanesi|Çankırı|Merkez|Devlet Hastanesi|72.1|71.6|5/10|6.000-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Ankara'ya yakın, maddi birikim yapılır.|Aktivite bulmak oldukça zor.",
  "cankiri_cerkes|Çankırı Çerkeş Devlet Hastanesi|Çankırı|Çerkeş|Devlet Hastanesi|71.5|71.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|İstanbul yolu üzerinde.|Çok sakin.",
  "cankiri_ilgaz|Çankırı Ilgaz Devlet Hastanesi|Çankırı|Ilgaz|Devlet Hastanesi|71.2|70.7|4/10|4.500-7.000 TL|24 Saat Nöbet|7.500-10.500 TL|Kayak merkezine yakın.|Ufak ilçe.",

  // ÇORUM (4)
  "corum_eah|Çorum Erol Olçok EAH|Çorum|Merkez|Eğitim ve Araştırma|72.6|72.1|7/10|8.000-12.000 TL|24 Saat Nöbet|11.000-16.000 TL|Teşvikler düzenli, yaşam masrafı düşük.|İç Anadolu standartlarında bir temposu var.",
  "corum_sungurlu|Çorum Sungurlu Devlet Hastanesi|Çorum|Sungurlu|Devlet Hastanesi|71.8|71.3|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-12.000 TL|Ankara yolu üzerinde büyük ilçe.|Merkeze 1 saat uzaklıkta.",
  "corum_osmancik|Çorum Osmancık Devlet Hastanesi|Çorum|Osmancık|Devlet Hastanesi|71.5|71.0|5/10|5.500-8.000 TL|24 Saat Nöbet|8.500-11.500 TL|Kızılırmak kenarında pirinç diyarı.|Küçük ilçe.",
  "corum_alaca|Çorum Alaca Devlet Hastanesi|Çorum|Alaca|Devlet Hastanesi|71.0|70.5|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin ortam.|Gelişmemiş.",

  // DENİZLİ (6)
  "denizli_devlet|Denizli Devlet Hastanesi|Denizli|Merkezefendi|Devlet Hastanesi|74.6|74.1|7/10|8.000-11.500 TL|24 Saat Nöbet|14.000-19.000 TL|Ege'nin sanayi kenti, ekonomik rahatlık.|Hastane yoğun ve personel sirkülasyonu var.",
  "denizli_servergazi|Denizli Servergazi Devlet Hastanesi|Denizli|Merkezefendi|Devlet Hastanesi|74.2|73.7|6/10|7.500-10.500 TL|24 Saat Nöbet|14.000-19.000 TL|Merkezde ikinci bir alternatif, daha sakin.|Bina biraz eski.",
  "denizli_civril|Denizli Çivril Devlet Hastanesi|Denizli|Çivril|Devlet Hastanesi|73.5|73.0|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Göl manzaralı büyük ilçe.|Merkeze oldukça uzak (1.5 saat).",
  "denizli_avas|Denizli Acıpayam Devlet Hastanesi|Denizli|Acıpayam|Devlet Hastanesi|73.1|72.6|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Antalya yolu üzerinde.|Sakin ilçe.",
  "denizli_tavas|Denizli Tavas Devlet Hastanesi|Denizli|Tavas|Devlet Hastanesi|72.8|72.3|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-12.000 TL|Muğla yolu üzerinde.|Küçük.",
  "denizli_buldan|Denizli Buldan Devlet Hastanesi|Denizli|Buldan|Devlet Hastanesi|72.5|72.0|4/10|5.500-8.000 TL|24 Saat Nöbet|8.500-11.500 TL|Tarihi evleriyle meşhur.|Sosyalleşme az.",

  // DİYARBAKIR (5)
  "diyarbakir_gazi|Diyarbakır Gazi Yaşargil EAH|Diyarbakır|Yenişehir|Eğitim ve Araştırma|70.3|69.8|9/10|9.000-13.000 TL|24 Saat Nöbet|11.000-16.000 TL|Hizmet puanı çok yüksek, klinik tecrübe artar.|Hasta yakını profili zaman zaman zorlayıcı.",
  "diyarbakir_selahaddin|Diyarbakır Selahaddin Eyyubi DH|Diyarbakır|Yenişehir|Devlet Hastanesi|69.8|69.3|8/10|8.500-12.000 TL|24 Saat Nöbet|11.000-15.000 TL|Şehir merkezinde ulaşımı kolay.|Eski hastane.",
  "diyarbakir_ergani|Diyarbakır Ergani Devlet Hastanesi|Diyarbakır|Ergani|Devlet Hastanesi|69.5|69.0|7/10|8.000-11.000 TL|24 Saat Nöbet|9.000-13.000 TL|Diyarbakır'ın en büyük ilçesi.|İlçe yoğunluğu fazla.",
  "diyarbakir_bismil|Diyarbakır Bismil Devlet Hastanesi|Diyarbakır|Bismil|Devlet Hastanesi|69.2|68.7|6/10|7.500-10.500 TL|24 Saat Nöbet|8.500-12.000 TL|Tarım bölgesi.|Sıcak ve kurak.",
  "diyarbakir_silvan|Diyarbakır Silvan Devlet Hastanesi|Diyarbakır|Silvan|Devlet Hastanesi|68.9|68.4|6/10|7.000-10.000 TL|24 Saat Nöbet|8.000-11.000 TL|Tarihi ilçe.|Uzaklık.",

  // DÜZCE (3)
  "duzce_ataturk|Düzce Atatürk Devlet Hastanesi|Düzce|Merkez|Devlet Hastanesi|72.8|72.3|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Otoban kenarında, ulaşımı çok rahat.|Hava kirliliği dönem dönem yüksek.",
  "duzce_akcakoca|Düzce Akçakoca Devlet Hastanesi|Düzce|Akçakoca|Devlet Hastanesi|72.2|71.7|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-15.000 TL|Batı Karadeniz'in incisi, sahil kenti.|Yazın turistik yoğunluk.",
  "duzce_kaynasli|Düzce Kaynaşlı Devlet Hastanesi|Düzce|Kaynaşlı|Devlet Hastanesi|71.5|71.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Bolu dağı eteklerinde.|Küçük.",

  // EDİRNE (4)
  "edirne_sultan_murat|Edirne Sultan 1. Murat Devlet Hastanesi|Edirne|Merkez|Devlet Hastanesi|73.4|72.9|6/10|8.000-11.000 TL|24 Saat Nöbet|14.000-19.000 TL|Modern, öğrenci yoğunluklu Trakya şehri.|Sınır kapısı yoğunlukları acili etkiler.",
  "edirne_kesan|Edirne Keşan Devlet Hastanesi|Edirne|Keşan|Devlet Hastanesi|72.8|72.3|6/10|7.500-10.500 TL|24 Saat Nöbet|12.000-16.000 TL|Saros körfezine yakın büyük ilçe.|Merkeze 1.5 saat.",
  "edirne_uzunkopru|Edirne Uzunköprü Devlet Hastanesi|Edirne|Uzunköprü|Devlet Hastanesi|72.4|71.9|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Tarihi köprüsüyle meşhur şirin ilçe.|Sosyal imkan dar.",
  "edirne_ipsala|Edirne İpsala Devlet Hastanesi|Edirne|İpsala|Devlet Hastanesi|71.8|71.3|4/10|5.500-8.000 TL|24 Saat Nöbet|8.500-12.000 TL|Sınır kapısı ilçesi.|Gelişmemiş.",

  // ELAZIĞ (3)
  "elazig_sehir|Elazığ Fethi Sekin Şehir Hastanesi|Elazığ|Merkez|Şehir Hastanesi|71.0|70.5|7/10|10.000-13.000 TL|24 Saat Nöbet|11.000-15.000 TL|Altyapısı güçlü modern bölge üssü.|Sosyal ortam büyükşehirlere göre sakin.",
  "elazig_kovancilar|Elazığ Kovancılar Devlet Hastanesi|Elazığ|Kovancılar|Devlet Hastanesi|70.2|69.7|5/10|6.000-8.500 TL|24 Saat Nöbet|8.000-11.000 TL|Bingöl yolu üzerinde.|Sakin.",
  "elazig_karakocan|Elazığ Karakoçan Devlet Hastanesi|Elazığ|Karakoçan|Devlet Hastanesi|69.8|69.3|4/10|5.500-8.000 TL|24 Saat Nöbet|7.500-10.500 TL|Tasarruf ilçesi.|Uzak ilçe.",

  // ERZİNCAN (2)
  "erzincan_eah|Erzincan Mengücek Gazi EAH|Erzincan|Merkez|Eğitim ve Araştırma|71.2|70.7|6/10|8.000-11.000 TL|24 Saat Nöbet|10.000-14.000 TL|Doğa sporları, temiz havası ve sakin şehir yapısı.|Şehrin popülasyonu yaşlı ağırlıklı.",
  "erzincan_tercan|Erzincan Tercan Devlet Hastanesi|Erzincan|Tercan|Devlet Hastanesi|70.1|69.6|4/10|5.000-7.500 TL|24 Saat Nöbet|7.000-10.000 TL|Erzurum'a daha yakın.|Çok küçük.",

  // ERZURUM (4)
  "erzurum_sehir|Erzurum Şehir Hastanesi|Erzurum|Palandöken|Şehir Hastanesi|71.4|70.9|8/10|10.000-14.000 TL|24 Saat Nöbet|11.000-16.000 TL|Kışın kapalı tüp geçitler kurtarıcı.|Aşırı soğuk iklim alışkın olmayanlar için zorlayıcı.",
  "erzurum_oltu|Erzurum Oltu Devlet Hastanesi|Erzurum|Oltu|Devlet Hastanesi|70.5|70.0|5/10|6.000-8.500 TL|24 Saat Nöbet|8.000-11.000 TL|Erzurum'un Karadeniz iklimine yakın büyük ilçesi.|Merkeze 2 saat uzaklık.",
  "erzurum_askale|Erzurum Aşkale Devlet Hastanesi|Erzurum|Aşkale|Devlet Hastanesi|70.0|69.5|4/10|5.000-7.500 TL|24 Saat Nöbet|7.500-10.500 TL|Erzincan yolu üzerinde.|Sosyalleşme imkanı yok.",
  "erzurum_horasan|Erzurum Horasan Devlet Hastanesi|Erzurum|Horasan|Devlet Hastanesi|69.8|69.3|4/10|5.500-8.000 TL|24 Saat Nöbet|7.500-10.500 TL|Kars yolu üzerinde.|Sert kışlar.",

  // ESKİŞEHİR (4)
  "eskisehir_sehir|Eskişehir Şehir Hastanesi|Eskişehir|Odunpazarı|Şehir Hastanesi|74.8|74.3|7/10|10.000-13.000 TL|24 Saat Nöbet|14.000-20.000 TL|Öğrenci kenti, tramvay hattı var, sosyal ortamı mükemmel.|Türkiye'nin en popüler illerinden biri olduğu için tayin süreçleri yavaş.",
  "eskisehir_yunus_emre|Eskişehir Yunus Emre Devlet Hastanesi|Eskişehir|Tepebaşı|Devlet Hastanesi|74.5|74.0|6/10|8.000-11.000 TL|24 Saat Nöbet|13.000-18.000 TL|Şehrin merkezinde, ulaşımı çok kolay.|Bina şehir hastanesine göre eski.",
  "eskisehir_sivrihisar|Eskişehir Sivrihisar Devlet Hastanesi|Eskişehir|Sivrihisar|Devlet Hastanesi|73.2|72.7|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Ankara yolu üzerinde tarihi ilçe.|Merkeze 1 saat.",
  "eskisehir_cifteler|Eskişehir Çifteler Devlet Hastanesi|Eskişehir|Çifteler|Devlet Hastanesi|72.8|72.3|4/10|5.500-8.000 TL|24 Saat Nöbet|8.500-12.000 TL|Sakarya nehrinin doğduğu ilçe.|Küçük ve sakin.",

  // GAZİANTEP (5)
  "gaziantep_sehir|Gaziantep Şehir Hastanesi|Gaziantep|Şahinbey|Şehir Hastanesi|71.8|71.3|8/10|10.000-14.000 TL|24 Saat Nöbet|14.000-20.000 TL|Yeni kampüs, modern teşhis üniteleri.|Şehrin genel trafik ve yaşam karmaşası.",
  "gaziantep_ersin_arslan|Gaziantep Dr. Ersin Arslan EAH|Gaziantep|Şahinbey|Eğitim ve Araştırma|71.5|71.0|8/10|9.500-13.000 TL|24 Saat Nöbet|13.000-18.000 TL|Şehrin en köklü ve yoğun kurumu.|Bina eski, hasta profili zorlayıcı olabilir.",
  "gaziantep_sehitkamil|Gaziantep Şehitkamil Devlet Hastanesi|Gaziantep|Şehitkamil|Devlet Hastanesi|71.2|70.7|7/10|8.500-12.000 TL|24 Saat Nöbet|12.000-17.000 TL|Ulaşımı kolay.|Acili yoğun.",
  "gaziantep_nizip|Gaziantep Nizip Devlet Hastanesi|Gaziantep|Nizip|Devlet Hastanesi|70.8|70.3|6/10|7.500-10.500 TL|24 Saat Nöbet|10.000-14.000 TL|Büyük ilçe.|Şanlıurfa sınırına yakın.",
  "gaziantep_islahiye|Gaziantep İslahiye Devlet Hastanesi|Gaziantep|İslahiye|Devlet Hastanesi|70.5|70.0|5/10|6.500-9.500 TL|24 Saat Nöbet|9.000-13.000 TL|Nurdağı eteklerinde.|Deprem sonrası toparlanma süreci.",

  // GİRESUN (4)
  "giresun_eah|Giresun Eğitim ve Araştırma Hastanesi|Giresun|Merkez|Eğitim ve Araştırma|73.1|72.6|7/10|8.000-11.500 TL|24 Saat Nöbet|12.000-17.000 TL|Denize sıfır huzurlu ve güzel bir şehir.|Arsa sıkıntısı nedeniyle ev kiraları pahalı.",
  "giresun_bulancak|Giresun Bulancak Devlet Hastanesi|Giresun|Bulancak|Devlet Hastanesi|72.5|72.0|6/10|7.000-10.000 TL|24 Saat Nöbet|10.000-15.000 TL|Ordu sınırında, merkeze çok yakın.|Şehir içi trafiği.",
  "giresun_gorele|Giresun Görele Devlet Hastanesi|Giresun|Görele|Devlet Hastanesi|72.2|71.7|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Trabzon sınırına yakın sahil ilçesi.|Sosyalleşme imkanları kısıtlı.",
  "giresun_tirebolu|Giresun Tirebolu Devlet Hastanesi|Giresun|Tirebolu|Devlet Hastanesi|71.9|71.4|5/10|6.000-8.500 TL|24 Saat Nöbet|8.500-12.000 TL|Şirin ve tarihi sahil kenti.|Küçük ilçe.",

  // GÜMÜŞHANE (2)
  "gumushane_devlet|Gümüşhane Devlet Hastanesi|Gümüşhane|Merkez|Devlet Hastanesi|71.2|70.7|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Yeni tünellerle Trabzon'a 45 dk mesafede.|Dağların arasında kapalı bir coğrafya.",
  "gumushane_kelkit|Gümüşhane Kelkit Devlet Hastanesi|Gümüşhane|Kelkit|Devlet Hastanesi|70.5|70.0|4/10|5.000-7.500 TL|24 Saat Nöbet|7.500-10.500 TL|Düzenli bir ilçe.|Erzincan'a daha yakın.",

  // HAKKARİ (2)
  "hakkari_devlet|Hakkari Devlet Hastanesi|Hakkari|Merkez|Devlet Hastanesi|67.9|67.4|5/10|8.000-12.000 TL|24 Saat Nöbet|8.000-12.000 TL|En yüksek hizmet puanı avantajı.|Ulaşım ve sosyal mahrumiyet çok yüksek.",
  "hakkari_yuksekova|Hakkari Yüksekova Devlet Hastanesi|Hakkari|Yüksekova|Devlet Hastanesi|67.5|67.0|6/10|8.500-12.500 TL|24 Saat Nöbet|8.000-11.000 TL|Havalimanı var.|Kışlar çok çetin geçer.",

  // HATAY (4)
  "hatay_dortyol|Hatay Dörtyol Devlet Hastanesi|Hatay|Dörtyol|Devlet Hastanesi|71.8|71.3|6/10|7.000-10.000 TL|24 Saat Nöbet|10.000-14.000 TL|Denize kıyısı olan güzel bir ilçe.|Sanayi bölgesi olduğu için hava kirliliği mevcut.",
  "hatay_iskenderun|Hatay İskenderun Devlet Hastanesi|Hatay|İskenderun|Devlet Hastanesi|72.4|71.9|7/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Hatay'ın en gelişmiş, modern ilçesi.|Trafik ve sıcak hava yorucu olabilir.",
  "hatay_kirikhan|Hatay Kırıkhan Devlet Hastanesi|Hatay|Kırıkhan|Devlet Hastanesi|71.2|70.7|5/10|6.500-9.500 TL|24 Saat Nöbet|9.000-13.000 TL|Suriye sınırına yakın.|Yazın aşırı sıcak.",
  "hatay_reyhanli|Hatay Reyhanlı Devlet Hastanesi|Hatay|Reyhanlı|Devlet Hastanesi|70.9|70.4|5/10|6.000-9.000 TL|24 Saat Nöbet|8.000-12.000 TL|Amik ovasında.|Mülteci yoğunluğu.",

  // IĞDIR (1)
  "igdir_devlet|Iğdır Dr. Nevruz Erez Devlet Hastanesi|Iğdır|Merkez|Devlet Hastanesi|68.9|68.4|6/10|7.000-10.000 TL|24 Saat Nöbet|9.000-13.000 TL|Mikroklima iklimli ılıman doğu kenti.|Hava kirliliği kışın çok rahatsız edici boyutta.",

  // ISPARTA (3)
  "isparta_sehir|Isparta Şehir Hastanesi|Isparta|Merkez|Şehir Hastanesi|74.1|73.6|7/10|10.000-13.000 TL|24 Saat Nöbet|12.000-17.000 TL|Sakin, güvenli ve düzenli şehir.|Şehir hastanesi sirkülasyonu bazen yorabiliyor.",
  "isparta_yalvac|Isparta Yalvaç Devlet Hastanesi|Isparta|Yalvaç|Devlet Hastanesi|73.0|72.5|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Tarihi ve büyük ilçe.|Merkeze 1.5 saat mesafede.",
  "isparta_egirdir|Isparta Eğirdir Devlet Hastanesi|Isparta|Eğirdir|Devlet Hastanesi|73.4|72.9|5/10|6.000-8.500 TL|24 Saat Nöbet|10.000-14.000 TL|Göl kenarı, muazzam doğa.|Kışın çok sessiz.",

  // İSTANBUL (5 - En çok bilinenler)
  "istanbul_cam_sakura|Başakşehir Çam ve Sakura Şehir H.|İstanbul|Başakşehir|Şehir Hastanesi|69.3|68.9|10/10|12.000-15.000 TL|24 Saat Nöbet|25.000-35.000 TL|Kağıtsız hastane, metroyla içine kadar ulaşım.|İstanbul pahalılığı ve aşırı kalabalık yoğunluk.",
  "istanbul_sadi_konuk|Bakırköy Dr. Sadi Konuk EAH|İstanbul|Bakırköy|Eğitim ve Araştırma|69.6|69.0|9/10|11.000-14.000 TL|24 Saat Nöbet|25.000-35.000 TL|Metrobüs dibinde, merkezi klinik.|Eski ve çok yoğun bir kurum.",
  "istanbul_ilhan_varank|Sancaktepe Prof. Dr. İlhan Varank EAH|İstanbul|Sancaktepe|Eğitim ve Araştırma|69.1|68.6|9/10|10.000-13.000 TL|24 Saat Nöbet|22.000-30.000 TL|Anadolu yakasının parlayan yıldızı.|Sancaktepe bölgesinin genel kalabalığı.",
  "istanbul_okmeydani|Prof. Dr. Cemil Taşcıoğlu Şehir H.|İstanbul|Şişli|Şehir Hastanesi|69.4|68.8|10/10|11.500-14.500 TL|24 Saat Nöbet|25.000-40.000 TL|Şehrin kalbinde yeni ve çok teknolojik tesis.|Avrupa yakası trafiği ve inanılmaz iş yükü.",
  "istanbul_kartal_lutfi_kirdar|Kartal Dr. Lütfi Kırdar Şehir H.|İstanbul|Kartal|Şehir Hastanesi|69.5|69.0|9/10|11.000-14.000 TL|24 Saat Nöbet|23.000-32.000 TL|Anadolu yakasının en köklü sağlık üssü.|Çok geniş bir nüfusa hitap ediyor.",

  // İZMİR (6)
  "izmir_sehir|İzmir Şehir Hastanesi|İzmir|Bayraklı|Şehir Hastanesi|75.5|75.0|9/10|11.000-15.000 TL|24 Saat Nöbet|20.000-28.000 TL|Ege'nin en prestijli yapısı, manzarası var.|Tepede yer alıyor, ulaşım ve organizasyon yorucu.",
  "izmir_bozyaka|İzmir Bozyaka EAH|İzmir|Karabağlar|Eğitim ve Araştırma|75.1|74.6|8/10|10.000-13.000 TL|24 Saat Nöbet|18.000-25.000 TL|Vaka tecrübesi için çok ideal.|Bina oldukça eski ve yenilenme sürecinde.",
  "izmir_katip_celebi|İzmir Katip Çelebi Üniv. Atatürk EAH|İzmir|Karabağlar|Eğitim ve Araştırma|75.3|74.8|8/10|10.500-13.500 TL|24 Saat Nöbet|19.000-26.000 TL|İzmir'in en köklü ve tercih edilen kurumlarından.|Otopark ve poliklinik yoğunluğu.",
  "izmir_buca|İzmir Buca Seyfi Demirsoy EAH|İzmir|Buca|Eğitim ve Araştırma|74.9|74.4|8/10|9.500-12.500 TL|24 Saat Nöbet|16.000-23.000 TL|Yeni yapılan modern bina.|Buca'nın öğrenci ve trafik yoğunluğu.",
  "izmir_odemis|İzmir Ödemiş Devlet Hastanesi|İzmir|Ödemiş|Devlet Hastanesi|74.5|74.0|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Tarihi ve şirin Ege ilçesi.|İzmir merkeze 2 saat mesafede.",
  "izmir_bergama|İzmir Bergama Necla-Mithat Öztüre DH|İzmir|Bergama|Devlet Hastanesi|74.3|73.8|6/10|7.500-10.500 TL|24 Saat Nöbet|11.000-15.000 TL|Kuzeyde sakin ve antik kent.|Merkeze uzak.",

  // KAHRAMANMARAŞ (4)
  "maras_necil|Kahramanmaraş Necip Fazıl Şehir Hastanesi|Kahramanmaraş|Dulkadiroğlu|Şehir Hastanesi|72.3|71.8|7/10|9.000-12.000 TL|24 Saat Nöbet|12.000-16.000 TL|Düzenli işleyiş.|Deprem sonrası toparlanma süreci.",
  "maras_elbistan|Kahramanmaraş Elbistan Devlet Hastanesi|Kahramanmaraş|Elbistan|Devlet Hastanesi|71.5|71.0|6/10|8.000-11.000 TL|24 Saat Nöbet|9.000-13.000 TL|Büyük ve gelişmiş ilçe.|Kışları oldukça sert geçer.",
  "maras_afsin|Kahramanmaraş Afşin Devlet Hastanesi|Kahramanmaraş|Afşin|Devlet Hastanesi|71.1|70.6|5/10|7.000-10.000 TL|24 Saat Nöbet|8.000-12.000 TL|Santrallere yakın.|Hava kirliliği sorunu.",
  "maras_pazarcik|Kahramanmaraş Pazarcık Devlet Hastanesi|Kahramanmaraş|Pazarcık|Devlet Hastanesi|70.8|70.3|5/10|6.500-9.000 TL|24 Saat Nöbet|8.000-11.000 TL|Gaziantep'e yakın konum.|Küçük.",

  // KARABÜK (2)
  "karabuk_eah|Karabük Eğitim ve Araştırma Hastanesi|Karabük|Merkez|Eğitim ve Araştırma|73.1|72.6|7/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Üniversite kenti, dinamik genç nüfus.|Demir çelik fabrikası kaynaklı ağır sanayi havası.",
  "karabuk_safranbolu|Karabük Safranbolu Devlet Hastanesi|Karabük|Safranbolu|Devlet Hastanesi|72.8|72.3|5/10|6.500-9.000 TL|24 Saat Nöbet|12.000-16.000 TL|Dünya mirası turistik kent.|Merkez hastanenin gölgesinde kalır.",

  // KARAMAN (2)
  "karaman_eah|Karaman Eğitim ve Araştırma Hastanesi|Karaman|Merkez|Eğitim ve Araştırma|72.6|72.1|6/10|8.000-11.000 TL|24 Saat Nöbet|10.000-14.000 TL|Hızlı trenle Konya'ya yarım saat.|Sanayisi gelişmemiş, sessiz bir il.",
  "karaman_ermenek|Karaman Ermenek Devlet Hastanesi|Karaman|Ermenek|Devlet Hastanesi|71.5|71.0|4/10|5.000-7.500 TL|24 Saat Nöbet|7.000-10.000 TL|Toroslar'da doğa harikası.|Yolları çok virajlı ve merkeze çok uzak.",

  // KARS (3)
  "kars_harakani|Kars Harakani Devlet Hastanesi|Kars|Merkez|Devlet Hastanesi|69.4|68.9|6/10|8.000-11.000 TL|24 Saat Nöbet|10.000-14.000 TL|Doğu ekspresi ile turistik ve tarihi yapı.|İklim çok sert.",
  "kars_sarikamis|Kars Sarıkamış Devlet Hastanesi|Kars|Sarıkamış|Devlet Hastanesi|68.8|68.3|5/10|6.500-9.000 TL|24 Saat Nöbet|8.000-12.000 TL|Kayak merkezi ve çam ormanları.|Kışın dondurucu soğuklar.",
  "kars_kagizman|Kars Kağızman Devlet Hastanesi|Kars|Kağızman|Devlet Hastanesi|68.5|68.0|5/10|6.000-8.500 TL|24 Saat Nöbet|7.500-11.000 TL|Meyve bahçeleriyle ılıman mikroklima.|Merkeze 1 saat.",

  // KASTAMONU (4)
  "kastamonu_eah|Kastamonu Eğitim ve Araştırma Hastanesi|Kastamonu|Merkez|Eğitim ve Araştırma|72.7|72.2|7/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Ormanlık, bol yeşilli ve ferah bir il.|Ankara'ya gitmek kışın zorlayıcı olabilir.",
  "kastamonu_tosya|Kastamonu Tosya Devlet Hastanesi|Kastamonu|Tosya|Devlet Hastanesi|72.1|71.6|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|İstanbul yolu üzerinde gelişmiş ilçe.|Merkeze nispeten uzak.",
  "kastamonu_taskopru|Kastamonu Taşköprü Devlet Hastanesi|Kastamonu|Taşköprü|Devlet Hastanesi|71.8|71.3|5/10|5.500-8.000 TL|24 Saat Nöbet|8.500-12.000 TL|Sarımsağı meşhur şirin ilçe.|Sosyal imkanlar kısıtlı.",
  "kastamonu_inebolu|Kastamonu İnebolu Devlet Hastanesi|Kastamonu|İnebolu|Devlet Hastanesi|71.5|71.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Deniz kenarında tarihi ilçe.|Dağları aşarak gidildiği için ulaşım yorucu.",

  // KAYSERİ (4)
  "kayseri_sehir|Kayseri Şehir Hastanesi|Kayseri|Kocasinan|Şehir Hastanesi|74.1|73.6|7/10|10.000-13.500 TL|24 Saat Nöbet|12.000-18.000 TL|Tramvay tam önünden geçer.|Sanayi şehri olması hasebiyle sanayi kazaları çok görülür.",
  "kayseri_develi|Kayseri Develi Devlet Hastanesi|Kayseri|Develi|Devlet Hastanesi|73.5|73.0|5/10|7.000-10.000 TL|24 Saat Nöbet|10.000-14.000 TL|Erciyes'in eteklerinde büyük ilçe.|Dağ yolu kışın kapanabilir.",
  "kayseri_yahyali|Kayseri Yahyalı Devlet Hastanesi|Kayseri|Yahyalı|Devlet Hastanesi|72.8|72.3|4/10|6.000-8.500 TL|24 Saat Nöbet|8.500-12.000 TL|Şelaleleriyle ünlü.|Uzak.",
  "kayseri_pinarbasi|Kayseri Pınarbaşı Devlet Hastanesi|Kayseri|Pınarbaşı|Devlet Hastanesi|72.5|72.0|4/10|5.500-8.000 TL|24 Saat Nöbet|8.000-11.000 TL|Kavşak noktasında.|Çok küçük.",

  // KIRIKKALE (1)
  "kirikkale_ihtisas|Kırıkkale Yüksek İhtisas Hastanesi|Kırıkkale|Merkez|Devlet Hastanesi|72.8|72.3|6/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Ankara'ya git gel yapılabilir.|Şehrin kendi içindeki imkanlar dar.",

  // KIRKLARELİ (3)
  "kirklareli_eah|Kırklareli Eğitim ve Araştırma Hastanesi|Kırklareli|Merkez|Eğitim ve Araştırma|73.4|72.9|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-17.000 TL|Trakya'da çok medeni, huzurlu ve sakin yaşam.|Hareketli yaşam sevenler için fazla sakin.",
  "kirklareli_luleburgaz|Kırklareli Lüleburgaz Devlet Hastanesi|Kırklareli|Lüleburgaz|Devlet Hastanesi|73.1|72.6|6/10|8.000-11.000 TL|24 Saat Nöbet|13.000-18.000 TL|İl merkezinden daha gelişmiş, Edirne-İstanbul ortasında.|Sanayi yoğunluğu.",
  "kirklareli_babaeski|Kırklareli Babaeski Devlet Hastanesi|Kırklareli|Babaeski|Devlet Hastanesi|72.5|72.0|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Sakin ve şirin ilçe.|Ufak yerleşim.",

  // KIRŞEHİR (2)
  "kirsehir_eah|Kırşehir Eğitim ve Araştırma Hastanesi|Kırşehir|Merkez|Eğitim ve Araştırma|72.7|72.2|6/10|8.000-11.000 TL|24 Saat Nöbet|10.000-14.000 TL|Anadolu'nun şirin, eğitim düzeyi yüksek ili.|Küçük şehir sıkıntısı çekilebilir.",
  "kirsehir_kaman|Kırşehir Kaman Devlet Hastanesi|Kırşehir|Kaman|Devlet Hastanesi|71.8|71.3|4/10|5.500-8.000 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin ortam.|Sosyal yaşam yok.",

  // KİLİS (1)
  "kilis_alaeddin|Kilis Prof. Dr. Alaeddin Yavaşca DH|Kilis|Merkez|Devlet Hastanesi|71.3|70.8|6/10|7.000-10.000 TL|24 Saat Nöbet|9.000-13.000 TL|Gaziantep'e çok yakın yeni bina.|Mülteci hasta profili yoğun.",

  // KOCAELİ (5)
  "kocaeli_sehir|Kocaeli Şehir Hastanesi|Kocaeli|İzmit|Şehir Hastanesi|73.1|72.6|8/10|11.000-14.500 TL|24 Saat Nöbet|15.000-22.000 TL|İstanbul'a 1 saat mesafede sanayi merkezi.|Hava kirliliği ve yoğun sanayi temposu.",
  "kocaeli_derince|Kocaeli Derince Eğitim ve Araştırma Hastanesi|Kocaeli|Derince|Eğitim ve Araştırma|72.8|72.3|7/10|10.000-13.500 TL|24 Saat Nöbet|14.000-20.000 TL|Köklü kurum.|Şehir hastanesi açılınca kadro biraz bölündü.",
  "kocaeli_gebze|Kocaeli Gebze Fatih Devlet Hastanesi|Kocaeli|Gebze|Devlet Hastanesi|72.9|72.4|8/10|10.500-14.000 TL|24 Saat Nöbet|16.000-23.000 TL|İstanbul sınırında devasa sanayi ilçesi.|İl merkezinden daha kalabalık ve stresli.",
  "kocaeli_golcuk|Kocaeli Gölcük Necati Çelik DH|Kocaeli|Gölcük|Devlet Hastanesi|72.5|72.0|6/10|8.500-12.000 TL|24 Saat Nöbet|13.000-18.000 TL|Deniz kıyısı ve donanma kenti.|Dar bir alana sıkışmış yapı.",
  "kocaeli_darıca|Kocaeli Darıca Farabi EAH|Kocaeli|Darıca|Eğitim ve Araştırma|72.6|72.1|7/10|9.500-13.000 TL|24 Saat Nöbet|15.000-21.000 TL|İstanbul'a çok yakın.|Sanayi yoğun.",

  // KONYA (6)
  "konya_sehir|Konya Şehir Hastanesi|Konya|Karatay|Şehir Hastanesi|74.1|73.6|7/10|10.000-14.000 TL|24 Saat Nöbet|12.000-17.000 TL|Düzenli ulaşım ve tramvay ağı.|Kampüs dışı sosyal alanlar nispeten sınırlı.",
  "konya_numune|Konya Numune Hastanesi|Konya|Selçuklu|Devlet Hastanesi|73.8|73.3|6/10|8.000-11.000 TL|24 Saat Nöbet|13.000-18.000 TL|Tam şehrin kalbinde.|Trafik ve park sorunu kronik.",
  "konya_eregli|Konya Ereğli Devlet Hastanesi|Konya|Ereğli|Devlet Hastanesi|73.1|72.6|6/10|7.000-10.000 TL|24 Saat Nöbet|10.000-14.000 TL|İl statüsünde devasa bir ilçe.|Konya merkeze çok uzak (1.5 saat).",
  "konya_aksehir|Konya Akşehir Devlet Hastanesi|Konya|Akşehir|Devlet Hastanesi|72.8|72.3|5/10|6.500-9.500 TL|24 Saat Nöbet|9.000-13.000 TL|Nasreddin Hoca'nın memleketi, düzenli.|Merkeze uzak.",
  "konya_seydisehir|Konya Seydişehir Devlet Hastanesi|Konya|Seydişehir|Devlet Hastanesi|72.5|72.0|5/10|6.000-9.000 TL|24 Saat Nöbet|8.500-12.000 TL|Torosların eteğinde serin.|Antalya yolu üzerinde mola yeri gibi.",
  "konya_beysehir|Konya Beyşehir Devlet Hastanesi|Konya|Beyşehir|Devlet Hastanesi|72.6|72.1|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-12.500 TL|Göl manzaralı.|Kışın sert rüzgar alır.",

  // KÜTAHYA (3)
  "kutahya_sehir|Kütahya Şehir Hastanesi|Kütahya|Merkez|Şehir Hastanesi|73.4|72.9|7/10|10.000-13.000 TL|24 Saat Nöbet|12.000-16.000 TL|Eskişehir'e çok yakın, yeni hastane.|Kışın hava kalitesi düşük olabiliyor.",
  "kutahya_tavsanli|Kütahya Tavşanlı Doç. Dr. Mustafa Kalemli DH|Kütahya|Tavşanlı|Devlet Hastanesi|72.8|72.3|6/10|7.500-10.500 TL|24 Saat Nöbet|10.000-14.000 TL|Büyük sanayi ilçesi.|Hava kirliliği.",
  "kutahya_simav|Kütahya Simav Doç. Dr. İsmail Karakuyu DH|Kütahya|Simav|Devlet Hastanesi|72.2|71.7|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-12.000 TL|Termal tesisleriyle ünlü.|Kütahya merkeze uzak.",

  // MALATYA (3)
  "malatya_eah|Malatya Eğitim ve Araştırma Hastanesi|Malatya|Battalgazi|Eğitim ve Araştırma|71.6|71.1|7/10|9.000-12.000 TL|24 Saat Nöbet|11.000-15.000 TL|Personel dayanışması yüksektir.|Yoğun bölge hastanesi konumunda.",
  "malatya_dogansehir|Malatya Doğanşehir Devlet Hastanesi|Malatya|Doğanşehir|Devlet Hastanesi|70.8|70.3|5/10|6.000-9.000 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin.|Deprem bölgesinde.",
  "malatya_darende|Malatya Darende Hulusi Efendi DH|Malatya|Darende|Devlet Hastanesi|70.5|70.0|4/10|5.500-8.000 TL|24 Saat Nöbet|7.500-10.500 TL|Somuncu Baba türbesiyle huzurlu ilçe.|Kayseri-Malatya yolu üzerinde uzak ilçe.",

  // MANİSA (6)
  "manisa_sehir|Manisa Şehir Hastanesi|Manisa|Şehzadeler|Şehir Hastanesi|74.3|73.8|7/10|11.000-14.000 TL|24 Saat Nöbet|14.000-19.000 TL|İzmir'den gidiş geliş yapma imkanı.|Şehir hastanesi temposu.",
  "manisa_akhisar|Manisa Akhisar Mustafa Kirazoğlu DH|Manisa|Akhisar|Devlet Hastanesi|73.7|73.2|6/10|7.000-10.000 TL|24 Saat Nöbet|11.000-15.000 TL|Manisa'nın en gelişmiş ilçesi.|Eksik branş nöbetleri bazen zorlar.",
  "manisa_salihli|Manisa Salihli Devlet Hastanesi|Manisa|Salihli|Devlet Hastanesi|73.9|73.4|6/10|7.500-10.500 TL|24 Saat Nöbet|12.000-16.000 TL|İzmir yolu üzerinde güzel ilçe.|Tarım bölgesi.",
  "manisa_turgutlu|Manisa Turgutlu Devlet Hastanesi|Manisa|Turgutlu|Devlet Hastanesi|73.5|73.0|6/10|7.000-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|İzmir'e Manisa merkezden daha yakın.|Sanayi yoğunluğu.",
  "manisa_soma|Manisa Soma Devlet Hastanesi|Manisa|Soma|Devlet Hastanesi|72.8|72.3|6/10|7.500-10.500 TL|24 Saat Nöbet|10.000-14.000 TL|Tasarruf ilçesi.|Maden şehri, hava kirliliği.",
  "manisa_alasehir|Manisa Alaşehir Devlet Hastanesi|Manisa|Alaşehir|Devlet Hastanesi|72.5|72.0|5/10|6.500-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Üzüm diyarı.|Uzaklık.",

  // MARDİN (4)
  "mardin_eah|Mardin Eğitim ve Araştırma Hastanesi|Mardin|Artuklu|Eğitim ve Araştırma|70.2|69.7|7/10|9.000-12.000 TL|24 Saat Nöbet|11.000-16.000 TL|Muhteşem tarihi doku ve kültür.|Turistik bir yer olduğu için kira piyasası yüksek.",
  "mardin_kiziltepe|Mardin Kızıltepe Devlet Hastanesi|Mardin|Kızıltepe|Devlet Hastanesi|69.8|69.3|7/10|8.500-11.500 TL|24 Saat Nöbet|10.000-14.000 TL|İl merkezinden çok daha kalabalık ve büyük.|Aşırı yaz sıcakları.",
  "mardin_midyat|Mardin Midyat Devlet Hastanesi|Mardin|Midyat|Devlet Hastanesi|69.5|69.0|6/10|7.500-10.500 TL|24 Saat Nöbet|10.000-14.000 TL|Dizi setlerinin mekanı tarihi ilçe.|Sosyal imkanlar büyük illere göre sınırlı.",
  "mardin_nusaybin|Mardin Nusaybin Devlet Hastanesi|Mardin|Nusaybin|Devlet Hastanesi|69.1|68.6|5/10|7.000-10.000 TL|24 Saat Nöbet|8.000-12.000 TL|Düz ovada yer alır.|Sınır ilçesi hassasiyeti.",

  // MERSİN (5)
  "mersin_sehir|Mersin Şehir Hastanesi|Mersin|Toroslar|Şehir Hastanesi|74.4|73.9|7/10|10.000-13.000 TL|24 Saat Nöbet|14.000-20.000 TL|Modern yapı, denize yakınlık.|Yaz aylarında bunaltıcı nem.",
  "mersin_tarsus|Mersin Tarsus Devlet Hastanesi|Mersin|Tarsus|Devlet Hastanesi|73.8|73.3|7/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Tarihi ilçe, Adana ve Mersin'in tam ortasında.|Yeni bina geçiş süreci sorunları.",
  "mersin_erdemli|Mersin Erdemli Devlet Hastanesi|Mersin|Erdemli|Devlet Hastanesi|73.5|73.0|6/10|7.500-10.500 TL|24 Saat Nöbet|13.000-18.000 TL|Limon bahçeleri ve deniz.|Yazın trafik ve tatilci kalabalığı.",
  "mersin_silifke|Mersin Silifke Devlet Hastanesi|Mersin|Silifke|Devlet Hastanesi|73.2|72.7|6/10|7.000-10.000 TL|24 Saat Nöbet|12.000-17.000 TL|Tatil beldesi tadında sakinlik.|Kış aylarında oldukça sessiz.",
  "mersin_anamur|Mersin Anamur Devlet Hastanesi|Mersin|Anamur|Devlet Hastanesi|72.8|72.3|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Muz diyarı şirin ilçe.|Mersin merkeze 3-4 saat uzaklıkta (Çok virajlı yol).",

  // MUĞLA (6)
  "mugla_eah|Muğla Eğitim ve Araştırma Hastanesi|Muğla|Menteşe|Eğitim ve Araştırma|75.3|74.8|8/10|10.000-13.000 TL|24 Saat Nöbet|18.000-25.000 TL|Turizm kenti, prestijli üniversite hastanesi.|Muğla merkez deniz kenarında değil, kiralar uçuk.",
  "mugla_fethiye|Muğla Fethiye Devlet Hastanesi|Muğla|Fethiye|Devlet Hastanesi|74.8|74.3|7/10|8.000-11.000 TL|24 Saat Nöbet|20.000-30.000 TL|Doğa ve tatil cennetinde çalışmak.|Konut bulmak aşırı zor ve kiralar çok yüksek.",
  "mugla_marmaris|Muğla Marmaris Devlet Hastanesi|Muğla|Marmaris|Devlet Hastanesi|74.5|74.0|7/10|8.000-11.000 TL|24 Saat Nöbet|22.000-32.000 TL|Eşsiz deniz manzarası.|Yazın İngiliz turist yoğunluğu ve astronomik kiralar.",
  "mugla_bodrum|Muğla Bodrum Devlet Hastanesi|Muğla|Bodrum|Devlet Hastanesi|74.6|74.1|7/10|8.000-11.000 TL|24 Saat Nöbet|25.000-35.000 TL|Türkiye'nin en popüler tatil noktası.|Memur maaşıyla geçinmek imkansıza yakın.",
  "mugla_milas|Muğla Milas Devlet Hastanesi|Muğla|Milas|Devlet Hastanesi|74.0|73.5|6/10|7.500-10.500 TL|24 Saat Nöbet|15.000-22.000 TL|Havalimanı var, Bodrum'a yakın.|Yazları orman yangını riskleri.",
  "mugla_koycegiz|Muğla Köyceğiz Devlet Hastanesi|Muğla|Köyceğiz|Devlet Hastanesi|73.8|73.3|5/10|6.500-9.500 TL|24 Saat Nöbet|14.000-20.000 TL|Göl kenarı sakin (Cittaslow) ilçe.|Sivrisinek problemi.",

  // MUŞ (3)
  "mus_devlet|Muş Devlet Hastanesi|Muş|Merkez|Devlet Hastanesi|68.8|68.3|6/10|8.000-11.000 TL|24 Saat Nöbet|9.000-13.000 TL|Hizmet puanı avantajı ve hızlı birikim imkanı.|Kışları hayat durma noktasına gelir.",
  "mus_bulanik|Muş Bulanık Devlet Hastanesi|Muş|Bulanık|Devlet Hastanesi|67.9|67.4|5/10|6.500-9.500 TL|24 Saat Nöbet|7.500-10.500 TL|Muş'un en büyük ilçesi.|Sosyal olanak yok denecek kadar az.",
  "mus_malazgirt|Muş Malazgirt Devlet Hastanesi|Muş|Malazgirt|Devlet Hastanesi|67.5|67.0|4/10|5.500-8.000 TL|24 Saat Nöbet|7.000-10.000 TL|Tarihi doku.|Merkeze çok uzak.",

  // NEVŞEHİR (2)
  "nevsehir_devlet|Nevşehir Devlet Hastanesi|Nevşehir|Merkez|Devlet Hastanesi|73.5|73.0|6/10|8.000-11.000 TL|24 Saat Nöbet|11.000-16.000 TL|Kapadokya bölgesinde huzurlu yaşam.|Personel rotasyonu bazen hızlı olabiliyor.",
  "nevsehir_urgup|Nevşehir Ürgüp Devlet Hastanesi|Nevşehir|Ürgüp|Devlet Hastanesi|72.8|72.3|5/10|6.500-9.000 TL|24 Saat Nöbet|12.000-18.000 TL|Turizmin tam kalbi peri bacaları.|Kiralar Nevşehir merkeze göre yüksek.",

  // NİĞDE (2)
  "nigde_omer|Niğde Ömer Halisdemir EAH|Niğde|Merkez|Eğitim ve Araştırma|72.6|72.1|6/10|8.000-11.000 TL|24 Saat Nöbet|10.000-14.000 TL|Ucuz ve sakin tam bir öğrenci kenti.|Hastane işleyişinde akademik süreçler ağır basar.",
  "nigde_bor|Niğde Bor Devlet Hastanesi|Niğde|Bor|Devlet Hastanesi|71.9|71.4|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-12.000 TL|Merkeze çok yakın şirin ilçe.|Sosyal imkan sınırlı.",

  // ORDU (4)
  "ordu_eah|Ordu Eğitim ve Araştırma Hastanesi|Ordu|Altınordu|Eğitim ve Araştırma|73.6|73.1|7/10|8.000-12.000 TL|24 Saat Nöbet|13.000-18.000 TL|Karadeniz'in en modern sahil şeridi.|Hastane bölgenin ana yükünü çekiyor.",
  "ordu_fatsa|Ordu Fatsa Devlet Hastanesi|Ordu|Fatsa|Devlet Hastanesi|73.2|72.7|6/10|7.000-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|Deniz manzaralı şık ilçe.|Yaz aylarında fındık işçilerinden kaynaklı yoğunluk.",
  "ordu_unye|Ordu Ünye Devlet Hastanesi|Ordu|Ünye|Devlet Hastanesi|73.0|72.5|6/10|7.000-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|Fatsa ile birlikte Ordu'nun belkemiği.|Samsun'a yakın olmanın verdiği sevk trafiği.",
  "ordu_golkoy|Ordu Gölköy Devlet Hastanesi|Ordu|Gölköy|Devlet Hastanesi|72.1|71.6|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|İç kısımlarda yayla havası.|Sahile giden yollar virajlı.",

  // OSMANİYE (3)
  "osmaniye_devlet|Osmaniye Devlet Hastanesi|Osmaniye|Merkez|Devlet Hastanesi|72.9|72.4|6/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Sakin ve kendi halinde bir il.|Sosyal olanaklar dar.",
  "osmaniye_kadirli|Osmaniye Kadirli Devlet Hastanesi|Osmaniye|Kadirli|Devlet Hastanesi|72.3|71.8|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-13.000 TL|Ormanlarla kaplı turp diyarı.|Yazın aşırı nemli.",
  "osmaniye_duzici|Osmaniye Düziçi Devlet Hastanesi|Osmaniye|Düziçi|Devlet Hastanesi|71.8|71.3|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-12.000 TL|Amanos eteklerinde.|Küçük.",

  // RİZE (3)
  "rize_eah|Rize Eğitim ve Araştırma Hastanesi|Rize|Merkez|Eğitim ve Araştırma|72.8|72.3|7/10|8.000-11.000 TL|24 Saat Nöbet|12.000-17.000 TL|Doğa ve yayla hayatı muazzam.|Türkiye'nin en çok yağış alan ili.",
  "rize_cayeli|Rize Çayeli Devlet Hastanesi|Rize|Çayeli|Devlet Hastanesi|72.2|71.7|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Çayın başkenti, şirin sahil kenti.|Arazi yapısından dolayı yollar dik.",
  "rize_ardesen|Rize Ardeşen Devlet Hastanesi|Rize|Ardeşen|Devlet Hastanesi|71.9|71.4|5/10|6.000-8.500 TL|24 Saat Nöbet|10.000-14.000 TL|Ayder yaylası yol ayrımında.|Turizm nedeniyle yazlık kira artışları.",

  // SAKARYA (4)
  "sakarya_eah|Sakarya Eğitim ve Araştırma Hastanesi|Sakarya|Adapazarı|Eğitim ve Araştırma|73.2|72.7|7/10|9.000-12.000 TL|24 Saat Nöbet|14.000-20.000 TL|İstanbul ve Ankara'nın tam ortasında stratejik konum.|Deprem bölgesi psikolojisi ve dağınık yerleşim.",
  "sakarya_serdivan|Sakarya Serdivan Devlet Hastanesi|Sakarya|Serdivan|Devlet Hastanesi|73.6|73.1|6/10|8.000-11.000 TL|24 Saat Nöbet|15.000-22.000 TL|Sakarya'nın en nezih ve modern ilçesi.|Kiralar merkezden daha pahalı.",
  "sakarya_akyazi|Sakarya Akyazı Devlet Hastanesi|Sakarya|Akyazı|Devlet Hastanesi|72.8|72.3|5/10|7.000-9.500 TL|24 Saat Nöbet|12.000-16.000 TL|Termal tesisleri olan kaplıca ilçesi.|Sıradan bir Anadolu ilçesi.",
  "sakarya_hendek|Sakarya Hendek Devlet Hastanesi|Sakarya|Hendek|Devlet Hastanesi|72.5|72.0|5/10|6.500-9.000 TL|24 Saat Nöbet|11.000-15.000 TL|Düzce ile Sakarya arasında kavşak.|Ufak yerleşim.",

  // SİİRT (2)
  "siirt_eah|Siirt Eğitim ve Araştırma Hastanesi|Siirt|Merkez|Eğitim ve Araştırma|69.3|68.8|6/10|8.000-11.000 TL|24 Saat Nöbet|9.000-13.000 TL|Sakin, tasarruf yapmak için ideal şehir.|Sosyalleşme alanları sıfıra yakın.",
  "siirt_kurtalan|Siirt Kurtalan Devlet Hastanesi|Siirt|Kurtalan|Devlet Hastanesi|68.5|68.0|5/10|6.000-8.500 TL|24 Saat Nöbet|8.000-11.000 TL|Tren yolunun son durağı.|Dışarıdan gelen memur için uyum zor olabilir.",

  // SİVAS (4)
  "sivas_numune|Sivas Numune Hastanesi|Sivas|Merkez|Devlet Hastanesi|73.1|72.6|6/10|8.000-11.000 TL|24 Saat Nöbet|11.000-15.000 TL|Hızlı trenle Ankara bağlantısı, düzenli şehir.|Kışları Türkiye'nin en soğuk illerinden biri.",
  "sivas_suhriye|Sivas Cumhuriyet Üniv. Tıp Fak.|Sivas|Merkez|Üniversite Hastanesi|72.5|72.0|7/10|8.500-12.000 TL|24 Saat Nöbet|11.000-15.000 TL|Büyük kampüs, vaka çeşitliliği.|Üniversite hastanesi yoğunluğu ve bürokrasisi.",
  "sivas_sarkisla|Sivas Şarkışla Devlet Hastanesi|Sivas|Şarkışla|Devlet Hastanesi|72.0|71.5|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|Kayseri yolunda, Aşık Veysel'in memleketi.|Aktivite yok.",
  "sivas_zara|Sivas Zara Devlet Hastanesi|Sivas|Zara|Devlet Hastanesi|71.6|71.1|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Sakin ilçe.|Erzincan sınırında, ulaşım uzun.",

  // ŞANLIURFA (5)
  "sanliurfa_eah|Şanlıurfa Eğitim ve Araştırma Hastanesi|Şanlıurfa|Eyyübiye|Eğitim ve Araştırma|69.8|69.3|8/10|9.000-13.000 TL|24 Saat Nöbet|10.000-15.000 TL|Puan ve klinik tecrübesi yüksek.|Doğum klinikleri Türkiye'nin en yoğunudur.",
  "sanliurfa_mehmet_akif|Şanlıurfa Mehmet Akif İnan EAH|Şanlıurfa|Haliliye|Eğitim ve Araştırma|70.2|69.7|8/10|9.500-13.500 TL|24 Saat Nöbet|11.000-16.000 TL|Karaköprü ve Haliliye nezih yerleşimlerdir.|Aşırı sıcaklar ve nüfus yoğunluğu.",
  "sanliurfa_siverek|Şanlıurfa Siverek Devlet Hastanesi|Şanlıurfa|Siverek|Devlet Hastanesi|69.2|68.7|7/10|8.000-11.000 TL|24 Saat Nöbet|9.000-13.000 TL|İl statüsünde devasa ilçe.|Şanlıurfa ve Diyarbakır'ın tam ortasında, yoğun trafik.",
  "sanliurfa_viransehir|Şanlıurfa Viranşehir Devlet Hastanesi|Şanlıurfa|Viranşehir|Devlet Hastanesi|68.9|68.4|6/10|7.500-10.500 TL|24 Saat Nöbet|8.500-12.000 TL|Geniş tarım alanları.|Yazları kavurucu sıcak.",
  "sanliurfa_birecik|Şanlıurfa Birecik Devlet Hastanesi|Şanlıurfa|Birecik|Devlet Hastanesi|69.5|69.0|6/10|8.000-11.000 TL|24 Saat Nöbet|9.500-13.500 TL|Fırat nehri kenarında, Gaziantep'e çok yakın.|Nem oranı yüksek.",

  // ŞIRNAK (3)
  "sirnak_devlet|Şırnak Devlet Hastanesi|Şırnak|Merkez|Devlet Hastanesi|67.8|67.3|6/10|8.000-11.500 TL|24 Saat Nöbet|8.000-11.000 TL|Hizmet puanı tavan, birikim için çok uygun.|Sosyal yaşam yok denecek kadar az.",
  "sirnak_cizre|Şırnak Cizre Dr. Selahattin Cizrelioğlu DH|Şırnak|Cizre|Devlet Hastanesi|68.2|67.7|6/10|9.000-12.000 TL|24 Saat Nöbet|8.000-12.000 TL|İl merkezinden daha hareketli, havalimanı dibinde.|Aşırı sıcaklar ve toz fırtınaları.",
  "sirnak_silopi|Şırnak Silopi Devlet Hastanesi|Şırnak|Silopi|Devlet Hastanesi|68.0|67.5|5/10|8.000-11.000 TL|24 Saat Nöbet|7.500-10.500 TL|Habur sınır kapısında.|Güvenlik algısı nedeniyle stresli olabilir.",

  // TEKİRDAĞ (4)
  "tekirdag_sehir|Tekirdağ Dr. İsmail Fehmi Cumalıoğlu Şehir H.|Tekirdağ|Süleymanpaşa|Şehir Hastanesi|73.5|73.0|7/10|10.000-13.000 TL|24 Saat Nöbet|15.000-20.000 TL|Deniz kenarı harika kampüs.|Sert rüzgarları meşhurdur.",
  "tekirdag_corlu|Tekirdağ Çorlu Devlet Hastanesi|Tekirdağ|Çorlu|Devlet Hastanesi|72.9|72.4|7/10|8.000-11.000 TL|24 Saat Nöbet|13.000-18.000 TL|İl merkezinden büyük sanayi ilçesi.|Fabrikalardan dolayı iş kazası vakaları sık gelir.",
  "tekirdag_cerkezkoy|Tekirdağ Çerkezköy Devlet Hastanesi|Tekirdağ|Çerkezköy|Devlet Hastanesi|72.5|72.0|7/10|8.500-12.000 TL|24 Saat Nöbet|14.000-19.000 TL|İstanbul sınırında, tam bir fabrika kenti.|Hava ve çevre kirliliği.",
  "tekirdag_malkara|Tekirdağ Malkara Devlet Hastanesi|Tekirdağ|Malkara|Devlet Hastanesi|72.0|71.5|5/10|6.000-9.000 TL|24 Saat Nöbet|11.000-15.000 TL|Sakin, Yunanistan yolu üzerinde.|Aktivite az.",

  // TRABZON (4)
  "trabzon_kanuni|Trabzon Kanuni EAH|Trabzon|Yomra|Eğitim ve Araştırma|73.7|73.2|8/10|9.000-13.000 TL|24 Saat Nöbet|14.000-20.000 TL|Deniz manzaralı kampüs, tecrübeli kadro.|Doğu Karadeniz'in tüm ağır sevkleri buraya gelir.",
  "trabzon_akcaabat|Trabzon Akçaabat Haçkalı Baba DH|Trabzon|Akçaabat|Devlet Hastanesi|73.3|72.8|6/10|7.500-10.000 TL|24 Saat Nöbet|12.000-16.000 TL|Trabzon merkezden daha sakin.|Acili deniz kenarı trafik kazalarından etkilenir.",
  "trabzon_vakfikebir|Trabzon Vakfıkebir Devlet Hastanesi|Trabzon|Vakfıkebir|Devlet Hastanesi|72.9|72.4|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Giresun sınırına yakın.|Dar sahil şeridi.",
  "trabzon_of|Trabzon Of Devlet Hastanesi|Trabzon|Of|Devlet Hastanesi|72.6|72.1|5/10|6.000-8.500 TL|24 Saat Nöbet|10.000-13.000 TL|Rize sınırında.|Yayla turizmi yoğunluğu.",

  // TUNCELİ (2)
  "tunceli_devlet|Tunceli Devlet Hastanesi|Tunceli|Merkez|Devlet Hastanesi|70.8|70.3|5/10|7.000-10.000 TL|24 Saat Nöbet|10.000-14.000 TL|Türkiye'nin en güvenli ve doğası harika ili.|Hastane imkanları kısıtlı.",
  "tunceli_ovacik|Tunceli Ovacık İlçe Hastanesi|Tunceli|Ovacık|Entegre Hastane|69.9|69.4|3/10|4.000-6.000 TL|24 Saat Nöbet|8.000-11.000 TL|Munzur suyu kenarında doğa cenneti.|Kışın ulaşım çok zor, imkanlar sıfıra yakın.",

  // UŞAK (3)
  "usak_eah|Uşak Eğitim ve Araştırma Hastanesi|Uşak|Merkez|Eğitim ve Araştırma|73.8|73.3|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Sakin, düzenli ve yaşaması kolay Ege ili.|Büyük şehirlere kıyasla sosyal yaşam zayıf.",
  "usak_banaz|Uşak Banaz Devlet Hastanesi|Uşak|Banaz|Devlet Hastanesi|72.9|72.4|5/10|6.000-8.500 TL|24 Saat Nöbet|10.000-13.000 TL|Afyon yolu üzerinde.|Küçük.",
  "usak_esme|Uşak Eşme Devlet Hastanesi|Uşak|Eşme|Devlet Hastanesi|72.5|72.0|4/10|5.000-7.500 TL|24 Saat Nöbet|8.500-12.000 TL|Kilimiyle meşhur şirin yer.|Merkeze oldukça uzak.",

  // VAN (4)
  "van_eah|Van Eğitim ve Araştırma Hastanesi|Van|Edremit|Eğitim ve Araştırma|69.6|69.1|7/10|9.000-13.000 TL|24 Saat Nöbet|10.000-15.000 TL|Göl kenarında ferah kampüs, büyükşehir imkanları.|Kış şartları oldukça serttir.",
  "van_ercis|Van Erciş Devlet Hastanesi|Van|Erciş|Devlet Hastanesi|69.1|68.6|6/10|8.000-11.000 TL|24 Saat Nöbet|9.000-13.000 TL|Göl kenarında il statüsünde büyük ilçe.|Merkeze 1 saat mesafede.",
  "van_muradiye|Van Muradiye Devlet Hastanesi|Van|Muradiye|Devlet Hastanesi|68.5|68.0|5/10|6.500-9.000 TL|24 Saat Nöbet|8.000-11.000 TL|Şelalesiyle meşhur.|Sakin.",
  "van_ozalp|Van Özalp Devlet Hastanesi|Van|Özalp|Devlet Hastanesi|68.2|67.7|4/10|5.500-8.000 TL|24 Saat Nöbet|7.000-10.000 TL|İran sınırında.|Mahrumiyet bölgesi.",

  // YALOVA (2)
  "yalova_eah|Yalova Eğitim ve Araştırma Hastanesi|Yalova|Merkez|Eğitim ve Araştırma|73.9|73.4|7/10|9.000-13.000 TL|24 Saat Nöbet|15.000-22.000 TL|Marmara'da sayfiye yeri rahatlığı.|Yazlıkçıların gelmesiyle artan hasta yükü.",
  "yalova_cinarcik|Yalova Çınarcık Devlet Hastanesi|Yalova|Çınarcık|Devlet Hastanesi|73.2|72.7|5/10|7.000-10.000 TL|24 Saat Nöbet|14.000-20.000 TL|Deniz tatili bölgesi.|Kışın tamamen ıssız.",

  // YOZGAT (4)
  "yozgat_sehir|Yozgat Şehir Hastanesi|Yozgat|Merkez|Şehir Hastanesi|72.4|71.9|6/10|10.000-13.000 TL|24 Saat Nöbet|10.000-14.000 TL|Yeni, modern ve temiz bir hastane.|Sosyal imkanlar büyükşehirden gelenleri tatmin etmez.",
  "yozgat_sorgun|Yozgat Sorgun Devlet Hastanesi|Yozgat|Sorgun|Devlet Hastanesi|71.9|71.4|5/10|6.500-9.000 TL|24 Saat Nöbet|9.000-12.000 TL|Sivas yolu üzerinde gelişmiş ilçe.|Kışlar dondurucu.",
  "yozgat_yerkoy|Yozgat Yerköy Devlet Hastanesi|Yozgat|Yerköy|Devlet Hastanesi|71.5|71.0|5/10|6.000-8.500 TL|24 Saat Nöbet|8.500-11.500 TL|Ankara'ya giden tren hattı.|Sıradan.",
  "yozgat_bogazliyan|Yozgat Boğazlıyan Devlet Hastanesi|Yozgat|Boğazlıyan|Devlet Hastanesi|71.0|70.5|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-11.000 TL|Kayseri sınırında.|Çok küçük.",

  // ZONGULDAK (3)
  "zonguldak_ataturk|Zonguldak Atatürk Devlet Hastanesi|Zonguldak|Merkez|Devlet Hastanesi|73.2|72.7|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-17.000 TL|Tecrübeli kadrosuyla bilinen merkez.|Madenci bölgesi, solunum yolları vakaları çok fazladır.",
  "zonguldak_eregli|Zonguldak Ereğli Devlet Hastanesi|Zonguldak|Ereğli|Devlet Hastanesi|72.8|72.3|6/10|7.500-10.500 TL|24 Saat Nöbet|11.000-15.000 TL|Zonguldak merkezden daha gelişmiş ve düzenli ilçe.|Ağır sanayi yoğunluğu.",
  "zonguldak_caycuma|Zonguldak Çaycuma Devlet Hastanesi|Zonguldak|Çaycuma|Devlet Hastanesi|72.4|71.9|5/10|6.500-9.000 TL|24 Saat Nöbet|10.000-14.000 TL|Havalimanı var, sakin doğa.|Ufak bir yerleşim."
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
  List<String> _bundledAssets = []; 
  
  String _searchQuery = '';
  String _activeCity = 'Tümü';
  
  double _userScore = 72.0;
  late TextEditingController _scoreController;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(text: _userScore.toString());
    _parseData();
    _loadPrefs();
    _loadAssetListSilently();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  void _parseData() {
    for (var item in rawData) {
      try {
        final p = item.split('|');
        if (p.length >= 7) {
          final isDetailed = p.length > 7;
          _hospitals.add(Hospital(
            id: p[0], name: p[1], city: p[2], district: p[3], type: p[4],
            kpss2024: double.tryParse(p[5]) ?? 70.0, 
            kpss2025: double.tryParse(p[6]) ?? 70.0,
            workLoad: isDetailed ? p[7] : '7/10',
            incentive: isDetailed ? p[8] : '8.000 - 11.000 TL',
            shift: isDetailed ? p[9] : '24 Saat Nöbet',
            rentRange: isDetailed ? p[10] : '12.000 - 18.000 TL',
            pros: isDetailed && p.length > 11 ? p[11] : 'Kurumun genel işleyişi oturmuş durumda.',
            cons: isDetailed && p.length > 12 ? p[12] : 'Dönemsel personel eksikliği yaşanabilir.',
          ));
        }
      } catch (e) {
        debugPrint('Veri parse hatası: $item');
      }
    }
  }

  Future<void> _loadAssetListSilently() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      setState(() {
        _bundledAssets = manifestMap.keys.where((String key) => key.startsWith('assets/')).toList();
      });
    } catch (e) {
      debugPrint("Asset okuma atlandı: $e");
    }
  }

  String _normalizeString(String text) {
    return text.toLowerCase()
      .replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u')
      .replaceAll('ç', 'c').replaceAll('ş', 's').replaceAll('ğ', 'g')
      .replaceAll('hastanesi', '').replaceAll('eah', '').replaceAll('dh', '')
      .replaceAll(RegExp(r'[^a-z0-9]'), ''); 
  }

  String? _findMatchingAsset(Hospital h) {
    final normHospName = _normalizeString(h.name);
    final normHospCity = _normalizeString(h.city);

    final List<String> safeAssets = List<String>.from(_bundledAssets);

    for (String assetPath in safeAssets) {
      final parts = assetPath.split('/').last.split('.');
      if (parts.isEmpty) continue;
      
      final fileName = parts.first; 
      final normFileName = _normalizeString(fileName);

      if (normHospName.contains(normFileName) || normFileName.contains(normHospName)) {
        return assetPath;
      }
      if (normFileName.contains(normHospCity) && normHospName.contains(normFileName.replaceAll(normHospCity, ''))) {
        return assetPath;
      }
    }
    
    if (safeAssets.contains('assets/${h.id}.jpg')) return 'assets/${h.id}.jpg';
    if (safeAssets.contains('assets/${h.id}.jpeg')) return 'assets/${h.id}.jpeg';
    
    return null;
  }

  Widget _buildImageEngine(Hospital h) {
    final personalImage = _images[h.id]; 
    final bundledAsset = _findMatchingAsset(h); 

    if (personalImage != null && File(personalImage).existsSync()) {
      return Image.file(File(personalImage), fit: BoxFit.cover);
    } else if (bundledAsset != null) {
      return Image.asset(bundledAsset, fit: BoxFit.cover);
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apartment, color: Colors.white54, size: 40),
          SizedBox(height: 8),
          Text("GÖRSEL EKLENEBİLİR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))
        ],
      );
    }
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _favoriteIds = prefs.getStringList('favs') ?? [];
        final notesStr = prefs.getString('notes');
        if (notesStr != null) _notes = Map<String, String>.from(json.decode(notesStr));
        final imagesStr = prefs.getString('images');
        if (imagesStr != null) _images = Map<String, String>.from(json.decode(imagesStr));
        
        _userScore = prefs.getDouble('userScore') ?? 72.0;
        _scoreController.text = _userScore.toString();
      });
    } catch (e) {
      debugPrint('Prefs yükleme hatası: $e');
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favs', _favoriteIds);
    await prefs.setString('notes', json.encode(_notes));
    await prefs.setString('images', json.encode(_images));
    await prefs.setDouble('userScore', _userScore);
  }

  void _toggleFav(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) _favoriteIds.remove(id);
      else _favoriteIds.add(id);
    });
    _savePrefs();
  }

  Future<void> _pickImage(String id) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _images[id] = pickedFile.path);
        _savePrefs();
      }
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
    }
  }

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openMap(String name, String city) {
    final query = Uri.encodeComponent("$name $city");
    _launchURL(Uri.parse("https://www.google.com/maps/search/?api=1&query=$query"));
  }

  void _openSahibinden(String city, String district) {
    String format(String text) => text.toLowerCase().replaceAll(' ', '-').replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u').replaceAll('ç', 'c').replaceAll('ş', 's').replaceAll('ğ', 'g');
    _launchURL(Uri.parse("https://www.sahibinden.com/kiralik-daire/${format(city)}-${format(district)}"));
  }

  void _copyOSYMFormat() {
    String text = "ÖSYM TERCİH LİSTEM:\n\n";
    for (int i = 0; i < _favoriteIds.length; i++) {
      final idx = _hospitals.indexWhere((x) => x.id == _favoriteIds[i]);
      if (idx != -1) {
        final h = _hospitals[idx];
        text += "${i + 1}. TERCİH: ${h.name} (${h.city}/${h.district})\n";
      }
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tercih listeniz ÖSYM şablonunda kopyalandı!', style: TextStyle(fontWeight: FontWeight.bold))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hemşire Kariyer Asistanı', style: TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(hintText: 'Hastane veya İlçe Ara...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16), prefixIcon: const Icon(Icons.search, size: 20)),
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
                      SizedBox(width: 50, child: TextField(controller: _scoreController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: InputBorder.none), onChanged: (v) { setState(() => _userScore = double.tryParse(v) ?? 0.0); _savePrefs(); }))
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Hastaneler'),
          NavigationDestination(icon: Badge(label: Text('${_favoriteIds.length}'), child: const Icon(Icons.star)), label: 'Tercih Listem'),
          const NavigationDestination(icon: Icon(Icons.calculate), label: 'Maaş/Nöbet'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) return _buildAllList();
    if (_currentIndex == 1) return _buildFavList();
    return const CalculatorScreen();
  }

  Widget _buildAllList() {
    final cities = ['Tümü', ..._hospitals.map((h) => h.city).toSet().toList()..sort()];
    final filtered = _hospitals.where((h) {
      final mSearch = h.name.toLowerCase().contains(_searchQuery.toLowerCase()) || h.district.toLowerCase().contains(_searchQuery.toLowerCase());
      final mCity = _activeCity == 'Tümü' || h.city == _activeCity;
      return mSearch && mCity;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), child: Row(children: cities.map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(c), selected: _activeCity == c, onSelected: (val) { if(val) setState(() => _activeCity = c); }))).toList())),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: filtered.length, itemBuilder: (ctx, i) => _buildCard(filtered[i]))),
      ],
    );
  }

  Widget _buildFavList() {
    if (_favoriteIds.isEmpty) return const Center(child: Text("Listeniz Boş. Kalp ikonuna basarak hastane ekleyin.", style: TextStyle(color: Colors.grey)));
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(8), itemCount: _favoriteIds.length,
            onReorder: (oldI, newI) {
              if (newI > oldI) newI -= 1;
              setState(() { final item = _favoriteIds.removeAt(oldI); _favoriteIds.insert(newI, item); });
              _savePrefs();
            },
            itemBuilder: (ctx, i) {
              final idx = _hospitals.indexWhere((x) => x.id == _favoriteIds[i]);
              if (idx == -1) return const SizedBox.shrink();
              final h = _hospitals[idx];
              return Card(key: ValueKey(h.id), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF0D9488), child: Text('${i + 1}', style: const TextStyle(color: Colors.white))), title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text('${h.city} • Son Taban: ${h.kpss2025}'), trailing: const Icon(Icons.drag_handle), onTap: () => _showDetails(h)));
            },
          ),
        ),
        Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.copy), label: const Text("ÖSYM İçin Listeyi Kopyala"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, padding: const EdgeInsets.all(12)), onPressed: _copyOSYMFormat)))
      ],
    );
  }

  Widget _buildCard(Hospital h) {
    final isFav = _favoriteIds.contains(h.id);
    final diff = _userScore - h.kpss2025;
    Color badgeColor = diff >= 0 ? Colors.green : (diff >= -1.5 ? Colors.orange : Colors.red);
    String badgeText = diff >= 0 ? "Kesin Gelir" : (diff >= -1.5 ? "Sınırda" : "Zor / Gelmez");

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
                  child: _buildImageEngine(h),
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
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.map, size: 16), label: const Text("Haritada Gör", style: TextStyle(fontSize: 12)), onPressed: () => _openMap(h.name, h.city))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.home_work, size: 16), label: const Text("Ev Ara", style: TextStyle(fontSize: 12)), onPressed: () => _openSahibinden(h.city, h.district))),
                    ],
                  ),
                  const Divider(),
                  Row(children: [Expanded(child: _detailBox("İş Yükü", h.workLoad, Icons.trending_up)), const SizedBox(width: 8), Expanded(child: _detailBox("Teşvik", h.incentive, Icons.payments))]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: _detailBox("Nöbet", h.shift, Icons.schedule)), const SizedBox(width: 8), Expanded(child: _detailBox("Ev Kirası", h.rentRange, Icons.home))]),
                  const SizedBox(height: 16),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.business, size: 16, color: Colors.blueGrey), const SizedBox(width: 4), Text("Lojman Durumu: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)), Expanded(child: Text(h.lojmanDurumu, style: TextStyle(color: Colors.blueGrey.shade800)))]), const SizedBox(height: 6), Row(children: [const Icon(Icons.school, size: 16, color: Colors.blueGrey), const SizedBox(width: 4), Text("Eğitim Toleransı: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)), Expanded(child: Text(h.egitimToleransi, style: TextStyle(color: Colors.blueGrey.shade800)))])])),
                  const SizedBox(height: 16),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border(left: const BorderSide(color: Colors.green, width: 4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("🟢 Artıları", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)), const SizedBox(height: 4), Text(h.pros, style: TextStyle(color: Colors.green.shade900, fontSize: 13))])),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border(left: const BorderSide(color: Colors.red, width: 4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("🔴 Eksileri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)), const SizedBox(height: 4), Text(h.cons, style: TextStyle(color: Colors.red.shade900, fontSize: 13))])),
                  const SizedBox(height: 16),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: "Kişisel notunuz...", border: OutlineInputBorder()), maxLines: 2, onChanged: (v) { _notes[h.id] = v; _savePrefs(); }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_a_photo), label: const Text("Telefondan Şahsi Görsel Ekle"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                      onPressed: () async { await _pickImage(h.id); setModalState(() {}); setState(() {}); },
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

  Widget _detailBox(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Row(children: [Icon(icon, size: 14, color: Colors.grey.shade600), const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold))]), const SizedBox(height: 4), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))],
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  double _baseSalary = 45000;
  double _incentive = 11000;
  double _extraHours = 24;
  final double _hourlyRate = 160.0;

  @override
  Widget build(BuildContext context) {
    final extraPay = _extraHours * _hourlyRate;
    final totalPay = _baseSalary + _incentive + extraPay;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nöbet & Maaş Simülatörü", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("130 saatlik zorunlu mesainin üzerine tuttuğunuz ekstra nöbetlere göre o ay cebinize girecek tahmini net tutarı hesaplayın.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _inputRow("Taban Maaş (TL)", _baseSalary, (v) => setState(() => _baseSalary = v)),
          const SizedBox(height: 12),
          _inputRow("Ortalama Teşvik/Ek Ödeme (TL)", _incentive, (v) => setState(() => _incentive = v)),
          const SizedBox(height: 12),
          _inputRow("Fazla Mesai / Nöbet (Saat)", _extraHours, (v) => setState(() => _extraHours = v)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Nöbet Ücreti Getirisi:", style: TextStyle(color: Colors.white70)), Text("+${extraPay.toStringAsFixed(0)} TL", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                const Divider(color: Colors.white30, height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Toplam Tahmini Kazanç:", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text("${totalPay.toStringAsFixed(0)} TL", style: const TextStyle(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _inputRow(String label, double val, Function(double) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(width: 100, child: TextField(keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)), controller: TextEditingController(text: val.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: val.toStringAsFixed(0).length), onChanged: (v) => onChanged(double.tryParse(v) ?? 0))),
      ],
    );
  }
}
