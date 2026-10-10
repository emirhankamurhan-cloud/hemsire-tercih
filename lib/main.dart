import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

// ---------------- MODEL ----------------
class Hospital {
  final String id;
  final String name;
  final String city;
  final String district;
  final String type;
  final String imageUrl;
  final double kpss2024;
  final double kpss2025;
  final String workLoad;
  final String incentive;
  final String shift;
  final String rentRange;
  final List<String> surveyReviews;
  final List<String> webReviews;

  Hospital({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.type,
    required this.imageUrl,
    required this.kpss2024,
    required this.kpss2025,
    required this.workLoad,
    required this.incentive,
    required this.shift,
    required this.rentRange,
    required this.surveyReviews,
    required this.webReviews,
  });
}

// ---------------- TÜRKİYE GENELİ KAPSAMLI VERİ HAVUZU ----------------
final List<Hospital> initialHospitals = [
  // --- SAMSUN & KARADENİZ ---
  Hospital(
    id: 'samsun_sehir',
    name: 'Samsun Şehir Hastanesi',
    city: 'Samsun',
    district: 'Canik',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.45,
    kpss2025: 82.90,
    workLoad: '8 / 10',
    incentive: '12.000 TL - 16.000 TL',
    shift: '08:00 - 08:00 (24 Saat) & 16-8',
    rentRange: '15.000 TL - 22.000 TL',
    surveyReviews: [
      'Bina ve tüm teknolojik altyapı sıfır ve son model. Geniş servisler ve dinlenme odaları mevcut.',
      'Sistem ilk açılış sürecinde oturmaya başladığı için birim transferleri yaşanabiliyor.'
    ],
    webReviews: [
      'Canik çevre yolunda; ekspres belediye otobüsleri ve servislerle ulaşım rahat.',
      'Atakum bölgesine kıyasla Canik ve İlkadım taraflarında ev kiraları daha makul seviyelerde.'
    ],
  ),
  Hospital(
    id: 'samsun_eah',
    name: 'Samsun Eğitim ve Araştırma Hastanesi',
    city: 'Samsun',
    district: 'İlkadım',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.10,
    kpss2025: 82.75,
    workLoad: '7 / 10',
    incentive: '8.000 TL - 12.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '14.000 TL - 20.000 TL',
    surveyReviews: [
      'Merkezi konumda, dolmuş ve belediye otobüsleri kapısına kadar gidiyor.',
      'Köklü bir hastane; hemşire ekipleri deneyimli ve nöbet dayanışması yüksek.'
    ],
    webReviews: [
      'Şehir hastanesine bazı branşların kaymasıyla aşırı hasta yükü azaldı, çalışma ortamı dengelendi.'
    ],
  ),
  Hospital(
    id: 'samsun_gazi',
    name: 'Samsun Gazi Devlet Hastanesi',
    city: 'Samsun',
    district: 'İlkadım',
    type: 'Devlet Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.30,
    kpss2025: 82.95,
    workLoad: '6 / 10',
    incentive: '7.000 TL - 10.000 TL',
    shift: '08:00 - 08:00 & 8-16',
    rentRange: '13.000 TL - 18.000 TL',
    surveyReviews: [
      'Şehrin göbeğinde. Ulaşım sorunu kesinlikle yok.',
      'İkinci basamak hastane; ağır travma vakaları EAH veya Şehir Hastanesine sevk ediliyor.'
    ],
    webReviews: [
      'Huzurlu, nöbet usulü düzenli, çalışan memnuniyeti ortalamanın üzerinde.'
    ],
  ),
  Hospital(
    id: 'tokat_resadiye',
    name: 'Tokat Reşadiye Devlet Hastanesi',
    city: 'Tokat',
    district: 'Reşadiye',
    type: 'Devlet Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.15,
    kpss2025: 81.80,
    workLoad: '4 / 10',
    incentive: '4.000 TL - 7.000 TL',
    shift: '24 Saat Nöbet & Blok İzin',
    rentRange: '8.000 TL - 12.000 TL',
    surveyReviews: [
      'Küçük ilçe hastanesi. İş yükü büyük şehirlere kıyasla gayet sakin ve stressiz.',
      'Blok nöbet sistemiyle memlekete gitmek için uzun süreli boşluklar alınabiliyor.'
    ],
    webReviews: [
      'Yaşam giderleri çok uygun. Sakinlik ve birikim arayanlar için biçilmiş kaftan.'
    ],
  ),
  Hospital(
    id: 'tokat_eah',
    name: 'Tokat Gaziosmanpaşa Üniversitesi & Devlet Hastanesi',
    city: 'Tokat',
    district: 'Merkez',
    type: 'Devlet / EAH',
    imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.20,
    kpss2025: 82.80,
    workLoad: '6 / 10',
    incentive: '7.500 TL - 11.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '10.000 TL - 15.000 TL',
    surveyReviews: [
      'Merkezde hayat ucuz ve rahat. Ulaşım masrafı neredeyse yok denecek kadar az.',
      'İdare genel olarak hemşirelerle uyumlu çalışıyor, mobbing şikayeti düşük.'
    ],
    webReviews: [
      'Tokat merkez hem aile hayatı hem de ekonomik rahatlık açısından hemşirelerin gözde yerlerinden biri.'
    ],
  ),
  Hospital(
    id: 'amasya_eah',
    name: 'Amasya Sabuncuoğlu Şerefeddin EAH',
    city: 'Amasya',
    district: 'Merkez',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.90,
    kpss2025: 82.40,
    workLoad: '7 / 10',
    incentive: '8.000 TL - 11.500 TL',
    shift: '08:00 - 08:00 & 16-8',
    rentRange: '12.000 TL - 17.000 TL',
    surveyReviews: [
      'İl merkezinin tek büyük hastanesi. Nüfusa göre yoğunluk kaldırılabilir düzeyde.',
      'Tarihi ve şirin bir şehir, yaşam masrafı makul.'
    ],
    webReviews: [
      'Samsun ve Tokat aksında yer alıyor, ulaşım ağı kolay.'
    ],
  ),
  Hospital(
    id: 'corum_eah',
    name: 'Çorum Erol Olçok EAH',
    city: 'Çorum',
    district: 'Merkez',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.60,
    kpss2025: 82.10,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 12.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '12.000 TL - 17.000 TL',
    surveyReviews: [
      'İlin en büyük hastanesi, çevre ilçelerden çok fazla vaka gelir.',
      'Ek mesai ücretleri ve teşvik düzenli yatar.'
    ],
    webReviews: [
      'Hayat pahalılığı düşük, İç Anadolu-Karadeniz geçişinde sakin bir şehir.'
    ],
  ),
  Hospital(
    id: 'trabzon_kanuni',
    name: 'Trabzon Kanuni EAH',
    city: 'Trabzon',
    district: 'Yomra',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.50,
    kpss2025: 83.05,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '15.000 TL - 22.000 TL',
    surveyReviews: [
      'Doğu Karadeniz’in sevk merkezi konumunda. Vaka çeşitliliği çok fazla.',
      'Kaşüstü yerleşkesi ferah ve modern.'
    ],
    webReviews: [
      'Deniz manzaralı kampüs, Yomra ve Kaşüstü bölgesinde sitelerde kiralık daireler mevcut.'
    ],
  ),
  Hospital(
    id: 'giresun_eah',
    name: 'Giresun Eğitim ve Araştırma Hastanesi',
    city: 'Giresun',
    district: 'Merkez',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.70,
    kpss2025: 82.20,
    workLoad: '8 / 10',
    incentive: '8.000 TL - 11.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '13.000 TL - 18.000 TL',
    surveyReviews: [
      'Deniz kenarında konumlanmış modern bina. İl genelinin yükünü sırtlar.',
      'Şehir güvenli, insanları sıcakkanlı.'
    ],
    webReviews: [
      'Karadeniz sahil yolunda yer alır, dolmuşlarla merkeze 10 dakika.'
    ],
  ),
  Hospital(
    id: 'ordu_eah',
    name: 'Ordu Eğitim ve Araştırma Hastanesi',
    city: 'Ordu',
    district: 'Altınordu',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.35,
    kpss2025: 82.90,
    workLoad: '8 / 10',
    incentive: '8.500 TL - 12.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '14.000 TL - 20.000 TL',
    surveyReviews: [
      'Altınordu merkezinde sahil kordonuna yakın, şehir hayatı çok canlı.',
      'Servislerde sirkülasyon var ancak ekip dayanışması yüksek.'
    ],
    webReviews: [
      'Yeni şehir hastanesi projesi de sürdüğü için sağlık altyapısı hızla gelişen bir il.'
    ],
  ),

  // --- ANKARA & İÇ ANADOLU ---
  Hospital(
    id: 'ankara_bilkent',
    name: 'Ankara Bilkent Şehir Hastanesi',
    city: 'Ankara',
    district: 'Çankaya',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 84.10,
    kpss2025: 83.60,
    workLoad: '9 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 & 16-8',
    rentRange: '25.000 TL - 35.000 TL',
    surveyReviews: [
      'Devasa bir sağlık kenti. Her türlü ileri seviye cerrahi ve yoğun bakım vakası gelir.',
      'Sistem işi ve evrak prosedürleri titizlikle denetlenir.'
    ],
    webReviews: [
      'Metroya direkt ring otobüsleri var. Genç sağlık personeli nüfusu çok yoğun.'
    ],
  ),
  Hospital(
    id: 'ankara_etlik',
    name: 'Ankara Etlik Şehir Hastanesi',
    city: 'Ankara',
    district: 'Keçiören',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.80,
    kpss2025: 83.25,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '20.000 TL - 28.000 TL',
    surveyReviews: [
      'Bina yeni ve ferah. Malzeme sıkıntısı yaşanmıyor.',
      'Keçiören ve Yenimahalle aksında ev bulma şansı yüksek.'
    ],
    webReviews: [
      'Teşvik ödemeleri düzenli, acil serviste mentör-mentee oryantasyon sistemi uygulanıyor.'
    ],
  ),
  Hospital(
    id: 'ankara_gulhane',
    name: 'Ankara Gülhane EAH (GATA)',
    city: 'Ankara',
    district: 'Keçiören',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.95,
    kpss2025: 83.40,
    workLoad: '7 / 10',
    incentive: '9.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 & 16-8',
    rentRange: '20.000 TL - 26.000 TL',
    surveyReviews: [
      'Geniş ormanlık kampüsü var. Kurumsal kültürü ve disiplini çok köklü.',
      'Şehir hastanelerine göre daha kompakt ve derli toplu bir düzen var.'
    ],
    webReviews: [
      'Etlik ve Keçiören metro/otobüs hatlarının kesişim noktasında.'
    ],
  ),
  Hospital(
    id: 'eskisehir_sehir',
    name: 'Eskişehir Şehir Hastanesi',
    city: 'Eskişehir',
    district: 'Odunpazarı',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.70,
    kpss2025: 83.10,
    workLoad: '7 / 10',
    incentive: '8.000 TL - 11.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '14.000 TL - 20.000 TL',
    surveyReviews: [
      'Tramvay hattı hastanenin kapısına kadar geliyor. Şehir içi ulaşım mükemmel.',
      'Eskişehir sosyal imkanlar ve genç yaşamı açısından Türkiye’nin en keyifli illerinden.'
    ],
    webReviews: [
      'Şehir hastaneleri arasında hemşire memnuniyeti en yüksek kurumlardan biri.'
    ],
  ),
  Hospital(
    id: 'kayseri_sehir',
    name: 'Kayseri Şehir Hastanesi',
    city: 'Kayseri',
    district: 'Kocasinan',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.10,
    kpss2025: 82.60,
    workLoad: '8 / 10',
    incentive: '10.000 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '13.000 TL - 19.000 TL',
    surveyReviews: [
      'Kampüs geniş ve teknolojik altyapısı çok kuvvetli.',
      'Tramvay bağlantısı var, şehir merkezine ulaşım konforlu.'
    ],
    webReviews: [
      'İç Anadolu’nun sanayi ve ticaret merkezinde, yaşam masrafları dengeli.'
    ],
  ),
  Hospital(
    id: 'konya_sehir',
    name: 'Konya Şehir Hastanesi',
    city: 'Konya',
    district: 'Karatay',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.25,
    kpss2025: 82.75,
    workLoad: '8 / 10',
    incentive: '10.000 TL - 14.500 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '13.000 TL - 18.000 TL',
    surveyReviews: [
      'Geniş poliklinik ve yatak kapasitesi var. Çevre ilçelerden sevk yoğundur.',
      'Tramvay ve otobüs hatlarıyla entegre ulaşım.'
    ],
    webReviews: [
      'Geniş ve düzenli şehir planı, uygun ev kiraları sunar.'
    ],
  ),

  // --- İSTANBUL & MARMARA ---
  Hospital(
    id: 'basaksehir_cam_sakura',
    name: 'Başakşehir Çam ve Sakura Şehir Hastanesi',
    city: 'İstanbul',
    district: 'Başakşehir',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&w=800&q=80',
    kpss2024: 80.50,
    kpss2025: 79.90,
    workLoad: '10 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 & 8-16/16-08',
    rentRange: '25.000 TL - 32.000 TL',
    surveyReviews: [
      'Kağıtsız hastane; tüm ilaçlar hasta bileklik barkoduyla eşleştirilerek uygulanıyor.',
      'İş temposu yüksek fakat metro istasyonu doğrudan hastanenin altına çıkıyor.'
    ],
    webReviews: [
      'Kısa sürede üst düzey klinik ve cerrahi deneyim kazandırır. Teşvikler yüksektir.'
    ],
  ),
  Hospital(
    id: 'istanbul_bagcilar',
    name: 'Bağcılar Eğitim ve Araştırma Hastanesi',
    city: 'İstanbul',
    district: 'Bağcılar',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 79.80,
    kpss2025: 79.20,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 12.000 TL',
    shift: '08:00 - 08:00 & 16-8',
    rentRange: '18.000 TL - 24.000 TL',
    surveyReviews: [
      'Metro ve tramvay bağlantısı çok rahat. Vaka yoğunluğu yüksek.',
      'Nöbet sayıları adil dağıtılıyor.'
    ],
    webReviews: [
      'İstanbul içi merkezi ulaşımı olan ve teşvikleri stabil yatan kurumlardan biri.'
    ],
  ),
  Hospital(
    id: 'istanbul_sadi_konuk',
    name: 'Bakırköy Dr. Sadi Konuk EAH',
    city: 'İstanbul',
    district: 'Bakırköy',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 81.10,
    kpss2025: 80.60,
    workLoad: '9 / 10',
    incentive: '9.500 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '25.000 TL - 35.000 TL',
    surveyReviews: [
      'E-5 karayolunun bitişiğinde, metrobüs ve metro durağına yürüme mesafesinde.',
      'İstanbul’un en köklü ve en yoğun acillerinden biri.'
    ],
    webReviews: [
      'Lokasyon avantajı çok yüksek, çevre semtlerde sosyal imkanlar sınırsız.'
    ],
  ),
  Hospital(
    id: 'bursa_sehir',
    name: 'Bursa Şehir Hastanesi',
    city: 'Bursa',
    district: 'Nilüfer',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.15,
    kpss2025: 82.60,
    workLoad: '7 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '16.000 TL - 22.000 TL',
    surveyReviews: [
      'Yemekhane ve yardımcı personel hizmetleri şirket eliyle düzenli yürütülüyor.',
      'Bölge hastanesi olduğu için yoğunluk var ancak nöbetler sonrası 3-4 gün blok izin alınabiliyor.'
    ],
    webReviews: [
      'Nilüfer ilçesi sosyal imkanları ve genç nüfusuyla yaşam kalitesi açısından çok avantajlı.'
    ],
  ),
  Hospital(
    id: 'kocaeli_sehir',
    name: 'Kocaeli Şehir Hastanesi',
    city: 'Kocaeli',
    district: 'İzmit',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.80,
    kpss2025: 82.30,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 14.500 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '16.000 TL - 22.000 TL',
    surveyReviews: [
      'Tramvay hattı hastaneye kadar uzatıldı, ulaşım çok rahatladı.',
      'Bölgenin sanayi ve trafik kazaları dahil en büyük travma merkezi.'
    ],
    webReviews: [
      'İstanbul’a 1 saat mesafede, hayat Marmara standartlarına göre daha ekonomik.'
    ],
  ),

  // --- EGE & AKDENİZ ---
  Hospital(
    id: 'izmir_sehir',
    name: 'İzmir Şehir Hastanesi',
    city: 'İzmir',
    district: 'Bayraklı',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.90,
    kpss2025: 83.40,
    workLoad: '8 / 10',
    incentive: '12.000 TL - 16.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '22.000 TL - 30.000 TL',
    surveyReviews: [
      'Ege Bölgesi’nin en büyük kompleksi. Bina manzarası ve standartları çok yüksek.',
      'Bayraklı sırtlarında; ring otobüsleri ve personel servisleri düzenli işliyor.'
    ],
    webReviews: [
      'Sosyal imkanları sınırsız, teşvik performansı bölgenin en iyilerinden.'
    ],
  ),
  Hospital(
    id: 'antalya_sehir',
    name: 'Antalya Şehir Hastanesi',
    city: 'Antalya',
    district: 'Kepez',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.20,
    kpss2025: 82.70,
    workLoad: '7 / 10',
    incentive: '10.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '18.000 TL - 25.000 TL',
    surveyReviews: [
      'Yeni tesis olduğu için ortam ferah ve cihazlar son teknoloji.',
      'Personel kadrosu tamamlandıkça nöbet yükü rahat bir sisteme kavuşuyor.'
    ],
    webReviews: [
      'Tramvay bağlantısı mevcut, Akdeniz iklimi ve sosyal olanaklar için çok tercih ediliyor.'
    ],
  ),
  Hospital(
    id: 'adana_sehir',
    name: 'Adana Şehir Hastanesi',
    city: 'Adana',
    district: 'Yüreğir',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.80,
    kpss2025: 82.40,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 13.000 TL',
    shift: '24 Saat Nöbet & 16-08',
    rentRange: '15.000 TL - 20.000 TL',
    surveyReviews: [
      'Bölgenin ana referans hastanesi. Hasta yoğunluğu yüksek ama kurumsal düzen oturmuş.',
      'Yemek ve taşıma personeli şirkete bağlı, hemşirelik dışı angaryalar az.'
    ],
    webReviews: [
      'Teşvik ödemeleri bölge ortalamasına göre gayet yüksek ve düzenli yatıyor.'
    ],
  ),
  Hospital(
    id: 'mersin_sehir',
    name: 'Mersin Şehir Hastanesi',
    city: 'Mersin',
    district: 'Toroslar',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.90,
    kpss2025: 82.45,
    workLoad: '7 / 10',
    incentive: '10.500 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '15.000 TL - 21.000 TL',
    surveyReviews: [
      'Türkiye’nin ilk açılan şehir hastanelerinden biri; düzeni ve işleyişi tamamen oturmuş.',
      'Hastanenin fiziki şartları ve yemekhanesi oldukça başarılı.'
    ],
    webReviews: [
      'Akdeniz sahil şeridi, sosyal imkanlar ve uygun fiyatlı narenciye/gıda avantajı.'
    ],
  ),

  // --- DOĞU & GÜNEYDOĞU ---
  Hospital(
    id: 'diyarbakir_gazi_yasargil',
    name: 'Diyarbakır Gazi Yaşargil EAH',
    city: 'Diyarbakır',
    district: 'Yenişehir',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.30,
    kpss2025: 81.70,
    workLoad: '9 / 10',
    incentive: '9.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '12.000 TL - 17.000 TL',
    surveyReviews: [
      'Güneydoğu Anadolu’nun en büyük sağlık merkezlerinden. Çok yoğun ama çok tecrübe kazandırır.',
      'Ulaşım ağı dolmuşlarla gayet pratik.'
    ],
    webReviews: [
      'Hizmet puanı yüksek; batıya tayin istemeyi planlayanlar için büyük puan avantajı sağlar.'
    ],
  ),
  Hospital(
    id: 'erzurum_sehir',
    name: 'Erzurum Şehir Hastanesi',
    city: 'Erzurum',
    district: 'Palandöken',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.40,
    kpss2025: 81.90,
    workLoad: '9 / 10',
    incentive: '10.000 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '13.000 TL - 18.000 TL',
    surveyReviews: [
      'Kış aylarında kampüs içi ısıtma ve tüp geçitler çok iyi dizayn edilmiş.',
      'Doğu Anadolu genelinden sevk alan bölgesel ana merkez.'
    ],
    webReviews: [
      'Teşvikleri düzenli ve yüksek. Kış sporları ve doğa sevenler için cazip.'
    ],
  ),
  Hospital(
    id: 'gaziantep_sehir',
    name: 'Gaziantep Şehir Hastanesi',
    city: 'Gaziantep',
    district: 'Şahinbey',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.10,
    kpss2025: 81.60,
    workLoad: '9 / 10',
    incentive: '11.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '16.000 TL - 22.000 TL',
    surveyReviews: [
      'Yeni açılan dev kompleks. Tramvay hattı doğrudan hastaneye kadar geliyor.',
      'Hasta sirkülasyonu yüksek, ameliyathane ve yoğun bakım birimleri çok dinamik.'
    ],
    webReviews: [
      'Gaziantep gastronomi ve sanayi kenti, sosyal hayat hareketli.'
    ],
  ),
  Hospital(
    id: 'van_eah',
    name: 'Van Eğitim ve Araştırma Hastanesi',
    city: 'Van',
    district: 'Edremit',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
    kpss2024: 81.80,
    kpss2025: 81.30,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 12.500 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '11.000 TL - 16.000 TL',
    surveyReviews: [
      'Van Gölü kıyısında, manzarası ve hava kalitesi çok ferah bir yerleşkede.',
      'Bölgenin tek 3. basamak referans hastanesi olduğu için çevre illerden sevk alır.'
    ],
    webReviews: [
      'Edremit konutları hastaneye çok yakın, yaşam maliyetleri Doğu standartlarında uygundur.'
    ],
  ),
];

// ---------------- ANA SAYFA & NAVİGASYON ----------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<String> _favoriteIds = [];
  Map<String, String> _notes = {};

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favorites') ?? [];
      final notesJson = prefs.getString('notes');
      if (notesJson != null) {
        _notes = Map<String, String>.from(json.decode(notesJson));
      }
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds);
  }

  Future<void> _saveNote(String hospitalId, String noteText) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (noteText.trim().isEmpty) {
        _notes.remove(hospitalId);
      } else {
        _notes[hospitalId] = noteText;
      }
    });
    await prefs.setString('notes', json.encode(_notes));
  }

  void _toggleFavorite(String hospitalId) {
    setState(() {
      if (_favoriteIds.contains(hospitalId)) {
        _favoriteIds.remove(hospitalId);
      } else {
        _favoriteIds.add(hospitalId);
      }
    });
    _saveFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HospitalListScreen(
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        notes: _notes,
        onSaveNote: _saveNote,
      ),
      PreferenceListScreen(
        favoriteIds: _favoriteIds,
        onReorder: (newList) {
          setState(() {
            _favoriteIds = newList;
          });
          _saveFavorites();
        },
        onToggleFavorite: _toggleFavorite,
        notes: _notes,
        onSaveNote: _saveNote,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital, color: Color(0xFF0D9488)),
            label: 'Hastaneler',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${_favoriteIds.length}'),
              isLabelVisible: _favoriteIds.isNotEmpty,
              child: const Icon(Icons.format_list_numbered),
            ),
            selectedIcon: Badge(
              label: Text('${_favoriteIds.length}'),
              isLabelVisible: _favoriteIds.isNotEmpty,
              child: const Icon(Icons.format_list_numbered, color: Color(0xFF0D9488)),
            ),
            label: 'Tercih Listem',
          ),
        ],
      ),
    );
  }
}

// ---------------- HASTANE LİSTE EKRANI ----------------
class HospitalListScreen extends StatefulWidget {
  final List<String> favoriteIds;
  final Function(String) onToggleFavorite;
  final Map<String, String> notes;
  final Function(String, String) onSaveNote;

  const HospitalListScreen({
    super.key,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.notes,
    required this.onSaveNote,
  });

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  String _searchQuery = '';
  String _selectedCity = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final cities = ['Tümü', ...initialHospitals.map((h) => h.city).toSet()];

    final filtered = initialHospitals.where((h) {
      final matchesSearch = h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.city.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCity = _selectedCity == 'Tümü' || h.city == _selectedCity;
      return matchesSearch && matchesCity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hemşire Tercih Rehberi (83 KPSS)'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Hastane, il veya ilçe ara (örn: Samsun, Ankara)...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cities.map((city) {
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCity = city);
                          },
                          selectedColor: const Color(0xFFCCFBF1),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final hospital = filtered[index];
                final isFav = widget.favoriteIds.contains(hospital.id);
                final hasNote = widget.notes.containsKey(hospital.id);

                return HospitalCard(
                  hospital: hospital,
                  isFavorite: isFav,
                  hasNote: hasNote,
                  onToggleFavorite: () => widget.onToggleFavorite(hospital.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HospitalDetailScreen(
                          hospital: hospital,
                          isFavorite: isFav,
                          onToggleFavorite: () => widget.onToggleFavorite(hospital.id),
                          currentNote: widget.notes[hospital.id] ?? '',
                          onSaveNote: (note) => widget.onSaveNote(hospital.id, note),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SÜRÜKLE-BIRAK SIRALAMA EKRANI ----------------
class PreferenceListScreen extends StatelessWidget {
  final List<String> favoriteIds;
  final Function(List<String>) onReorder;
  final Function(String) onToggleFavorite;
  final Map<String, String> notes;
  final Function(String, String) onSaveNote;

  const PreferenceListScreen({
    super.key,
    required this.favoriteIds,
    required this.onReorder,
    required this.onToggleFavorite,
    required this.notes,
    required this.onSaveNote,
  });

  @override
  Widget build(BuildContext context) {
    final favHospitals = favoriteIds
        .map((id) => initialHospitals.firstWhere((h) => h.id == id,
            orElse: () => initialHospitals.first))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öncelikli Tercih Sıralamam'),
      ),
      body: favHospitals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz tercih listenize hastane eklemediniz.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hastaneler sekmesinden kalp butonuna basarak kurumları listenize ekleyebilir, ardından basılı tutarak 1., 2., 3. tercih sıranızı kolayca belirleyebilirsiniz.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFF0FDFA),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF0D9488), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sıralamayı değiştirmek için sağdaki tutamaçtan basılı tutarak yukarı-aşağı sürükleyin.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: favHospitals.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final updated = List<String>.from(favoriteIds);
                      final item = updated.removeAt(oldIndex);
                      updated.insert(newIndex, item);
                      onReorder(updated);
                    },
                    itemBuilder: (context, index) {
                      final h = favHospitals[index];
                      return Card(
                        key: ValueKey(h.id),
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            h.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${h.city} • 2025 Taban: ${h.kpss2025}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HospitalDetailScreen(
                                  hospital: h,
                                  isFavorite: true,
                                  onToggleFavorite: () => onToggleFavorite(h.id),
                                  currentNote: notes[h.id] ?? '',
                                  onSaveNote: (n) => onSaveNote(h.id, n),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------- GÜÇLENDİRİLMİŞ HASTANE KARTI ----------------
class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final bool isFavorite;
  final bool hasNote;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.isFavorite,
    required this.hasNote,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: hospital.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _fallbackHospitalBanner(hospital),
                  errorWidget: (context, url, err) => _fallbackHospitalBanner(hospital),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hospital.type,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.35),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: onToggleFavorite,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hospital.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      if (hasNote)
                        const Tooltip(
                          message: 'Kayıtlı kişisel notunuz var',
                          child: Icon(Icons.note_alt, size: 20, color: Colors.amber),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hospital.city} / ${hospital.district}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _badge('2024 Taban', '${hospital.kpss2024}'),
                      _badge('2025 Taban', '${hospital.kpss2025}'),
                      _badge('İş Yükü', hospital.workLoad),
                      _statusBadge(hospital.kpss2025),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackHospitalBanner(Hospital h) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              h.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statusBadge(double basePoint) {
    // 83 puana göre anlık durum
    final bool isLikely = 83.0 >= basePoint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isLikely ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isLikely ? Colors.green.shade300 : Colors.amber.shade300),
      ),
      child: Text(
        isLikely ? '83 Puan Gelir' : 'Sınırda / Yakın',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isLikely ? Colors.green.shade800 : Colors.amber.shade900,
        ),
      ),
    );
  }
}

// ---------------- HASTANE DETAY SAYFASI ----------------
class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String currentNote;
  final Function(String) onSaveNote;

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.currentNote,
    required this.onSaveNote,
  });

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  late TextEditingController _noteController;
  late bool _fav;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.currentNote);
    _fav = widget.isFavorite;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;

    return Scaffold(
      appBar: AppBar(
        title: Text(h.name),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.favorite : Icons.favorite_border),
            color: _fav ? Colors.red.shade100 : Colors.white,
            onPressed: () {
              setState(() => _fav = !_fav);
              widget.onToggleFavorite();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: h.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 220,
                color: const Color(0xFF0D9488),
                child: const Center(child: Icon(Icons.apartment, size: 64, color: Colors.white)),
              ),
              errorWidget: (context, url, err) => Container(
                height: 220,
                color: const Color(0xFF0D9488),
                child: const Center(child: Icon(Icons.apartment, size: 64, color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${h.city} - ${h.district} • ${h.type}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // KPSS Puan Özeti
                  Card(
                    color: const Color(0xFFF0FDFA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem('2024 KPSS Taban', '${h.kpss2024}'),
                          _infoItem('2025 KPSS Taban', '${h.kpss2025}'),
                          _infoItem('İş Yükü Puanı', h.workLoad),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Çalışma ve Yaşam Şartları
                  const Text('Çalışma ve Yaşam Şartları',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _rowInfo(Icons.payments_outlined, 'Ortalama Teşvik', h.incentive),
                  _rowInfo(Icons.schedule, 'Nöbet & Çalışma Düzeni', h.shift),
                  _rowInfo(Icons.home_outlined, 'Bölge Ev Kiraları', h.rentRange),

                  const Divider(height: 32),

                  // Kişisel Not Defteri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kişisel Tercih Notum',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Kaydet'),
                        onPressed: () {
                          widget.onSaveNote(_noteController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notunuz başarıyla kaydedildi!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Örn: Canik kiraları Atakumdan uygun, Samsun Şehir Hastanesini 1. sıraya yazabilirim...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const Divider(height: 32),

                  // Saha Raporu Geri Bildirimleri
                  const Text('Saha Raporu Verileri (Meslektaş Yanıtları)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...h.surveyReviews.map((r) => _commentBubble(r, const Color(0xFFEFF6FF), const Color(0xFF1E40AF))),

                  const SizedBox(height: 16),

                  // Bağımsız Saha & Forum Yorumları
                  const Text('Bağımsız Saha & Güncel Forum Araştırması',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...h.webReviews.map((r) => _commentBubble(r, const Color(0xFFF0FDF4), const Color(0xFF166534))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
      ],
    );
  }

  Widget _rowInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D9488)),
          const SizedBox(width: 8),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _commentBubble(String text, Color bg, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 13, height: 1.4)),
    );
  }
}
