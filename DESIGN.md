# Дизайн-система: Kling Image Generator (Flutter)

## Философия
Интерфейс в стиле Linear и Notion: минимализм, фокус на контенте, плавные анимации, темная тема по умолчанию.

## Цветовая палитра
[Dart код]
primary: Color(0xFF6366F1)
surface: Color(0xFF1E1E2E)
background: Color(0xFF11111B)
textPrimary: Color(0xFFECEFF4)
textSecondary: Color(0xFFA6ACCD)
error: Color(0xFFEF4444)
success: Color(0xFF22C55E)
gradientStart: Color(0xFF6366F1)
gradientEnd: Color(0xFFA855F7)

## Типографика
[Dart код]
headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary)
titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary)
bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary)
labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primary)

## Отступы и сетка
- Базовый юнит: 8px
- Отступы: 16px вертикаль, 12px горизонталь
- Скругление: 12px карточки, 8px кнопки, 20px изображения
- Тени: blurRadius 20, цвет 0x1A000000

## Компоненты (Flutter)
Поле ввода: TextField с OutlineInputBorder(radius 12), подсказка "Опишите изображение...", кнопка отключена если пусто, предупреждение если <10 символов.
Карточка результата: Изображение 1:1, скругление 20, анимация fade-in. Статус загрузки: CircularProgressIndicator + текст "Генерация... ~45с". Ошибка: иконка + текст + кнопка "Повторить". Действия: "Скачать", "Поделиться" после успеха.

Состояния экрана:
| idle | Поле ввода + кнопка |
| loading | Индикатор + текст, кнопка отмены |
| success | Изображение + действия, поле активно |
| error | Ошибка + "Повторить", поле активно |

## Анимации
- Появление: FadeTransition + SlideTransition, 200ms
- Загрузка: CircularProgressIndicator с цветом primary
- Успех: ScaleTransition изображения (1.0 -> 1.02 -> 1.0)

## Анти-паттерны (НЕ делать)
- Яркие кислотные цвета
- Резкие переходы без анимации
- Перегруженные интерфейсы (максимум 2 действия на карточке)
- Хардкод отступов (использовать константы из lib/core/theme/)

## Структура темы
lib/core/theme/
app_colors.dart
app_text_styles.dart
app_spacing.dart
app_theme.dart

При генерации UI сверяйся с этим документом. Если нужно отклониться от стиля - предупреди и согласуй.