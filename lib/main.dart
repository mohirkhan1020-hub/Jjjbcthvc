import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Volt Toolkit',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PhotosScreen(),
    const VideosScreen(),
    const AppsScreen(),
    const FilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volt Toolkit', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'ছবি'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'ভিডিও'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'অ্যাপস'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'ফাইল'),
        ],
      ),
    );
  }
}

// ================= ১. ছবি এবং ভিডিও স্ক্রিন =================
class PhotosScreen extends StatefulWidget {
  final bool showOnlyVideos;
  const PhotosScreen({super.key, this.showOnlyVideos = false});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<AssetEntity> _media = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: widget.showOnlyVideos ? RequestType.video : RequestType.image,
      );
      if (paths.isNotEmpty) {
        final List<AssetEntity> media = await paths[0].getAssetListPaged(page: 0, size: 200);
        setState(() {
          _media = media;
          _loading = false;
        });
        return;
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_media.isEmpty) return const Center(child: Text('কোনো ফাইল পাওয়া যায়নি!'));

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _media.length,
      itemBuilder: (context, index) {
        return FutureBuilder<File?>(
          future: _media[index].file,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(color: Colors.grey[800]);
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(snapshot.data!, fit: BoxFit.cover),
            );
          },
        );
      },
    );
  }
}

// ভিডিও স্ক্রিন (ছবির স্ক্রিনকেই রিইউজ করা হয়েছে)
class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const PhotosScreen(showOnlyVideos: true);
  }
}

// ================= ২. ফাইল স্ক্রিন =================
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<PlatformFile> _pickedFiles = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _pickedFiles = result.files;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.folder_open),
            label: const Text('ফাইল সিলেক্ট করুন'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: _pickedFiles.isEmpty
              ? const Center(child: Text('কোনো ফাইল সিলেক্ট করা হয়নি'))
              : ListView.builder(
                  itemCount: _pickedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _pickedFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Colors.blueAccent),
                      title: Text(file.name),
                      subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ================= ৩. অ্যাপস স্ক্রিন =================
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<Application> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    bool isAndroid = Platform.isAndroid;
    if (isAndroid) {
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
      );
      // নাম অনুযায়ী সাজানো
      apps.sort((a, b) => a.appName.compareTo(b.appName));
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!Platform.isAndroid) return const Center(child: Text('শুধু অ্যান্ড্রয়েডের জন্য'));
    if (_apps.isEmpty) return const Center(child: Text('কোনো অ্যাপ পাওয়া যায়নি!'));

    return ListView.builder(
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        Application app = _apps[index];
        return ListTile(
          leading: app is ApplicationWithIcon
              ? Image.memory(app.icon, width: 40, height: 40)
              : const Icon(Icons.android, size: 40),
          title: Text(app.appName),
          subtitle: Text(app.packageName, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            DeviceApps.openApp(app.packageName);
          },
        );
      },
    );
  }
}