# Swift style

MoneyFramework uses the Google Swift Style Guide as its baseline. We use four spaces per indentation level and a 120-column limit. Apply both consistently to library, test, and sample app code. [Google Swift Style Guide](https://google.github.io/swift/)

## Formatting

- Use spaces for indentation, LF line endings, and a final newline.
- Keep each tracked Swift file at 400 physical lines or fewer, including comments and blank lines.
- Wrap code at 120 columns where practical. Keep indivisible URLs, literals, and imports intact when wrapping would reduce clarity or change their meaning.
- When arguments or parameters need wrapping, put the first item on a new line. Use trailing commas in multiline array and dictionary literals.
- Sort imports alphabetically, place opening braces on the same line when they fit, and omit semicolons between statements.

Omit `return` when a function, computed property, or closure can return its single expression implicitly. Keep explicit returns for early exits and bodies that require them. SwiftFormat checks this with `redundantReturn`.

For `guard`, put the body on its own lines. Keep a short single condition on the `guard` line. For multiple conditions, put each condition on its own indented line after `guard` and align `else` with `guard`. SwiftFormat expands inline guard bodies and indents conditions that wrap. Short lists of conditions can still fit on one line, so split them during editing or review.

## Comments and API design

Choose names and structure that explain what the code does. Add comments when readers need a non-obvious reason, invariant, platform workaround, or financial rounding rule to understand why the code is written that way. Keep public API documentation where it explains a caller-visible contract such as units, rounding, limits, or errors.

Follow the Swift API Design Guidelines when adding or reviewing public interfaces, including services and adapters. Review names and argument labels at the call site and make units and error behavior apparent to callers. [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)

Review new APIs at the call site:

- Use labels that explain the role or unit of an argument when its type alone leaves room for ambiguity. Prefer `allocate(recipientCount: 3)` and `divide(by: 2)`.
- Make mutation visible in names. Use pairs such as `sort()` and `sorted()` when both forms exist. Use assertion-like names for Boolean properties and predicates, such as `isZero`.
- Prefer properties for inexpensive derived values such as `amount`. Document the complexity of computed properties that take more than constant time.
- For new public APIs, distinguish recoverable invalid input with `throws` when callers need the reason. Document important units, default rounding, and failure conditions that callers cannot infer from the signature.

## Identifier names

Keep function and method names, test methods, variables, parameter names, and enum cases to 40 characters. SwiftLint's `identifier_name` enforces the limit for variables, parameters, and enum cases. The `function_name_length` rule checks function names composed of letters, combining marks, numbers, and underscores. Place declaration comments above the signature. The `test` prefix counts toward the limit. Type names use Swift's type naming conventions.

Use lower camel case and established terms. Check that names read clearly at the call site. SwiftLint reports violations of its lowercase-start convention through `identifier_name`. Start every Swift Testing and XCTest test method with `test` followed by a descriptive upper-camel-case suffix, as in `testRejectsInvalidCurrencyCode`. This convention also applies to parameterized and UI tests. Use ordinary names for test helpers. In Swift Testing, use a display name when the scenario needs more context. [SwiftLint identifier_name](https://realm.github.io/SwiftLint/identifier_name.html)

## Function body length

SwiftLint's `function_body_length` warns above 20 lines and reports an error above 50. The rule applies to production and test code, including initializers, deinitializers, and subscript bodies. SwiftLint counts the body and skips blank lines and comment-only lines. Extract a named step when a body grows past the limit. [SwiftLint function_body_length](https://realm.github.io/SwiftLint/function_body_length.html)

## Instance and type methods

Use instance methods for behavior that depends on a receiver or a supplied strategy. Prefer an initializer when constructing and configuring a new instance. Add a static helper only when the operation belongs to the type and has no natural receiver, such as a pure check used before initialization. Static operators follow Swift's operator declaration conventions.

## Access control

Use `private` for declarations used within a type and its same-file extensions. Use `fileprivate` when another type in the same file needs access. Use implicit `internal` for declarations shared within a module and `public` for supported library API. Mark public extension members explicitly so their visibility is clear where they are declared.

SwiftFormat enforces placement of access modifiers and simplifies redundant `fileprivate` where equivalent. Review any change to public access or public setters for compatibility.

## Error handling and optionals

Propagate errors with `try` and `throws`, or handle them explicitly where the caller can act on the failure. Avoid silent fallbacks. Use optional binding for expected absence and document what `nil` means in a public API.

Do not use `try!`, `try?`, force unwraps, or implicitly unwrapped optionals. In tests use `try XCTUnwrap`, `try #require`, or a throwing test. A force unwrap is a last resort in a test and requires a reason and a single-line SwiftLint exception. SwiftLint enforces these rules.

## Enforcement

SwiftFormat checks mechanical formatting using the root `.swiftformat`. Its wrapping rules handle supported constructs. Review remaining long lines against the documented exceptions. Comment usefulness and API clarity are code review criteria.

Enable the tracked `pre-commit` hook with `git config --local core.hooksPath .githooks`. The hook runs SwiftFormat and SwiftLint against staged copies of changed Swift files using the staged configurations. Run `swiftformat path/to/File.swift` to apply formatting, review the diff, and stage the intended changes.

Install SwiftLint with `brew install swiftlint`. To check all SwiftLint rules across tracked Swift files, run this command from the repository root.

```sh
git ls-files -z -- '*.swift' | xargs -0 swiftlint lint --no-cache --config .swiftlint.yml
```
