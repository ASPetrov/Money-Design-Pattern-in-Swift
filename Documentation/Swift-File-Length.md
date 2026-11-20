# Спецификация за дължина на Swift файловете

## Правило

Добави в [Swift Style](Swift-Style.md) лимит от 400 физически реда за всеки версиониран `.swift` файл. Включи изходния код, тестовете и двата `Package.swift` манифеста. Празните редове и коментарите се броят. Последният ред се брои и без завършващ LF. Файл с 400 реда минава, а файл с 401 се отхвърля. Проверката върху Git файловете изключва локално генерираните build артефакти.

## Инвентаризация

Проверени са всичките 17 версионирани Swift файла. Двата допълнителни `test_entry_point.swift` файла в локалните `.build` директории са генерирани от компилацията и имат по 569 реда.

| Директория | Файл | Редове |
| --- | --- | ---: |
| Корен | `Package.swift` | 23 |
| `Packages/MoneyFramework` | `Package.swift` | 23 |
| `Packages/MoneyFramework/Sources` | `Amount.swift` | 181 |
| | `ConvertCurrenciesStrategy.swift` | 73 |
| | `Currency.swift` | 352 |
| | `DecimalRepresentable.swift` | 115 |
| | `Locale+IsoCurrencyCode.swift` | 45 |
| | `Money.swift` | **468** |
| `Packages/MoneyFramework/Tests` | `AmountTests.swift` | 34 |
| | `CurrencyTests.swift` | 246 |
| | `CustomCurrencyTests.swift` | 115 |
| | `MoneyTests.swift` | **530** |
| `TestFrameworkApp/TestFrameworkApp` | `Features/Conversion/ConversionModel.swift` | 131 |
| | `Features/Conversion/ConversionView.swift` | 65 |
| | `TestFrameworkApp.swift` | 12 |
| `TestFrameworkApp/TestFrameworkAppTests` | `ConversionModelTests.swift` | 66 |
| `TestFrameworkApp/TestFrameworkAppUITests` | `OfflineConversionTests.swift` | 20 |

## План за рефакториране

1. Премести аритметичните методи и операторите от `Money.swift` в `Money+Arithmetic.swift` като съществуващите extensions. Прегледай достъпа до `result`, `checkCompatibility` и до файлово частните помощни декларации преди преместването. Запази публичните сигнатури, нивата на достъп и паричната семантика. При нужда премести частен помощник заедно с извикващия код.
2. Изнеси разпределението в `MoneyAllocationTests.swift`, а аритметиката, операторите и делението в `MoneyArithmeticTests.swift`. Остави в `MoneyTests.swift` създаването, представянето, сравненията и конвертирането. Използвай отделни `XCTestCase` класове и запази всички съществуващи проверки.
3. Провери откриването на новите файлове от двата SPM манифеста. Форматирай преместения код и преброй редовете отново. `Currency.swift` има 48 реда запас и може да се раздели по типове при бъдеща промяна, ако достигне лимита.

## Автоматична проверка

SwiftFormat 0.64.7 не разпознава правило `fileLength`. Неговото `--max-width 120` управлява ширината на реда. Проверявай броя редове със SwiftLint `file_length`, а форматирането със съществуващата конфигурация на SwiftFormat. [SwiftFormat rules](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md) · [SwiftLint file_length](https://realm.github.io/SwiftLint/file_length.html)

Предложената начална конфигурация активира само това правило. Временна проверка със SwiftLint 0.63.3 потвърди, че файл с 400 реда минава, а файл с 401 реда дава грешка, включително когато последният ред няма LF.

```yaml
only_rules:
  - file_length
file_length:
  warning: 400
  error: 400
  ignore_comment_only_lines: false
```

Добави SwiftLint към съществуващия pre-commit hook след SwiftFormat. Подай същите временни копия на staged файловете и прочети конфигурацията от Git индекса. Това запазва коректността при частично stage-нати файлове. Документирай инсталирането на SwiftLint в указанията за hook-а. Предвиди и команда за проверка на всички версионирани Swift файлове за ръчно изпълнение и за CI, ако се добави.

Ако въвеждането на SwiftLint се отложи, hook-ът може временно да приложи същия лимит чрез `awk` върху staged копията. Избери една проверка, която налага лимита.

## Критерии за приемане

- Пълната проверка минава за всички версионирани Swift файлове след преместването и форматирането.
- Проверка на hook-а показва, че 400 реда минават, 401 се отхвърлят, празните редове и коментарите се броят, а при частично stage-нат файл се проверява staged съдържанието. Преименуванията и пътищата с интервали се обработват.
- Двата SPM манифеста откриват същия брой тестове и тестовете минават. Потребителски код продължава да компилира със същия публичен API.
