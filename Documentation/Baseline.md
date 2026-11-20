# Базово състояние на MoneyFramework

Проверено на 20 ноември 2026 г. върху `e4e16bd`. Инструменти — Xcode 27.2 (27B52), Apple Swift 6.4.2, iOS и iOS Simulator SDK 27.2, arm64 macOS. Проектите използват езиков режим Swift 4. Потребителските Xcode файлове са извън индекса, а схемата на примерното приложение е налична в локалните настройки.

## Компилация с текущите настройки

Изпълни от корена на хранилището.

```sh
xcodebuild -project MoneyFramework/MoneyFramework.xcodeproj \
  -scheme MoneyFramework -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/money-stage0-framework CODE_SIGNING_ALLOWED=NO build-for-testing

xcodebuild -project TestFrameworkApp/TestFrameworkApp.xcodeproj \
  -scheme TestFrameworkApp -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/money-stage0-app CODE_SIGNING_ALLOWED=NO build
```

И двете команди завършват с код 65. Този SDK допуска deployment target от iOS 15.0 до 27.2.x. Рамката задава 10.0, а библиотечната XCTest цел и приложението наследяват или задават 11.0. За проверката на приложението е налична локалната схема. При възпроизвеждане в друго клониране избери или генерирай локална схема за едноименната цел. Двете тестови цели на приложението имат празни секции Sources.

## Контролна проверка с временно зададен iOS 15

`xcrun simctl list devices available` отказа достъп до CoreSimulator в sandbox. Извън него показа инсталирани iOS 27.0 и 27.2 runtimes с налични устройства, включително iPhone 18 Pro с iOS 27.2.

```sh
xcodebuild -project TestFrameworkApp/TestFrameworkApp.xcodeproj \
  -scheme TestFrameworkApp -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/money-stage0-app CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=15.0 build

xcodebuild -project MoneyFramework/MoneyFramework.xcodeproj \
  -scheme MoneyFramework -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
  -derivedDataPath /tmp/money-stage0-ios CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=15.0 -parallel-testing-enabled NO test
```

Примерното приложение се компилира. Стойността 15.0 е само параметър на проверката и настройките в хранилището запазват текущите си стойности.

XCTest на iPhone 18 Pro с iOS 27.2 изпълни 53 теста. Минаха 52. `testCanCreateMoneyWithAmountAsFormattedString` се провали, защото създаването на USD сума от низа `"$1"` върна `nil`. [MoneyTests.swift](../Packages/MoneyFramework/Tests/MoneyFrameworkTests/MoneyTests.swift#L49)

## Компилационна проверка от потребителски код

Запиши следния код в `/tmp/money-stage0-consumer.swift`.

```swift
import Foundation
import MoneyFramework

func checkPublicAPI() {
    guard let eur = LocaleCurrency(isoCurrencyCode: "EUR"),
          let zero = Money(currency: eur),
          let decimal = Money(amount: Decimal(2), currency: eur),
          let text = Money(amount: "2.50", currency: eur, roundingMode: .bankers)
    else { return }

    let amounts: [Decimal] = [zero.amount, decimal.amount, text.amount]
    _ = amounts
}
```

```sh
xcrun --sdk iphonesimulator swiftc -swift-version 4 -typecheck \
  -target arm64-apple-ios15.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -module-cache-path /tmp/money-stage0-clang \
  -F /tmp/money-stage0-ios/Build/Products/Debug-iphonesimulator \
  /tmp/money-stage0-consumer.swift
```

Проверката завърши с код 0. Външен Swift файл импортира модула, компилира трите извиквания и чете `Money.amount` като `Decimal`.

## Очаквания за регресионните тестове

- Валидиран USD пример с изрично зададен locale парсира форматираната сума и проверява точната стойност. Запази отделно базовия резултат за стария инициализатор, докато поведението му се уточни.

- Операторите за изваждане и умножение връщат правилния резултат при двата реда на операндите. Следваща операция запазва нестандартния режим на закръгляне.
- При деление на нулева сума с валиден делител резултатът е нула. Нулев делител връща обработваема грешка.
- Разпределянето на 0.03 EUR между двама връща 0.02 EUR и 0.01 EUR. Дяловете на отрицателна сума също запазват сбора.
- Паричните операции проверяват съвместимостта на валутите и през общ интерфейс. Невалидните курсове връщат грешка, а валидните използват точността на целевата валута.
- Мрежовите тестове на примерното приложение покриват валиден отговор, неуспешен HTTP статус, невалиден курс и декодиране. [Спецификация за корекциите](Security-Remediation.md)
