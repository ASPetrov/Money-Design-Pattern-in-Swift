# Отворена спецификация за предупрежденията от App Intents

## Наблюдение

`ExtractAppIntentsMetadata` извежда `Metadata extraction skipped, no AppIntents.framework dependency found` по веднъж за `TestFrameworkApp`, `TestFrameworkAppTests` и `TestFrameworkAppUITests`. Трите цели имат офлайн демо и тестове без App Intents функционалност. Метаданните служат за цели, които предоставят App Intents. [Apple App Intents](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents)

На ревизия `f712550` с Xcode 27.2 предупрежденията се възпроизвеждат при Debug и Release билд на демото и тестовите му цели. Release проверката използва `ENABLE_TESTABILITY=YES` на командния ред. Билдовете, седемте теста на демото и офлайн UI сценарият минават. В публичните настройки на Xcode и локалната спецификация на екстрактора не е намерена поддържана настройка, която да изключи само тази екстракция. [Настройки на Xcode](https://developer.apple.com/documentation/xcode/build-settings-reference)

## Приемане

При налична поддържана настройка или нова версия на Xcode пусни чисти Debug и Release билдове на трите цели. Потвърди, че диагностиката изчезва и останалите предупреждения остават видими. Изпълни unit и UI тестовете на споделената схема.
