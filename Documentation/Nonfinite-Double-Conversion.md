# Безопасно преобразуване на некраен Double

Стъпката е изпълнена. Изолираният регресионен тест прекрати тестовия процес преди поправката. След поправката тестът мина за `NaN` и двете безкрайности. Двата SPM входа минаха с по 93 Swift Testing теста и 2 XCTest измервания. SwiftFormat и SwiftLint минаха.

`Double.decimalNumber` извиква `Decimal(self)` директно. При локална проба `Decimal(Double.infinity)` прекрати отделен процес. `Double.decimalConversion` вече проверява `isFinite`, а директното свойство на `Float` връща `Decimal.nan` при некраен вход. [DecimalRepresentable](../Packages/MoneyFramework/Sources/DecimalRepresentable.swift)

Добави проверка за крайност преди директното преобразуване на `Double`. `decimalNumber` връща `Decimal.nan` за `NaN` и двете безкрайности. `decimalConversion` запазва `.failure(Amount.ValidationError.unrepresentableValue)`. Документирай и двата договора върху свойствата.

Добави параметризирани тестове, които извикват директното и провереното свойство за трите некрайни стойности. Покрий поне една крайна стойност и запази тестовете за крайни `Double` стойности извън диапазона на `Decimal` и за отказите в проверената парична аритметика. Изпълни двата SPM входа, SwiftFormat и SwiftLint.
