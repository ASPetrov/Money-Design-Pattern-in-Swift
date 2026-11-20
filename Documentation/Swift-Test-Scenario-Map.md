# Карта на сценариите за Swift Testing

База от етап 7. Обхваща 77 библиотечни, 4 приложни unit и 1 UI XCTest метода. Имената по-долу са текущите методи. При обединяване запази входовете и проверките, които пазят различен договор.

## AmountTests

| Сценарий и действие | Текущи XCTest методи |
| --- | --- |
| Скаларни операнди и проверено деление. **Запази.** | `testSignedAndUnsignedScalarsPreserveTheirBoundaryValues`, `testCheckedDivisionUsesExactAmountScalarsAndRejectsInvalidStrings` |
| Точност, граници и локализирано парсиране. **Запази.** | `testExactConstructionAndMinorUnits`, `testRejectsInvalidAndInexactInputs`, `testLocalizedParsingIsExactAndConsumesTheWholeInput` |

## CurrencyTests

| Сценарий и действие | Текущи XCTest методи |
| --- | --- |
| Конструктор с всички полета. **Запази.** | `testDefaultConstructorShouldStoreAllPassedValues` |
| Конструктори по ISO код и locale, валидни и невалидни входове. **Обедини по договор.** | `testCanCreateCurrencyFromCurrencyCode`, `testCanNotCreateCurrencyFromInvalidCurrencyCode`, `testCanCreateCurrencyFromLocaleWithAssociatedCurrency`, `testCanNotCreateCurrencFromLocaleWithoutAssociatedCurrency` |
| Подразбиращ се locale спрямо изричен текущ locale, включително nil. **Замени.** | `testCanCreateCurrencyFromCurrentLocale` |
| Метаданни по ISO код или locale с точни очаквания за полетата. **Обедини.** | `testCurrencyCodeMatch`, `testCurrencyCodeNotMatch`, `testCurrencyNameMatch`, `testCurrencyNameNotMatch`, `testCurrencySymbolMatch`, `testCurrencySymbolNotMatch`, `testCurrencyMaximumFractionDigitsMatch`, `testCurrencyMaximumFractionDigitsNotMatch`, `testCurrencDecimalSeparatorMatch`, `testCurrencyDecimalSeparatorNotMatch`, `testCurrencGroupingSeparatorMatch`, `testCurrencyGroupingSeparatorNotMatch` |
| Равни и различни валути. **Обедини.** | `testTwoCurrencyObjectsAreEqual`, `testTwoCurrencyObjectsAreNotEqual` |
| Производителност на lookup по locale и ISO код. **Остави в XCTest.** | `testCreateCurrencyWithLocaleIdentifierPerformance`, `testCreateCurrencyWithCurrencyCodePerformance` |

## CustomCurrencyTests

| Сценарий и действие | Текущи XCTest методи |
| --- | --- |
| Точност и формат за BTC/ETH във всеки locale, чужд суфикс и остатъчен текст. **Параметризирай.** | `testCryptoAmountsRoundTripExactlyAcrossLocales` |
| Идентичност и мащаб при сравнение и аритметика. **Запази валидните случаи и параметризирай отказите.** | `testIdentityAndScaleAreCheckedBeforeArithmetic` |
| Конвертиране между типове, невалидни курсове и препълване. **Запази и параметризирай курсовете.** | `testExplicitConversionAcrossCurrencyTypesAndValidation` |
| Делегиране, конфликтен мащаб, диапазон на ETH. **Запази.** | `testConversionUsesTheSuppliedStrategy`, `testConversionRejectsConflictingScalesForTheSameIdentity`, `testLargeETHRemainsDisplayableOutsideMinorUnitRange` |
| ISO формат и парсиране в изричен locale, остатъчен текст и USD без locale. **Запази и обедини припокриването за USD от MoneyTests.** | `testISOParsingUsesTheRequestedLocaleAndRejectsTrailingText` |
| Невалиден мащаб на валута. **Запази.** | `testMoneyRejectsInvalidExternalCurrencyScale` |

## MoneyTests

| Сценарий и действие | Текущи XCTest методи |
| --- | --- |
| Създаване, четене на валута и сума, невалиден вход. **Обедини по договор и пренеси USD без locale към ISO регресията.** | `testCanCreateMoney`, `testCanCreateMoneyWithAmountAsDecimal`, `testCanCreateMoneyWithAmountAsString`, `testCanCreateMoneyWithAmountAsFormattedString`, `testCanNotCreateMoneyWithBadDecimal`, `testCanNotCreateMoneyWithBadString`, `testCanReadCurrency`, `testCanReadAmount` |
| Знак, нула и абсолютна стойност. **Параметризирай.** | `testIsZeroReturnsTrue`, `testIsZeroReturnsFalse`, `testIsNegativeReturnsTrue`, `testIsNegativeReturnsFalse`, `testIsPositiveReturnsTrue`, `testIsPositiveReturnsFalse`, `testAbsolute` |
| Минимални единици и размер на една единица. **Запази.** | `testAmountInSubunits`, `testOneSubunit` |
| Наследени входни точки за равно и пропорционално разпределение. **Запази.** | `testAllocateToRecepients`, `testAllocateToRecepientsUsingRatios` |
| Конвертиране EUR към USD със стандартна стратегия. **Запази.** | `testConvertEurosToDollars` |
| Равенство и подреждане на съвместими стойности. **Обедини по договор.** | `testTwoMoneyObjectsWithSameAmountAndCurrencyAreEqual`, `testTwoMoneyObjectsWithDifferentAmountAndSameCurrencyAreNotEqual`, `testTwoMoneyObjectsWithSameAmountAndDifferentCurrencyAreNotEqual`, `testTwoMoneyObjectsWithDifferentAmountAndDifferentCurrencyAreNotEqual`, `testLeftSideMoneyObjectAmountIsGreaterThanRightSideMoneyObjectAmount`, `testLeftSideMoneyObjectAmmountIsLessThanRightSideMoneyObjectAmount` |
| Наследена аритметика, ред на операндите, избор на закръгляне и конвертиране към целеви мащаб. **Запази входните точки и параметризирай общите договори.** | `testAddMoney`, `testAddAmount`, `testSubtractMoney`, `testSubtractAmount`, `testMultiplyByAmount`, `testSubtractOperatorWithMoneyOnEitherSide`, `testMultiplyOperatorWithMoneyOnEitherSide`, `testArithmeticRoundingIsSelectedPerOperation`, `testScalarMinusMoneyUsesDefaultRounding` |
| Съвместимост на Amount API и проверено деление. **Запази.** | `testConversionAppliesRequestedRoundingAtTargetCurrencyPrecision`, `testAmountBackedMoneyPreservesPublicDecimalAccessAndRounding` |
| Проверено разпределение, точни грешки и граници. **Запази и параметризирай.** | `testCheckedDivisionHandlesZeroAndAppliesRequestedRounding`, `testCheckedEqualAllocationConservesPositiveNegativeAndZeroAmounts`, `testCheckedWeightedAllocationSkipsZeroWeightsAndHandlesIntMin`, `testCheckedAllocationRejectsInvalidInputsAndUnrepresentableMinorUnits` |
| Унарен минус при положителни, отрицателни и нулеви суми. **Параметризирай.** | `testUnaryMinusReversesTheSignAndPreservesCurrency` |

## ConversionModelTests

| Сценарий и действие | Текущи XCTest методи |
| --- | --- |
| Офлайн резултат, инвалидиране след редакция, отказ без заявка, еднакви валути без заявка и грешка на доставчик. **Мигрирай след библиотеката на MainActor.** | `testConvertsSelectedCurrenciesUsingSampleRates`, `testRejectsInvalidAmountBeforeConversion`, `testSameCurrencyUsesTheOriginalAmount`, `testReportsProviderFailure` |

## OfflineConversionTests

| Сценарий и действие | Текущи XCTest методи |
| --- | --- |
| Офлайн конвертиране през UI. **Остави в XCTest.** | `testConvertsUsingSampleRates` |
