import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final String id;
  final String name;
  final String city;
  final String district;
  final String type;
  final String defaultImageUrl;
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
    required this.defaultImageUrl,
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

// ---------------- ÖZEL İSTENENLER VE TÜM İLLER HAVUZU ----------------
final List<Hospital> initialHospitals = [
  // --- ÖNCELİKLİ SPESİFİK HASTANELER ---
  Hospital(
    id: 'tokat_devlet',
    name: 'Tokat Devlet Hastanesi',
    city: 'Tokat',
    district: 'Merkez',
    type: 'Devlet Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.20,
    kpss2025: 82.80,
    workLoad: '6 / 10',
    incentive: '7.500 TL - 11.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '10.000 TL - 15.000 TL',
    surveyReviews: ['Merkezde hayat ucuz ve rahat. Ulaşım masrafı çok az.', 'İdare çalışanlarla genel olarak uyumlu.'],
    webReviews: ['Tokat merkez hem aile hayatı hem ekonomik rahatlık için çok dengeli bir yerleşim.'],
  ),
  Hospital(
    id: 'tokat_zile',
    name: 'Tokat Zile Devlet Hastanesi',
    city: 'Tokat',
    district: 'Zile',
    type: 'Devlet Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.40,
    kpss2025: 82.00,
    workLoad: '5 / 10',
    incentive: '5.500 TL - 8.500 TL',
    shift: '24 Saat Nöbet & Blok Dinlenme',
    rentRange: '8.000 TL - 12.000 TL',
    surveyReviews: ['Huzurlu, sakin bir ilçe. Nöbet günleri dışında blok boşluklar alınabiliyor.'],
    webReviews: ['Tarihi dokusu olan sakin bir ilçe, yaşam giderleri son derece ekonomik.'],
  ),
  Hospital(
    id: 'tokat_turhal',
    name: 'Tokat Turhal Devlet Hastanesi',
    city: 'Tokat',
    district: 'Turhal',
    type: 'Devlet Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.50,
    kpss2025: 82.10,
    workLoad: '5 / 10',
    incentive: '6.000 TL - 9.000 TL',
    shift: '24 Saat Nöbet',
    rentRange: '9.000 TL - 13.000 TL',
    surveyReviews: ['Merkeze yaklaşık 20 dakika mesafede, dolmuş ulaşımı sürekli var.'],
    webReviews: ['İkinci basamak sakin bir hastane ortamı, çalışanlar arası diyalog iyi.'],
  ),
  Hospital(
    id: 'samsun_sehir',
    name: 'Samsun Şehir Hastanesi',
    city: 'Samsun',
    district: 'Canik',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.45,
    kpss2025: 82.90,
    workLoad: '8 / 10',
    incentive: '12.000 TL - 16.000 TL',
    shift: '08:00 - 08:00 (24 Saat) & 16-8',
    rentRange: '15.000 TL - 22.000 TL',
    surveyReviews: ['Bina ve donanım son teknoloji. Servis ve dinlenme alanları geniş.', 'Canik çevre yolunda servis imkanı var.'],
    webReviews: ['Atakum’a kıyasla Canik bölgesinde ev kiraları çok daha uygun.'],
  ),
  Hospital(
    id: 'samsun_eah',
    name: 'Samsun Eğitim ve Araştırma Hastanesi',
    city: 'Samsun',
    district: 'İlkadım',
    type: 'Eğitim ve Araştırma',
    defaultImageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.10,
    kpss2025: 82.75,
    workLoad: '7 / 10',
    incentive: '8.000 TL - 12.000 TL',
    shift: '08:00 - 08:00 (24 saat)',
    rentRange: '14.000 TL - 20.000 TL',
    surveyReviews: ['Merkezi konumda, köklü kadro, nöbet dayanışması oturmuş.'],
    webReviews: ['Şehir hastanesi açılınca hasta yükü dengelendi.'],
  ),
  Hospital(
    id: 'samsun_gazi',
    name: 'Samsun Gazi Devlet Hastanesi',
    city: 'Samsun',
    district: 'İlkadım',
    type: 'Devlet Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.30,
    kpss2025: 82.95,
    workLoad: '6 / 10',
    incentive: '7.000 TL - 10.000 TL',
    shift: '08:00 - 08:00 & 8-16',
    rentRange: '13.000 TL - 18.000 TL',
    surveyReviews: ['Şehrin tam kalbinde yer alır, ulaşım problemi yoktur.'],
    webReviews: ['Ağır travmalar sevk edildiği için nöbet temposu daha sakindir.'],
  ),
  Hospital(
    id: 'sinop_ataturk',
    name: 'Sinop Atatürk Devlet Hastanesi',
    city: 'Sinop',
    district: 'Merkez',
    type: 'Devlet Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.15,
    kpss2025: 82.70,
    workLoad: '5 / 10',
    incentive: '7.000 TL - 10.500 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '12.000 TL - 17.000 TL',
    surveyReviews: ['Deniz kenarında çok sakin ve huzurlu bir şehir. İş stresi düşüktür.'],
    webReviews: ['Türkiye’nin en mutlu ili olarak bilinir, sahil yaşamı sevenler için ideal bir tercih.'],
  ),

  // --- ANKARA ---
  Hospital(
    id: 'ankara_bilkent',
    name: 'Ankara Bilkent Şehir Hastanesi',
    city: 'Ankara',
    district: 'Çankaya',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 84.10,
    kpss2025: 83.60,
    workLoad: '9 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 & 16-8',
    rentRange: '25.000 TL - 35.000 TL',
    surveyReviews: ['Geniş vaka çeşitliliği, ileri düzey klinik deneyim.'],
    webReviews: ['Metro ring otobüsleri var, genç personel yoğunlukta.'],
  ),
  Hospital(
    id: 'ankara_etlik',
    name: 'Ankara Etlik Şehir Hastanesi',
    city: 'Ankara',
    district: 'Keçiören',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.80,
    kpss2025: 83.25,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat)',
    rentRange: '20.000 TL - 28.000 TL',
    surveyReviews: ['Bina yeni, malzeme sıkıntısı yok, ev imkanları geniş.'],
    webReviews: ['Teşvik ödemeleri düzenli, acilde oryantasyon programı var.'],
  ),

  // --- İSTANBUL ---
  Hospital(
    id: 'basaksehir_cam_sakura',
    name: 'Başakşehir Çam ve Sakura Şehir Hastanesi',
    city: 'İstanbul',
    district: 'Başakşehir',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&w=800&q=80',
    kpss2024: 80.50,
    kpss2025: 79.90,
    workLoad: '10 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 & 8-16/16-08',
    rentRange: '25.000 TL - 32.000 TL',
    surveyReviews: ['Kağıtsız hastane altyapısı, doğrudan metro bağlantısı.'],
    webReviews: ['Kısa sürede üst düzey klinik deneyim kazandırır.'],
  ),
  Hospital(
    id: 'istanbul_kartal_sehir',
    name: 'Kartal Dr. Lütfi Kırdar Şehir Hastanesi',
    city: 'İstanbul',
    district: 'Kartal',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 80.90,
    kpss2025: 80.40,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '22.000 TL - 30.000 TL',
    surveyReviews: ['Anadolu yakasının ana merkezi, metro kapısının önünde.'],
    webReviews: ['Sismik izolatörlü modern ve güvenli bina.'],
  ),

  // --- İZMİR ---
  Hospital(
    id: 'izmir_sehir',
    name: 'İzmir Şehir Hastanesi',
    city: 'İzmir',
    district: 'Bayraklı',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.90,
    kpss2025: 83.40,
    workLoad: '8 / 10',
    incentive: '12.000 TL - 16.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '22.000 TL - 30.000 TL',
    surveyReviews: ['Ege’nin en büyük hastanesi, bina standartları yüksek.'],
    webReviews: ['Ring otobüsleri ve personel servisleri düzenli.'],
  ),

  // --- BURSA ---
  Hospital(
    id: 'bursa_sehir',
    name: 'Bursa Şehir Hastanesi',
    city: 'Bursa',
    district: 'Nilüfer',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.15,
    kpss2025: 82.60,
    workLoad: '7 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '16.000 TL - 22.000 TL',
    surveyReviews: ['Yemek ve temizlik hizmetleri düzenli, servis mevcut.'],
    webReviews: ['Nilüfer ilçesi sosyal imkanlar açısından çok zengin.'],
  ),

  // --- ESKİŞEHİR ---
  Hospital(
    id: 'eskisehir_sehir',
    name: 'Eskişehir Şehir Hastanesi',
    city: 'Eskişehir',
    district: 'Odunpazarı',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.70,
    kpss2025: 83.10,
    workLoad: '7 / 10',
    incentive: '8.000 TL - 11.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '14.000 TL - 20.000 TL',
    surveyReviews: ['Tramvay kapısına kadar gider, ulaşım sorunsuz.'],
    webReviews: ['Genç nüfus ve sosyal hayat açısından en popüler illerden biri.'],
  ),

  // --- ANTALYA ---
  Hospital(
    id: 'antalya_sehir',
    name: 'Antalya Şehir Hastanesi',
    city: 'Antalya',
    district: 'Kepez',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.20,
    kpss2025: 82.70,
    workLoad: '7 / 10',
    incentive: '10.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '18.000 TL - 25.000 TL',
    surveyReviews: ['Yeni tesis, ortam ferah ve cihazlar son model.'],
    webReviews: ['Tramvay bağlantısı var, iklim ve sosyal ortam çok avantajlı.'],
  ),

  // --- ADANA ---
  Hospital(
    id: 'adana_sehir',
    name: 'Adana Şehir Hastanesi',
    city: 'Adana',
    district: 'Yüreğir',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.80,
    kpss2025: 82.40,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 13.000 TL',
    shift: '24 Saat Nöbet & 16-08',
    rentRange: '15.000 TL - 20.000 TL',
    surveyReviews: ['Bölgenin ana referans hastanesi, oturmuş kurumsal düzen.'],
    webReviews: ['Teşvik ödemeleri düzenli ve yüksek.'],
  ),

  // --- TRABZON ---
  Hospital(
    id: 'trabzon_kanuni',
    name: 'Trabzon Kanuni EAH',
    city: 'Trabzon',
    district: 'Yomra',
    type: 'Eğitim ve Araştırma',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 83.50,
    kpss2025: 83.05,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '15.000 TL - 22.000 TL',
    surveyReviews: ['Kaşüstü yerleşkesi ferah ve deniz manzaralı.'],
    webReviews: ['Doğu Karadeniz’in en kapsamlı sevk merkezi.'],
  ),

  // --- ÇORUM ---
  Hospital(
    id: 'corum_eah',
    name: 'Çorum Erol Olçok EAH',
    city: 'Çorum',
    district: 'Merkez',
    type: 'Eğitim ve Araştırma',
    defaultImageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.60,
    kpss2025: 82.10,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 12.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '12.000 TL - 17.000 TL',
    surveyReviews: ['İlin en büyük hastanesi, ek mesai ücretleri düzenli.'],
    webReviews: ['Yaşam maliyeti düşük, sakin bir şehir.'],
  ),

  // --- ERZURUM ---
  Hospital(
    id: 'erzurum_sehir',
    name: 'Erzurum Şehir Hastanesi',
    city: 'Erzurum',
    district: 'Palandöken',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.40,
    kpss2025: 81.90,
    workLoad: '9 / 10',
    incentive: '10.000 TL - 14.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '13.000 TL - 18.000 TL',
    surveyReviews: ['Kışın kampüs içi ısıtmalı tüp geçitler çok pratik.'],
    webReviews: ['Doğu Anadolu’nun ana bölge hastanesi.'],
  ),

  // --- DİYARBAKIR ---
  Hospital(
    id: 'diyarbakir_gazi_yasargil',
    name: 'Diyarbakır Gazi Yaşargil EAH',
    city: 'Diyarbakır',
    district: 'Yenişehir',
    type: 'Eğitim ve Araştırma',
    defaultImageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.30,
    kpss2025: 81.70,
    workLoad: '9 / 10',
    incentive: '9.000 TL - 13.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '12.000 TL - 17.000 TL',
    surveyReviews: ['Bölgenin en yoğun merkezi, çok fazla vaka tecrübesi.'],
    webReviews: ['Hizmet puanı çok yüksek, gelecekte tayin avantajı sağlar.'],
  ),

  // --- GAZİANTEP ---
  Hospital(
    id: 'gaziantep_sehir',
    name: 'Gaziantep Şehir Hastanesi',
    city: 'Gaziantep',
    district: 'Şahinbey',
    type: 'Şehir Hastanesi',
    defaultImageUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=800&q=80',
    kpss2024: 82.10,
    kpss2025: 81.60,
    workLoad: '9 / 10',
    incentive: '11.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '16.000 TL - 22.000 TL',
    surveyReviews: ['Yeni açılan dev tesis, tramvay bağlantısı direkt var.'],
    webReviews: ['Gaziantep sosyal hayatı hareketli bir şehir.'],
  ),

  // --- VAN ---
  Hospital(
    id: 'van_eah',
    name: 'Van Eğitim ve Araştırma Hastanesi',
    city: 'Van',
    district: 'Edremit',
    type: 'Eğitim ve Araştırma',
    defaultImageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
    kpss2024: 81.80,
    kpss2025: 81.30,
    workLoad: '8 / 10',
    incentive: '9.000 TL - 12.500 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '11.000 TL - 16.000 TL',
    surveyReviews: ['Van Gölü kenarında temiz ve ferah yerleşke.'],
    webReviews: ['Edremit konutları hastaneye çok yakın, kiralar uygun.'],
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
  Map<String, String> _customImages = {};

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
      final imagesJson = prefs.getString('custom_images');
      if (imagesJson != null) {
        _customImages = Map<String, String>.from(json.decode(imagesJson));
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

  Future<void> _saveCustomImage(String hospitalId, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customImages[hospitalId] = imagePath;
    });
    await prefs.setString('custom_images', json.encode(_customImages));
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
        customImages: _customImages,
        onSaveCustomImage: _saveCustomImage,
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
        customImages: _customImages,
        onSaveCustomImage: _saveCustomImage,
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
            label: 'Tüm Hastaneler',
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

// ---------------- HASTANE LİSTESİ ----------------
class HospitalListScreen extends StatefulWidget {
  final List<String> favoriteIds;
  final Function(String) onToggleFavorite;
  final Map<String, String> notes;
  final Function(String, String) onSaveNote;
  final Map<String, String> customImages;
  final Function(String, String) onSaveCustomImage;

  const HospitalListScreen({
    super.key,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.notes,
    required this.onSaveNote,
    required this.customImages,
    required this.onSaveCustomImage,
  });

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  String _searchQuery = '';
  String _selectedCity = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final cities = ['Tümü', ...initialHospitals.map((h) => h.city).toSet().toList()..sort()];

    final filtered = initialHospitals.where((h) {
      final matchesSearch = h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.city.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCity = _selectedCity == 'Tümü' || h.city == _selectedCity;
      return matchesSearch && matchesCity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hemşire Tercih Rehberi (${initialHospitals.length} Kurum)'),
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
                    hintText: 'Hastane, il veya ilçe ara (Tokat, Samsun, Zile vb.)...',
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
                final customImg = widget.customImages[hospital.id];

                return HospitalCard(
                  hospital: hospital,
                  customImagePath: customImg,
                  isFavorite: isFav,
                  hasNote: hasNote,
                  onToggleFavorite: () => widget.onToggleFavorite(hospital.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HospitalDetailScreen(
                          hospital: hospital,
                          customImagePath: customImg,
                          isFavorite: isFav,
                          onToggleFavorite: () => widget.onToggleFavorite(hospital.id),
                          currentNote: widget.notes[hospital.id] ?? '',
                          onSaveNote: (note) => widget.onSaveNote(hospital.id, note),
                          onSaveCustomImage: (path) => widget.onSaveCustomImage(hospital.id, path),
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

// ---------------- SÜRÜKLE-BIRAK SIRALAMA ----------------
class PreferenceListScreen extends StatelessWidget {
  final List<String> favoriteIds;
  final Function(List<String>) onReorder;
  final Function(String) onToggleFavorite;
  final Map<String, String> notes;
  final Function(String, String) onSaveNote;
  final Map<String, String> customImages;
  final Function(String, String) onSaveCustomImage;

  const PreferenceListScreen({
    super.key,
    required this.favoriteIds,
    required this.onReorder,
    required this.onToggleFavorite,
    required this.notes,
    required this.onSaveNote,
    required this.customImages,
    required this.onSaveCustomImage,
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
                      'Hastaneler sekmesinden kalp butonuna basarak kurumları listenize ekleyebilir, ardından basılı tutup sürükleyerek 1., 2., 3. tercih sıranızı belirleyebilirsiniz.',
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
