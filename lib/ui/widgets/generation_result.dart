import 'package:flutter/material.dart';
import 'package:kling_app/core/enums/generation_state.dart';

class GenerationResultView extends StatelessWidget {
  final GenerationState state;
  final String? imageUrl;
  final String? error;

  const GenerationResultView({
    super.key,
    required this.state,
    this.imageUrl,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case GenerationState.idle:
        return const Center(
          child: Text(
            'Введите запрос и нажмите кнопку',
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
              Text('Создаём изображение…'),
            ],
          ),
        );
      case GenerationState.success:
        if (imageUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl!,
              fit: BoxFit.contain,
            ),
          );
        }
        return const Center(child: Text('Нет изображения'));
      case GenerationState.error:
        return Center(
          child: Text(
            'Произошла ошибка: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
    }
  }
}
