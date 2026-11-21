# Базови проверки за етап 7

## Публичен API

Снимката е от ревизия `d7868f7` на macOS 27.2.1 с Xcode 27.2 и Swift 6.4.2. От корена изпълни `swift package dump-symbol-graph --minimum-access-level public`. SwiftPM записва графите в `.build/out/symbolgraph` при този инструментариум.

[Нормализираният TSV](MoneyFramework-Public-API.tsv) съдържа 189 записа за символи и 260 за връзки от графите `MoneyFramework`, `MoneyFramework@Foundation` и `MoneyFramework@Swift`. Броят включва генерирани от компилатора символи. Използвай същия инструментариум за сравнение. За редовете `symbol` колоните след вида на реда са граф, точен идентификатор, достъп, вид на символа, път и текст на декларацията. За `relationship` са граф, вид на връзката, изходен и целеви идентификатор, резервно име на целта и допълнителни полета като JSON със сортирани ключове. Всеки блок е сортиран лексикографски. Изходните позиции и документационните коментари са пропуснати, защото базата служи за сравнение при преместване на код.

## Swift Testing проба

В отделен временен Swift пакет с tools 6.0 и macOS 12 добави локалния `Packages/MoneyFramework` като зависимост на тестова цел. Постави теста в тази цел и изпълни `swift test` с избрания инструментариум.

```swift
import MoneyFramework
import Testing

@Test func amountPreservesMinorUnits() throws {
    let amount = try Amount(decimalString: "1.23")
    #expect(try amount.minorUnits(scale: 2) == 123)
}
```

С Xcode 27.2 и Swift 6.4.2 SwiftPM откри и изпълни 1/1 Swift Testing тест. Последвалата проверка със Swift 6.0 / Xcode 16.0 изпълни пълния библиотечен набор през двата SPM входа, включително теста за `Sendable`. [GitHub Actions](https://github.com/ASPetrov/Money-Design-Pattern-in-Swift/actions/runs/44870210365)
