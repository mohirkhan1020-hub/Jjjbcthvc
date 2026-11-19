import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Honour এর মতো কালো থিম
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    // অ্যাপ ওপেন হলেই পেছনের ক্যামেরা চালু হবে
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0], 
        ResolutionPreset.high,
      );
      _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ছবি তোলার ফাংশন
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    try {
      final XFile picture = await _controller!.takePicture();
      setState(() {
        _imageFile = picture;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ক্যামেরা চালু না হওয়া পর্যন্ত লোডিং দেখাবে
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ক্যামেরা প্রিভিউ
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // ওপরের দিকে ফ্ল্যাশ এবং সেটিংস আইকন (ডেকোরেশনের জন্য)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.flash_on, color: Colors.white),
                  Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ),
          ),

          // নিচের দিকে ক্যাপচার বাটন
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // গ্যালারি আইকন (ডেমো)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo, color: Colors.white),
                ),
                
                // শাটার বাটন
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // ক্যামেরা পরিবর্তন করার আইকন
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                  onPressed: () {
                    // এখানে ক্যামেরা পরিবর্তনের লজিক বসবে
                  },
                ),
              ],
            ),
          ),

          // ছবি তোলার পর সেই ছবি স্ক্রিনে দেখানোর জন্য
          if (_imageFile != null)
            Positioned.fill(
              child: Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _imageFile = null; // ছবি বন্ধ করে আবার ক্যামেরায় ফিরবে
                      });
                    },
                  ),
                  title: const Text('ছবি দেখুন'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: () {
                        // এখানে ছবি সেভ করার লজিক বসবে
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ছবি সেভ করা হয়েছে!')),
                        );
                        setState(() {
                          _imageFile = null;
                        });
                      },
                    )
                  ],
                ),
                body: Center(
                  child: Image.file(File(_imageFile!.path)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}