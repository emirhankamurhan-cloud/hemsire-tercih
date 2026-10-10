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
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.teal,
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
  final String type; // Şehir, EAH, Devlet
  final String imageUrl;
  final double kpss2024;
  final double kpss2025;
  final String workLoad; // 10 üzerinden
  final String incentive; // Teşvik
  final String shift; // Nöbet usulü
  final String rentRange; // Ortalama kira
  final List<String> surveyReviews; // Rapor içi çalışan yorumları
  final List<String> webReviews; // Dış saha / forum araştırmaları

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

// ---------------- VERİ TABANI (ÖRNEK VE YENİ KURUMLAR) ----------------
final List<Hospital> initialHospitals = [
  Hospital(
    id: 'samsun_sehir',
    name: 'Samsun Şehir Hastanesi',
    city: 'Samsun',
    district: 'Canik',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800',
    kpss2024: 83.45,
    kpss2025: 82.90,
    workLoad: '8 / 10',
    incentive: '12.000 TL - 16.000 TL',
    shift: '08:00 - 08:00 (24 saat nöbet)',
    rentRange: '15.000 TL - 22.000 TL',
    surveyReviews: [
      'Bina ve teknoloji son sistem. Başlarda birim transferleri yoğundu ancak düzen oturuyor.',
      'Canik çevre yolunda olduğu için ulaşım servis ve ekspres otobüslerle sağlanıyor.'
    ],
    webReviews: [
      'Geniş servis alanları ve yeni cihazlar mevcut. Ameliyathane ve yoğun bakımlarda vardiyalar oturmuş durumda.',
      'İl dışından gelecekler için Atakum tarafına göre hastane çevresi (Canik) kiraları bir tık daha makul.'
    ],
  ),
  Hospital(
    id: 'ankara_bilkent',
    name: 'Ankara Bilkent Şehir Hastanesi',
    city: 'Ankara',
    district: 'Çankaya',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800',
    kpss2024: 84.10,
    kpss2025: 83.60,
    workLoad: '9 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 (24 Saat) & 16-8',
    rentRange: '25.000 TL - 35.000 TL',
    surveyReviews: [
      'Hasta sirkülasyonu çok fazla. Çevre illerden sürekli yoğun bakım ve acil sevki geliyor.',
      'Sistem işi ve akreditasyon belgelemesi fazla. Mesleki tecrübe için devasa bir okul.'
    ],
    webReviews: [
      'Hastanenin kendi kampüsü çok büyük, binalar arası geçişler efor gerektiriyor.',
      'Metroya doğrudan ring otobüsleri var. Genç hemşire kadrosu ağırlıkta.'
    ],
  ),
  Hospital(
    id: 'adana_sehir',
    name: 'Adana Şehir Hastanesi',
    city: 'Adana',
    district: 'Yüreğir',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800',
    kpss2024: 82.80,
    kpss2025: 82.40,
    workLoad: '8 / 10',
    incentive: '11.000 TL - 13.000 TL',
    shift: '24 Saat Nöbet & 16-08',
    rentRange: '15.000 TL - 20.000 TL',
    surveyReviews: [
      'Yoğun bir hastane, özellikle acil servis ve yoğun bakım temposu yüksek.',
      'Yemek ve taşıma personeli şirkete bağlı olduğu için hemşirelik dışı angaryalar daha az.'
    ],
    webReviews: [
      'Bölgenin ana referans hastanesi. Teşvik ödemeleri bölge standartlarına göre iyi ve düzenli yatar.'
    ],
  ),
  Hospital(
    id: 'basaksehir_cam_sakura',
    name: 'Başakşehir Çam ve Sakura Şehir Hastanesi',
    city: 'İstanbul',
    district: 'Başakşehir',
    type: 'Şehir Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=800',
    kpss2024: 80.50,
    kpss2025: 79.90,
    workLoad: '10 / 10',
    incentive: '12.000 TL - 15.000 TL',
    shift: '08:00 - 08:00 & 8-16/16-08',
    rentRange: '25.000 TL - 32.000 TL',
    surveyReviews: [
      'Kağıtsız hastane sistemi var; ilaçlar bileklik barkoduyla veriliyor. Alışınca pratikleşiyor.',
      'İş temposu yüksek, doğrudan metro durağı mevcut. Ev kiraları Başakşehir çevresinde yüksek.'
    ],
    webReviews: [
      'Uluslararası standartta ekipmanlar var. Çok fazla hasta profili ve cerrahi vaka görerek hızlı uzmanlaşırsınız.'
    ],
  ),
  Hospital(
    id: 'samsun_eah',
    name: 'Samsun Eğitim ve Araştırma Hastanesi',
    city: 'Samsun',
    district: 'İlkadım',
    type: 'Eğitim ve Araştırma',
    imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800',
    kpss2024: 83.10,
    kpss2025: 82.75,
    workLoad: '7 / 10',
    incentive: '8.000 TL - 12.000 TL',
    shift: '08:00 - 08:00 (24 saat)',
    rentRange: '14.000 TL - 20.000 TL',
    surveyReviews: [
      'Merkezi bir konuma sahip, dolmuş ve belediye otobüsüyle ulaşım çok pratik.',
      'Köklü bir hastane olduğu için ekipler arası iletişim ve nöbet dayanışması oturmuş durumda.'
    ],
    webReviews: [
      'Şehir hastanesinin açılmasıyla bazı birim yükleri dağıldı, çalışma ortamı daha dengeli hale geldi.'
    ],
  ),
  Hospital(
    id: 'tokat_resadiye',
    name: 'Tokat Reşadiye Devlet Hastanesi',
    city: 'Tokat',
    district: 'Reşadiye',
    type: 'Devlet Hastanesi',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=800',
    kpss2024: 82.15,
    kpss2025: 81.80,
    workLoad: '4 / 10',
    incentive: '4.000 TL - 7.000 TL',
    shift: '24 Saat Nöbet & Blok Off',
    rentRange: '8.000 TL - 12.000 TL',
    surveyReviews: [
      'İlçe hastanesi olduğu için iş yükü büyük şehirlere kıyasla oldukça sakin.',
      'Nöbetleri blok tutup memlekete gitmek veya dinlenmek için geniş boşluklar yaratılabiliyor.'
    ],
    webReviews: [
      'Yaşam giderleri çok düşük, birikim yapmak ve kafa dinlemek isteyenler için ideal bir tercih.'
    ],
  ),
];

// ---------------- ANA NAVİGASYON ----------------
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
            selectedIcon: Icon(Icons.local_hospital, color: Colors.teal),
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
              child: const Icon(Icons.format_list_numbered, color: Colors.teal),
            ),
            label: 'Tercih Listem',
          ),
        ],
      ),
    );
  }
}

// ---------------- EKRAN 1: TÜM HASTANELER LİSTESİ ----------------
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
          h.district.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCity = _selectedCity == 'Tümü' || h.city == _selectedCity;
      return matchesSearch && matchesCity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hemşire Tercih Rehberi'),
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
                    hintText: 'Hastane veya ilçe ara...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
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
                          selectedColor: Colors.teal.shade100,
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

// ---------------- EKRAN 2: SÜRÜKLE-BIRAK TERCİH SIRALAMASI ----------------
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
        title: const Text('Tercih Sıralamam (Öncelik)'),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hastaneler sekmesinden kalp butonuna basarak listenizi oluşturabilir ve burada sürükleyerek sırasını ayarlayabilirsiniz.',
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
                  color: Colors.teal.shade50,
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sıralamayı değiştirmek için sağdaki tutamaçtan basılı tutup yukarı-aşağı sürükleyin.',
                          style: TextStyle(fontSize: 12, color: Colors.teal),
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
                            backgroundColor: Colors.teal,
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
                            '${h.city} • 2025 Tabanı: ${h.kpss2025}',
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

// ---------------- HASTANE KARTI BİLEŞENİ ----------------
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
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, err) => Container(
                    height: 140,
                    color: Colors.teal.shade100,
                    child: const Icon(Icons.local_hospital, size: 50, color: Colors.teal),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
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
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: onToggleFavorite,
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
                          message: 'Kişisel notunuz var',
                          child: Icon(Icons.note_alt, size: 18, color: Colors.amber),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hospital.city} / ${hospital.district}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _badge('2024 Taban', '${hospital.kpss2024}'),
                      _badge('2025 Taban', '${hospital.kpss2025}'),
                      _badge('İş Yükü', hospital.workLoad),
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

  Widget _badge(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ---------------- EKRAN 3: DETAY, YORUMLAR VE NOT SAYFASI ----------------
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
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${h.city} - ${h.district} (${h.type})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // KPSS Puan Özeti
                  Card(
                    color: Colors.teal.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem('2024 KPSS Taban', '${h.kpss2024}'),
                          _infoItem('2025 KPSS Taban', '${h.kpss2025}'),
                          _infoItem('İş Yükü', h.workLoad),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Şartlar Listesi
                  const Text('Çalışma ve Sosyal Koşullar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _rowInfo(Icons.attach_money, 'Tahmini Teşvik', h.incentive),
                  _rowInfo(Icons.schedule, 'Çalışma/Nöbet Düzeni', h.shift),
                  _rowInfo(Icons.home, 'Ortalama Ev Kirası', h.rentRange),

                  const Divider(height: 32),

                  // Kişisel Not Bölümü
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kişisel Tercih Notum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.save, color: Colors.teal),
                        onPressed: () {
                          widget.onSaveNote(_noteController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notunuz kaydedildi!')),
                          );
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Örn: Lojman var mı araştır, acili çok yoğunmuş, teyzemlere yakın...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const Divider(height: 32),

                  // PDF Raporu Geri Bildirimleri
                  const Text('Saha Raporu Verileri (Meslektaş Yanıtları)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...h.surveyReviews.map((r) => _commentBubble(r, Colors.blue.shade50, Colors.blue.shade800)),

                  const SizedBox(height: 16),

                  // İnternet / Bağımsız Saha Yorumları
                  const Text('Bağımsız Saha & Forum Yorumları',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...h.webReviews.map((r) => _commentBubble(r, Colors.green.shade50, Colors.green.shade900)),
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
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
      ],
    );
  }

  Widget _rowInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
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
      child: Text(text, style: TextStyle(color: textColor, fontSize: 13)),
    );
  }
}
