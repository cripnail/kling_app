# Skill: API Authentication
## Контекст
Безопасная работа с внешними API во Flutter.

## Правила
1. Секреты только через flutter_dotenv + String.fromEnvironment.
2. Никаких хардкодов ключей в коде, логах или UI.
3. Для подписи запросов используй dart:crypto (HMAC-SHA256).
4. Все HTTP-клиенты должны иметь:
    - Явный timeout (30s)
    - Retry при 429/5xx (max 3 попытки, экспоненциальная задержка)
    - Кастомные исключения (ApiException, TimeoutException, AuthException)
5. Перед реализацией проверь актуальную документацию через MCP fetch.
6. Не пиши UI, пока не подтверждена стабильная работа слоя аутентификации.