import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e');
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
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const AdvancedCameraScreen(),
    );
  }
}

class AdvancedCameraScreen extends StatefulWidget {
  const AdvancedCameraScreen({super.key});

  @override
  State<AdvancedCameraScreen> createState() => _AdvancedCameraScreenState();
}

class _AdvancedCameraScreenState extends State<AdvancedCameraScreen> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isTakingPicture = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera(_selectedCameraIndex);
  }

  // ক্যামেরা চালু করার ফাংশন
  Future<void> _initCamera(int index) async {
    if (cameras.isEmpty) return;
    
    final controller = CameraController(
      cameras[index],
      ResolutionPreset.veryHigh, // হাই কোয়ালিটি ছবির জন্য
      enableAudio: false,
    );
    
    _controller = controller;
    
    try {
      await controller.initialize();
      await controller.setFlashMode(_currentFlashMode);
      if (mounted) setState(() {});
    } catch (e) {
      print(e);
    }
  }

  // ক্যামেরা পরিবর্তন (ফ্রন্ট/ব্যাক) করার ফাংশন
  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    
    setState(() {
      _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
      _controller = null; 
    });
    
    await _initCamera(_selectedCameraIndex);
  }

  // ফ্ল্যাশ পরিবর্তন করার ফাংশন
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode newMode;
    if (_currentFlashMode == FlashMode.off) {
      newMode = FlashMode.always;
    } else if (_currentFlashMode == FlashMode.always) {
      newMode = FlashMode.auto;
    } else {
      newMode = FlashMode.off;
    }

    try {
      await _controller!.setFlashMode(newMode);
      setState(() {
        _currentFlashMode = newMode;
      });
    } catch (e) {
      print("Flash error: $e");
    }
  }

  // ছবি তোলার এবং গ্যালারিতে সেভ করার ফাংশন
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile picture = await _controller!.takePicture();
      
      // ফোনের গ্যালারিতে ছবি সেভ করা
      await Gal.putImage(picture.path);
      
      setState(() {
        _capturedImage = picture;
        _isTakingPicture = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ছবি গ্যালারিতে সেভ হয়েছে!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
      });
      print("Picture error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ফ্ল্যাশ আইকন ঠিক করার ফাংশন
  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.auto:
        return Icons.flash_auto;
      default:
        return Icons.flash_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ১. ক্যামেরা প্রিভিউ
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // ২. ওপরের কন্ট্রোল প্যানেল (ফ্ল্যাশ এবং সেটিংস)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ফ্ল্যাশ বাটন
                  IconButton(
                    icon: Icon(_getFlashIcon(), color: Colors.white, size: 30),
                    onPressed: _toggleFlash,
                  ),
                  // আরও অপশন (ডেমো)
                  const Icon(Icons.settings, color: Colors.white, size: 30),
                ],
              ),
            ),
          ),

          // ৩. নিচের কন্ট্রোল প্যানেল (শাটার এবং ক্যামেরা সুইচ)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // গ্যালারি আইকন (ডেমো)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_library, color: Colors.white),
                    ),
                    
                    // ছবি তোলার শাটার বাটন
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
                          child: _isTakingPicture
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Container(
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
                    
                    // ক্যামেরা পরিবর্তন বাটন
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 35),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // নিচের ইন্ডিকেটর (ডেমো)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('VIDEO', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 30),
                    Container(width: 40, height: 2, color: Colors.white),
                    const SizedBox(width: 30),
                    const Text('PHOTO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),

          // ৪. ছবি তোলার পর সেটি দেখানোর ওভারলে স্ক্রিন
          if (_capturedImage != null)
            Positioned.fill(
              child: Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _capturedImage = null; // আবার ক্যামেরায় ফিরে যাবে
                      });
                    },
                  ),
                  title: const Text('রিভিউ'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _capturedImage = null; 
                        });
                      },
                    )
                  ],
                ),
                body: Center(
                  child: Image.file(File(_capturedImage!.path)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}