import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/network/kling_api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kling Image Generator',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366F1),
          background: const Color(0xFF11111B),
          surface: const Color(0xFF1A1A23),
        ),
        scaffoldBackgroundColor: const Color(0xFF11111B),
      ),
      home: const ImageGenerationScreen(),
    );
  }
}

enum GenerationState { idle, loading, success, error }

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final _promptController = TextEditingController();
  final _focusNode = FocusNode();
  final _apiClient = KlingApiClient();
  GenerationState _state = GenerationState.idle;
  String? _imageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _state = GenerationState.loading;
      _imageUrl = null;
      _errorMessage = null;
    });

    try {
      final taskId = await _apiClient.generateImage(prompt);
      String? imageUrl;
      
      while (imageUrl == null) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await _apiClient.getTaskStatus(taskId);
        final data = status['data'] as Map<String, dynamic>?;
        final taskStatus = data?['task_status'] as String?;
        
        if (taskStatus == 'succeed') {
          final images = data?['task_result']?['images'] as List<dynamic>?;
          if (images != null && images.isNotEmpty) {
            imageUrl = images[0]['url'] as String?;
          }
        } else if (taskStatus == 'failed') {
          throw Exception('Task failed');
        }
      }

      setState(() {
        _imageUrl = imageUrl;
        _state = GenerationState.success;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = GenerationState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kling Image Generator'),
        backgroundColor: const Color(0xFF1A1A23),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              focusNode: _focusNode,
              autofocus: true,
              enabled: true,
              decoration: InputDecoration(
                hintText: 'Enter your prompt...',
                filled: true,
                fillColor: const Color(0xFF1A1A23),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _state == GenerationState.loading ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _state == GenerationState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Generate'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case GenerationState.idle:
        return const Center(
          child: Text(
            'Enter a prompt to generate an image',
            style: TextStyle(color: Colors.grey),
          ),
        );
      case GenerationState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating image...'),
            ],
          ),
        );
      case GenerationState.success:
        if (_imageUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.contain,
            ),
          );
        }
        return const Center(child: Text('No image'));
      case GenerationState.error:
        return Center(
          child: Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
    }
  }
}
