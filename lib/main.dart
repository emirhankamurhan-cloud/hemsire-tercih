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
  
  "samsun_sehir|Samsun Şehir Hastanesi|Samsun|Canik|Şehir Hastanesi|74.2|73.8|9/10|12.000-16.000 TL|24 Saat & 16-8|15.000-22.000 TL|Bina, yoğun bakımlar ve donanım son teknoloji. Canik'te kiralar Atakum'a göre daha uygun.|Çok devasa olduğu için içi ulaşım ve adımlama çok yorucu. Kurumsal işleyiş hala tam oturmadı, angarya iş yükü fazla.",
  "samsun_eah|Samsun Eğitim ve Araştırma Hastanesi|Samsun|İlkadım|Eğitim ve Araştırma|73.8|73.5|8/10|8.000-12.000 TL|24 Saat Nöbet|14.000-20.000 TL|Merkezi konumda, köklü kadro, tecrübeli ekipler var. Vaka çeşitliliği muazzam.|Şehir hastanesi açılsa da acili hala bölgenin en yoğun yerlerinden. Otopark ve trafik sorunu var.",
  "samsun_gazi|Samsun Gazi Devlet Hastanesi|Samsun|İlkadım|Devlet Hastanesi|73.5|73.1|6/10|7.000-10.000 TL|08:00-08:00 & 8-16|13.000-18.000 TL|Ağır ve komplike vakalar EAH ve Şehir'e sevk edildiği için nöbet temposu daha sakindir.|Bina eski, servis fiziki şartları yeni hastanelere kıyasla yetersiz ve dar.",
  "samsun_carsamba|Samsun Çarşamba Devlet Hastanesi|Samsun|Çarşamba|Devlet Hastanesi|73.2|72.7|6/10|6.500-9.500 TL|24 Saat Nöbet|10.000-15.000 TL|Ulaşımı kolay, merkeze yakın düzenli ilçe.|Olaylı acil vakaları zaman zaman güvenliği zorlayabiliyor.",
  "samsun_bafra|Samsun Bafra Devlet Hastanesi|Samsun|Bafra|Devlet Hastanesi|73.4|72.9|7/10|7.000-10.000 TL|24 Saat Nöbet|11.000-16.000 TL|Gelişmiş ilçe, oturmuş hastane kültürü.|Merkezden gidiş geliş yapanlar için yol kışın yorucu olabilir.",
  "samsun_vezirkopru|Samsun Vezirköprü Devlet Hastanesi|Samsun|Vezirköprü|Devlet Hastanesi|72.8|72.3|5/10|5.500-8.500 TL|24 Saat Nöbet|8.500-12.000 TL|Yeni binasında hizmet veriyor.|Merkeze oldukça uzak.",
  
  "sinop_ataturk|Sinop Atatürk Devlet Hastanesi|Sinop|Merkez|Devlet Hastanesi|73.1|72.7|5/10|7.000-10.500 TL|24 Saat Nöbet|12.000-17.000 TL|Deniz manzaralı, çok huzurlu şehir. İş stresi ve mobbing vakaları çok nadir.|Kışın şehir çok ölü oluyor. Uzak memleketlere gidiş geliş uçak/otobüs sefer azlığından dolayı zor.",
  "sinop_boyabat|Sinop Boyabat 75. Yıl Devlet Hastanesi|Sinop|Boyabat|Devlet Hastanesi|72.4|71.9|5/10|6.000-8.500 TL|24 Saat Nöbet|9.000-13.000 TL|İl merkezine göre iç kısımlarda, yaşam çok daha ucuz.|Sahil şeridinde olmaması bazıları için dezavantaj.",
  "sinop_ayancik|Sinop Ayancık Devlet Hastanesi|Sinop|Ayancık|Devlet Hastanesi|72.2|71.8|4/10|5.000-7.500 TL|24 Saat Nöbet|8.000-12.000 TL|Sahil şeridinde küçük şirin bir kurum.|Kışın sosyal hayat neredeyse duruyor.",

  "ankara_bilkent|Ankara Bilkent Şehir Hastanesi|Ankara|Çankaya|Şehir Hastanesi|74.5|74.0|10/10|12.000-15.000 TL|24 Saat & 16-8|25.000-35.000 TL|Her türlü vaka görülür, mesleki gelişim için en büyük akademi. Sosyal imkanlar sonsuz.|Kampüs çok büyük, nöbetçi için fiziksel adımlama yorucu. Hasta sirkülasyonu aşırı fazla.",
  "istanbul_cam_sakura|Başakşehir Çam ve Sakura Şehir H.|İstanbul|Başakşehir|Şehir Hastanesi|69.3|68.9|10/10|12.000-15.000 TL|24 Saat Nöbet|25.000-35.000 TL|Kağıtsız hastane altyapısı, metroyla direkt içine kadar ulaşım.|İstanbul pahalılığı ve aşırı kalabalık. Yoğun bakımlarda tükenmişlik sendromu sık görülür.",
  "izmir_sehir|İzmir Şehir Hastanesi|İzmir|Bayraklı|Şehir Hastanesi|75.5|75.0|9/10|11.000-15.000 TL|24 Saat Nöbet|20.000-28.000 TL|Bina yeni, manzarası var. Ege'nin en prestijli yapısı.|Tepede yer alıyor, ring beklemek can sıkıcı. Yeni açıldığı için malzeme tedarik süreçleri bazen aksıyor.",
  "adana_sehir|Adana Şehir Hastanesi|Adana|Yüreğir|Şehir Hastanesi|74.2|73.8|8/10|11.000-14.000 TL|24 Saat Nöbet|15.000-20.000 TL|Bölgenin ana referans merkezi, teşvikleri çok tatmin edici.|Yaz aylarında inanılmaz sıcak. Acil servis yoğunluğu ve şiddet vakaları zaman zaman yorucu.",
  "trabzon_kanuni|Trabzon Kanuni EAH|Trabzon|Yomra|Eğitim ve Araştırma|73.7|73.2|8/10|9.000-13.000 TL|24 Saat Nöbet|14.000-20.000 TL|Deniz manzaralı kampüs. Tecrübeli kadrosu ve köklü yapısı var.|Doğu Karadeniz'in tüm ağır vakalarının sevki buraya geldiği için iş yükü asla bitmez.",
  "diyarbakir_gazi|Diyarbakır Gazi Yaşargil EAH|Diyarbakır|Yenişehir|Eğitim ve Araştırma|70.3|69.8|9/10|9.000-13.000 TL|24 Saat Nöbet|11.000-16.000 TL|Hizmet puanı çok yüksek, doğu görevini yaparken mesleki tecrübenin zirvesine ulaşılır.|Hasta ve hasta yakını profilini yönetmek bazen ciddi krizlere neden olabiliyor."
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

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _favoriteIds = prefs.getStringList('favs') ?? [];
        final notesStr = prefs.getString('notes');
        if (notesStr != null) _notes = Map<String, String>.from(json.decode(notesStr));
        final imagesStr = prefs.getString('images');
        if (imagesStr != null) _images = Map<String, String>.from(json.decode(imagesStr));
      });
    } catch (e) {
      debugPrint('Prefs yükleme hatası: $e');
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favs', _favoriteIds);
      await prefs.setString('notes', json.encode(_notes));
      await prefs.setString('images', json.encode(_images));
    } catch (e) {
      debugPrint('Prefs kaydetme hatası: $e');
    }
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
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('URL açma hatası: $e');
    }
  }

  void _openMap(String name, String city) {
    final query = Uri.encodeComponent("$name $city");
    _launchURL(Uri.parse("https://www.google.com/maps/search/?api=1&query=$query"));
  }

  void _openSahibinden(String city, String district) {
    String format(String text) => text.toLowerCase().replaceAll(' ', '-').replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u').replaceAll('ç', 'c').replaceAll('ş', 's').replaceAll('ğ', 'g');
    final c = format(city);
    final d = format(district);
    _launchURL(Uri.parse("https://www.sahibinden.com/kiralik-daire/$c-$d"));
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
              final idx = _hospitals.indexWhere((x) => x.id == _favoriteIds[i]);
              if (idx == -1) return const SizedBox.shrink();
              final h = _hospitals[idx];
              
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
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map, size: 16), label: const Text("Haritada Gör", style: TextStyle(fontSize: 12)),
                          onPressed: () => _openMap(h.name, h.city),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.home_work, size: 16), label: const Text("Ev Ara", style: TextStyle(fontSize: 12)),
                          onPressed: () => _openSahibinden(h.city, h.district),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  Row(
                    children: [
                      Expanded(child: _detailBox("İş Yükü", h.workLoad, Icons.trending_up)),
                      const SizedBox(width: 8),
                      Expanded(child: _detailBox("Teşvik", h.incentive, Icons.payments)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _detailBox("Nöbet", h.shift, Icons.schedule)),
                      const SizedBox(width: 8),
                      Expanded(child: _detailBox("Ev Kirası", h.rentRange, Icons.home)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.business, size: 16, color: Colors.blueGrey), const SizedBox(width: 4), Text("Lojman Durumu: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)), Expanded(child: Text(h.lojmanDurumu, style: TextStyle(color: Colors.blueGrey.shade800)))]),
                        const SizedBox(height: 6),
                        Row(children: [const Icon(Icons.school, size: 16, color: Colors.blueGrey), const SizedBox(width: 4), Text("Eğitim/Y.Lisans Toleransı: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)), Expanded(child: Text(h.egitimToleransi, style: TextStyle(color: Colors.blueGrey.shade800)))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border(left: const BorderSide(color: Colors.green, width: 4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("🟢 Artıları", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)), const SizedBox(height: 4), Text(h.pros, style: TextStyle(color: Colors.green.shade900, fontSize: 13))]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border(left: const BorderSide(color: Colors.red, width: 4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("🔴 Eksileri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)), const SizedBox(height: 4), Text(h.cons, style: TextStyle(color: Colors.red.shade900, fontSize: 13))]),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: "Kişisel notunuz...", border: OutlineInputBorder()), maxLines: 2, onChanged: (v) { _notes[h.id] = v; _savePrefs(); }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_a_photo), label: const Text("Galeriden Fotoğraf Değiştir"),
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
        children: [
          Row(children: [Icon(icon, size: 14, color: Colors.grey.shade600), const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Nöbet Ücreti Getirisi:", style: TextStyle(color: Colors.white70)), Text("+${extraPay.toStringAsFixed(0)} TL", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                const Divider(color: Colors.white30, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Toplam Tahmini Kazanç:", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("${totalPay.toStringAsFixed(0)} TL", style: const TextStyle(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
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
        SizedBox(
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            controller: TextEditingController(text: val.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: val.toStringAsFixed(0).length),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }
}
