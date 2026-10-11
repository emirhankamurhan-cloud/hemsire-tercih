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
  "adana_pozanti|Adana Pozantı Devlet Hastanesi|Adana|Pozantı|Devlet Hastanesi|71.8|71.3|5/10|5.500-8.000 TL|24 Saat Nöbet|8.500-12.000 TL|Toroslar'da serin hava.|Merkeze uzak.",
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
  "amasya_serefeddin|Amasya Sabuncuoğlu Şerefeddin EAH|Amasya|Merkez|Eğitim ve Araştırma|73.4|72.9|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-16.000 TL|Tarihi şehir, personel memnuniyeti iyi.|Çok spesifik vakal
