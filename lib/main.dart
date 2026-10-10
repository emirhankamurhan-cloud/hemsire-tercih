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
  "tokat_devlet|Tokat Devlet Hastanesi|Tokat|Merkez|Devlet Hastanesi|73.2|72.8|6/10|7.500-11.000 TL|24 Saat Nöbet|10.000-15.000 TL|Merkezde yaşam çok rahat, masraflar büyükşehirlere göre düşük. Ekip uyumu genel olarak tatmin edici.|Eski bina bölümlerinde fiziki yetersizlikler mevcut. Sosyal aktivite alanları büyükşehirlere göre sınırlı.",
  "tokat_zile|Tokat Zile Devlet Hastanesi|Tokat|Zile|Devlet Hastanesi|72.4|72.0|5/10|5.500-8.500 TL|24 Saat & Blok Off|8.000-12.000 TL|Sakin ve stressiz bir ortam. Blok nöbetlerle uzun izinler ayarlanabiliyor, kiralar çok ucuz.|İlçe hayatı çok durağan, memlekete gidiş-dönüşlerde merkeze olan uzaklık kış aylarında yorucu olabilir.",
  "tokat_turhal|Tokat Turhal Devlet Hastanesi|Tokat|Turhal|Devlet Hastanesi|72.5|72.1|5/10|6.000-9.000 TL|24 Saat Nöbet|9.000-13.000 TL|Merkeze 20 dk. İkinci basamak düzenli ilçe hastanesi. Ulaşım problemi sıfır.|Acil servisinde dönem dönem personel eksiği nedeniyle nöbetler arası dinlenme süreleri kısalabiliyor.",
  "tokat_resadiye|Tokat Reşadiye Devlet Hastanesi|Tokat|Reşadiye|Devlet Hastanesi|71.9|71.5|4/10|4.000-7.000 TL|24 Saat Nöbet|8.000-12.000 TL|İş yükü çok sakin, yıpranma payı az, maddi birikim yapmak için elverişli.|Mesleki gelişim ve vaka çeşitliliği açısından çok yetersiz, mahrumiyet hissi yaratabilir.",
  "tokat_niksar|Tokat Niksar Devlet Hastanesi|Tokat|Niksar|Devlet Hastanesi|72.2|71.8|5/10|5.000-8.000 TL|24 Saat Nöbet|8.500-12.500 TL|Doğası güzel, yeşillikler içinde bir ilçe. Hastane şartları standart.|Sosyal çevre edinmek bekar personeller için zaman alabiliyor.",
  "tokat_erbaa|Tokat Erbaa Devlet Hastanesi|Tokat|Erbaa|Devlet Hastanesi|72.6|72.1|6/10|6.500-9.500 TL|24 Saat Nöbet|10.000-14.000 TL|Tokat’ın en gelişmiş ve büyük ilçesi. Sosyal imkanları diğer ilçelere göre iyi.|Hastane hasta sirkülasyonu açısından merkez hastanesi gibi yoğun olabiliyor.",
  "tokat_almus|Tokat Almus Devlet Hastanesi|Tokat|Almus|Devlet Hastanesi|71.8|71.4|4/10|4.000-6.500 TL|24 Saat Nöbet|7.000-10.000 TL|Göl kenarında doğa harikası küçük ilçe.|Merkeze ulaşım kış aylarında zorlayıcı.",
  
  "samsun_sehir|Samsun Şehir Hastanesi|Samsun|Canik|Şehir Hastanesi|74.2|73.8|9/10|12.000-16.000 TL|24 Saat & 16-8|15.000-22.000 TL|Bina, yoğun bakımlar ve donanım son teknoloji. Canik'te kiralar Atakum'a göre daha uygun.|Çok devasa olduğu için içi ulaşım ve adımlama çok yorucu. Kurumsal işleyiş hala tam oturmadı, angarya iş yükü fazla.",
  "samsun_eah|Samsun Eğitim ve Araştırma Hastanesi|Samsun|İlkadım|Eğitim ve Araştırma|73.8|73.5|8/10|8.000-12.000 TL|24 Saat Nöbet|14.000-20.000 TL|Merkezi konumda, köklü kadro, tecrübeli ekipler var. Vaka çeşitliliği muazzam.|Şehir hastanesi açılsa da acili hala bölgenin en yoğun yerlerinden. Otopark ve trafik sorunu var.",
  "samsun_gazi|Samsun Gazi Devlet Hastanesi|Samsun|İlkadım|Devlet Hastanesi|73.5|73.1|6/10|7.000-10.000 TL|08:00-08:00 & 8-16|13.000-18.000 TL|Ağır ve komplike vakalar EAH ve Şehir'e sevk edildiği için nöbet temposu daha sakindir.|Bina eski, servis fiziki şartları yeni hastanelere kıyasla yetersiz ve dar.",
  "samsun_carsamba|Samsun Çarşamba Devlet Hastanesi|Samsun|Çarşamba|Devlet Hastanesi|73.2|72.7|6/10|6.500-9.500 TL|24 Saat Nöbet|10.000-15.000 TL|Ulaşımı kolay, merkeze yakın düzenli ilçe.|Olaylı acil vakaları zaman zaman güvenliği zorlayabiliyor.",
  "samsun_bafra|Samsun Bafra Devlet Hastanesi|Samsun|Bafra|Devlet Hastanesi|73.4|72.9|7/10|7.000-10.000 TL|24 Saat Nöbet|11.000-16.000 TL|Gelişmiş ilçe, oturmuş hastane kültürü.|Merkezden gidiş geliş yapanlar için yol kışın yorucu olabilir.",
  "samsun_vezirkopru|Samsun Vezirköprü Devlet Hastanesi|Samsun|Vezirköprü|Devlet Hastanesi|72.8|72.3|5/10|5.500-8.500 TL|24 Saat Nöbet|8.500-12.000 TL|Yeni binasında hizmet veriyor.|Merkeze oldukça uzak.",
  
  "sinop_ataturk|Sinop Atatürk Devlet Hastanesi|Sinop|Merkez|Devlet Hastanesi|73.1|72.7|5/10|7.000-10.500 TL|24 Saat Nöbet|12.000-17.000 TL|Deniz manzaralı, çok huzurlu şehir. İş stresi ve mobbing vakaları çok nadir.|Kışın şehir çok ölü oluyor. Uzak memleketlere gidiş geliş uçak/otobüs sefer azlığından dolayı zor.",
  "sinop_boyabat|Sinop Boyabat 75. Yıl Devlet Hastanesi|Sinop|Boyabat|Devlet Hastanesi|72.4|71.9|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|İl merkezine göre iç kısımlarda, yaşam çok daha ucuz.|Sahil şeridinde olmaması bazıları için dezavantaj.",
  "sinop_ayancik|Sinop Ayancık Devlet Hastanesi|Sinop|Ayancık|Devlet Hastanesi|72.2|71.8|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-12.000 TL|Sahil şeridinde küçük şirin bir kurum.|Kışın sosyal hayat neredeyse duruyor.",

  "adana_sehir|Adana Şehir Hastanesi|Adana|Yüreğir|Şehir Hastanesi|74.2|73.8|8/10|11.000-14.000 TL|24 Saat Nöbet|15.000-20.000 TL|Bölgenin ana referans merkezi, teşvikleri çok tatmin edici.|Yaz aylarında inanılmaz sıcak. Acil servis yoğunluğu ve şiddet vakaları zaman zaman yorucu.",
  "ankara_bilkent|Ankara Bilkent Şehir Hastanesi|Ankara|Çankaya|Şehir Hastanesi|74.5|74.0|10/10|12.000-15.000 TL|24 Saat & 16-8|25.000-35.000 TL|Her türlü vaka görülür, mesleki gelişim için en büyük akademi. Sosyal imkanlar sonsuz.|Kampüs çok büyük, nöbetçi için fiziksel adımlama yorucu. Hasta sirkülasyonu aşırı fazla.",
  "ankara_etlik|Ankara Etlik Şehir Hastanesi|Ankara|Keçiören|Şehir Hastanesi|74.2|73.7|8/10|11.000-14.000 TL|24 Saat Nöbet|20.000-28.000 TL|Malzeme sıkıntısı yok, ev imkanları geniş.|Birimler arası koordinasyon hala oturma aşamasında.",
  "antalya_sehir|Antalya Şehir Hastanesi|Antalya|Kepez|Şehir Hastanesi|75.1|74.6|7/10|10.000-14.000 TL|24 Saat Nöbet|18.000-25.000 TL|Yeni tesis, ortam ferah. Tramvay var.|Yaz aylarında turizm yoğunluğu iş yükünü artırır.",
  "bursa_sehir|Bursa Şehir Hastanesi|Bursa|Nilüfer|Şehir Hastanesi|73.8|73.3|7/10|11.000-14.000 TL|24 Saat Nöbet|16.000-22.000 TL|Nilüfer gibi nezih bir ilçede modern kampüs.|Merkeze olan uzaklık dezavantaj.",
  "diyarbakir_gazi|Diyarbakır Gazi Yaşargil EAH|Diyarbakır|Yenişehir|Eğitim ve Araştırma|70.3|69.8|9/10|9.000-13.000 TL|24 Saat Nöbet|11.000-16.000 TL|Hizmet puanı çok yüksek, doğu görevini yaparken mesleki tecrübenin zirvesine ulaşılır.|Hasta ve hasta yakını profilini yönetmek bazen ciddi krizlere neden olabiliyor.",
  "erzurum_sehir|Erzurum Şehir Hastanesi|Erzurum|Palandöken|Şehir Hastanesi|71.4|70.9|8/10|10.000-14.000 TL|24 Saat Nöbet|11.000-16.000 TL|Kışın kapalı tüp geçitler kurtarıcı.|Aşırı soğuk iklim alışkın olmayanlar için zorlayıcı.",
  "eskisehir_sehir|Eskişehir Şehir Hastanesi|Eskişehir|Odunpazarı|Şehir Hastanesi|74.8|74.3|7/10|10.000-13.000 TL|24 Saat Nöbet|14.000-20.000 TL|Tramvay hattı ve öğrenci sosyal ortamı mükemmel.|Popüler olduğu için tayin ve yer değiştirme işlemleri zor olabilir.",
  "gaziantep_sehir|Gaziantep Şehir Hastanesi|Gaziantep|Şahinbey|Şehir Hastanesi|71.8|71.3|8/10|10.000-14.000 TL|24 Saat Nöbet|14.000-20.000 TL|Yeni kampüs, modern teşhis üniteleri.|Şehrin genel trafik ve yaşam karmaşası.",
  "istanbul_cam_sakura|Başakşehir Çam ve Sakura Şehir H.|İstanbul|Başakşehir|Şehir Hastanesi|69.3|68.9|10/10|12.000-15.000 TL|24 Saat Nöbet|25.000-35.000 TL|Kağıtsız hastane altyapısı, metroyla direkt içine kadar ulaşım.|İstanbul pahalılığı ve aşırı kalabalık. Yoğun bakımlarda tükenmişlik sendromu sık görülür.",
  "izmir_sehir|İzmir Şehir Hastanesi|İzmir|Bayraklı|Şehir Hastanesi|75.5|75.0|9/10|11.000-15.000 TL|24 Saat Nöbet|20.000-28.000 TL|Bina yeni, manzarası var. Ege'nin en prestijli yapısı.|Tepede yer alıyor, ring beklemek can sıkıcı. Yeni açıldığı için malzeme tedarik süreçleri bazen aksıyor.",
  "kayseri_sehir|Kayseri Şehir Hastanesi|Kayseri|Kocasinan|Şehir Hastanesi|74.1|73.6|7/10|10.000-13.500 TL|24 Saat Nöbet|12.000-18.000 TL|Tramvay tam önünden geçer.|Sanayi şehri yoğunluğu.",
  "kocaeli_sehir|Kocaeli Şehir Hastanesi|Kocaeli|İzmit|Şehir Hastanesi|73.1|72.6|8/10|11.000-14.500 TL|24 Saat Nöbet|15.000-22.000 TL|İstanbul'a 1 saat mesafede sanayi merkezi.|Hava kirliliği sorunu zaman zaman hissedilir.",
  "konya_sehir|Konya Şehir Hastanesi|Konya|Karatay|Şehir Hastanesi|74.1|73.6|7/10|10.000-14.000 TL|24 Saat Nöbet|12.000-17.000 TL|Düzenli ulaşım ve tramvay ağı.|Kampüs dışı sosyal alanlar sınırlı.",
  "sanliurfa_eah|Şanlıurfa Eğitim ve Araştırma Hastanesi|Şanlıurfa|Eyyübiye|Eğitim ve Araştırma|69.8|69.3|8/10|9.000-13.000 TL|24 Saat Nöbet|10.000-15.000 TL|Puan ve klinik tecrübesi yüksek.|Doğum klinikleri Türkiye'nin en yoğunudur.",
  "van_eah|Van Eğitim ve Araştırma Hastanesi|Van|Edremit|Eğitim ve Araştırma|69.6|69.1|7/10|9.000-13.000 TL|24 Saat Nöbet|10.000-15.000 TL|Göl kenarında ferah kampüs, kiralar uygun.|Kış şartları oldukça serttir.",
  "zonguldak_ataturk|Zonguldak Atatürk Devlet Hastanesi|Zonguldak|Merkez|Devlet Hastanesi|73.2|72.7|6/10|8.000-11.000 TL|24 Saat Nöbet|12.000-17.000 TL|Tecrübeli kadrosuyla bilinen merkez.|Madenci bölgesi, solunum yolları vakaları çok fazladır."
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
      // Veri yapısının doğru indekslendiğinden emin olalım.
      // id [0], name [1], city [2], district [3], type [4], k24 [5], k25 [6], wl [7], inc [8], shift [9], rent [10], pros [11], cons [12]
      final hasProsCons = p.length > 12;
      _hospitals.add(Hospital(
        id: p[0], name: p[1], city: p[2], district: p[3], type: p[4],
        kpss2024: double.tryParse(p[5]) ?? 70.0, 
        kpss2025: double.tryParse(p[6]) ?? 70.0,
        workLoad: p.length > 7 ? p[7] : '7/10',
        incentive: p.length > 8 ? p[8] : '8.000 - 11.000 TL',
        shift: p.length > 9 ? p[9] : '24 Saat Nöbet',
        rentRange: p.length > 10 ? p[10] : '12.000 - 18.000 TL',
        pros: hasProsCons ? p[11] : 'Kurumun genel işleyişi oturmuş durumda.',
        cons: hasProsCons ? p[12] : 'Dönemsel personel eksikliği yaşanabilir.',
      ));
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteIds = prefs.getStringList('favs') ?? [];
      final notesStr = prefs.getString('notes');
      if (notesStr != null) _notes = Map<String, String>.from(json.decode(notesStr));
      final imagesStr = prefs.getString('images');
      if (imagesStr != null) _images = Map<String, String>.from(json.decode(imagesStr));
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

  Future<void> _pickImage(String id) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _images[id] = pickedFile.path);
      _savePrefs();
    }
  }

  Future<void> _openMap(String name, String city) async {
    final query = Uri.encodeComponent("$name$city");
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openSahibinden(String city, String district) async {
    String format(String text) => text.toLowerCase().replaceAll(' ', '-').replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u').replaceAll('ç', 'c').replaceAll('ş', 's').replaceAll('ğ', 'g');
    final c = format(city);
    final d = format(district);
    final url = Uri.parse("https://www.sahibinden.com/kiralik-daire/$c-$d");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copyOSYMFormat() {
    String text = "ÖSYM TERCİH LİSTEM:\n\n";
    for (int i = 0; i < _favoriteIds.length; i++) {
      final h = _hospitals.firstWhere((x) => x.id == _favoriteIds[i], orElse: () => _hospitals[0]);
      text += "${i + 1}. TERCİH: ${h.name} (${h.city}/${h.district})\n";
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
                    decoration: InputDecoration(
                      hintText: 'Hastane veya İlçe Ara...',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      prefixIcon: const Icon(Icons.search, size: 20),
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
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Hastaneler'),
          NavigationDestination(
            icon: Badge(label: Text('${_favoriteIds.length}'), child: const Icon(Icons.star)),
            label: 'Tercih Listem',
          ),
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
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
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
              final h = _hospitals.firstWhere((x) => x.id == _favoriteIds[i], orElse: () => _hospitals[0]);
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("ÖSYM İçin Listeyi Kopyala"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
              onPressed: _copyOSYMFormat,
            ),
          ),
        )
      ],
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
                            Icon(Icons.apartment, color: Colors.white54, size: 40),
                            SizedBox(height: 8),
                            Text("GÖRSEL EKLENEBİLİR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))
                          ],
                        ),
