import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required this.kpss2024,
    required this.kpss2025,
    required this.workLoad,
    required this.incentive,
    required this.shift,
    required this.rentRange,
    required this.surveyReviews,
    required this.webReviews,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      type: json['type'] ?? 'Devlet Hastanesi',
      kpss2024: (json['kpss2024'] as num?)?.toDouble() ?? 80.0,
      kpss2025: (json['kpss2025'] as num?)?.toDouble() ?? 80.0,
      workLoad: json['workLoad'] ?? '7 / 10',
      incentive: json['incentive'] ?? '8.000 TL - 12.000 TL',
      shift: json['shift'] ?? '24 Saat Nöbet',
      rentRange: json['rentRange'] ?? '12.000 TL - 18.000 TL',
      surveyReviews: List<String>.from(json['surveyReviews'] ?? []),
      webReviews: List<String>.from(json['webReviews'] ?? []),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Hospital> _allHospitals = [];
  bool _isLoading = true;
  List<String> _favoriteIds = [];
  Map<String, String> _notes = {};
  Map<String, String> _customImages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds = prefs.getStringList('favorites') ?? [];
    final notesJson = prefs.getString('notes');
    if (notesJson != null) _notes = Map<String, String>.from(json.decode(notesJson));
    final imgJson = prefs.getString('custom_images');
    if (imgJson != null) _customImages = Map<String, String>.from(json.decode(imgJson));

    try {
      final jsonString = await rootBundle.loadString('assets/hospitals.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allHospitals = jsonList.map((e) => Hospital.fromJson(e)).toList();
    } catch (e) {
      debugPrint('JSON load error: $e');
    }

    setState(() {
      _isLoading = false;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    final screens = [
      HospitalListScreen(
        hospitals: _allHospitals,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        notes: _notes,
        onSaveNote: _saveNote,
        customImages: _customImages,
        onSaveCustomImage: _saveCustomImage,
      ),
      PreferenceListScreen(
        hospitals: _allHospitals,
        favoriteIds: _favoriteIds,
        onReorder: (newList) {
          setState(() => _favoriteIds = newList);
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
          NavigationDestination(
            icon: const Icon(Icons.local_hospital_outlined),
            selectedIcon: const Icon(Icons.local_hospital, color: Color(0xFF0D9488)),
            label: 'Tüm Hastaneler (${_allHospitals.length})',
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

// ---------------- LİSTELEME EKRANI ----------------
class HospitalListScreen extends StatefulWidget {
  final List<Hospital> hospitals;
  final List<String> favoriteIds;
  final Function(String) onToggleFavorite;
  final Map<String, String> notes;
  final Function(String, String) onSaveNote;
  final Map<String, String> customImages;
  final Function(String, String) onSaveCustomImage;

  const HospitalListScreen({
    super.key,
    required this.hospitals,
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
    final cities = ['Tümü', ...widget.hospitals.map((h) => h.city).toSet().toList()..sort()];

    final filtered = widget.hospitals.where((h) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = h.name.toLowerCase().contains(q) ||
          h.district.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q);
      final matchesCity = _selectedCity == 'Tümü' || h.city == _selectedCity;
      return matchesSearch && matchesCity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hemşire Tercih Rehberi (${widget.hospitals.length} Kurum)'),
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
                    hintText: 'Hastane, il veya ilçe ara (Tokat, Zile, Samsun vb.)...',
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

// ---------------- SÜRÜKLE-BIRAK EKRANI ----------------
class PreferenceListScreen extends StatelessWidget {
  final List<Hospital> hospitals;
  final List<String> favoriteIds;
  final Function(List<String>) onReorder;
  final Function(String) onToggleFavorite;
  final Map<String, String> notes;
  final Function(String, String) onSaveNote;
  final Map<String, String> customImages;
  final Function(String, String) onSaveCustomImage;

  const PreferenceListScreen({
    super.key,
    required this.hospitals,
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
        .map((id) => hospitals.firstWhere((h) => h.id == id,
            orElse: () => hospitals.first))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Öncelikli Tercih Sıralamam')),
      body: favHospitals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Henüz listenize hastane eklemediniz.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Hastaneler sekmesinden kalp butonuna basarak kurumları buraya ekleyebilir, ardından basılı tutup sürükleyerek 1., 2., 3. tercih sıranızı belirleyebilirsiniz.',
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
                          'Sıralamayı değiştirmek için sağdaki tutamaçtan basılı tutup sürükleyin.',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${h.city} • 2025 Taban: ${h.kpss2025}', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HospitalDetailScreen(
                                  hospital: h,
                                  customImagePath: customImages[h.id],
                                  isFavorite: true,
                                  onToggleFavorite: () => onToggleFavorite(h.id),
                                  currentNote: notes[h.id] ?? '',
                                  onSaveNote: (n) => onSaveNote(h.id, n),
                                  onSaveCustomImage: (p) => onSaveCustomImage(h.id, p),
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

// ---------------- HASTANE KARTI (MİMARİ LOGOLU BANNER / GALERİ RESMİ) ----------------
class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final String? customImagePath;
  final bool isFavorite;
  final bool hasNote;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const HospitalCard({
    super.key,
    required this.hospital,
    this.customImagePath,
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
                _buildHeader(),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        child: Text(hospital.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      if (hasNote)
                        const Tooltip(
                          message: 'Kayıtlı notunuz var',
                          child: Icon(Icons.note_alt, size: 20, color: Colors.amber),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${hospital.city} / ${hospital.district}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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

  Widget _buildHeader() {
    if (customImagePath != null && File(customImagePath!).existsSync()) {
      return Image.file(
        File(customImagePath!),
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital_rounded, size: 52, color: Colors.white),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hospital.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
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

  Widget _statusBadge(double basePoint) {
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

// ---------------- DETAY EKRANI (GALERİ BUTONLU) ----------------
class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;
  final String? customImagePath;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String currentNote;
  final Function(String) onSaveNote;
  final Function(String) onSaveCustomImage;

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
    this.customImagePath,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.currentNote,
    required this.onSaveNote,
    required this.onSaveCustomImage,
  });

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  late TextEditingController _noteController;
  late bool _fav;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.currentNote);
    _fav = widget.isFavorite;
    _localImagePath = widget.customImagePath;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localImagePath = pickedFile.path;
      });
      widget.onSaveCustomImage(pickedFile.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf galerinizden başarıyla güncellendi!')),
      );
    }
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
            Stack(
              children: [
                _buildHeaderBanner(h),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.75),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('Galeriden Fotoğraf Ekle'),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  Text('${h.city} - ${h.district} • ${h.type}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 16),

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

                  const Text('Çalışma ve Yaşam Şartları',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _rowInfo(Icons.payments_outlined, 'Ortalama Teşvik', h.incentive),
                  _rowInfo(Icons.schedule, 'Nöbet & Çalışma Düzeni', h.shift),
                  _rowInfo(Icons.home_outlined, 'Bölge Ev Kiraları', h.rentRange),

                  const Divider(height: 32),

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
                      hintText: 'Örn: Tokat Zile ilk sıraya yazılabilir, nöbetler blok tutulabilir...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const Divider(height: 32),

                  const Text('Saha Raporu Verileri (Meslektaş Yanıtları)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...h.surveyReviews.map((r) => _commentBubble(r, const Color(0xFFEFF6FF), const Color(0xFF1E40AF))),

                  const SizedBox(height: 16),

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

  Widget _buildHeaderBanner(Hospital h) {
    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      return Image.file(
        File(_localImagePath!),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment_rounded, size: 68, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              h.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${h.city} / ${h.district}',
              style: TextStyle(color: Colors.teal.shade100, fontSize: 13),
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
