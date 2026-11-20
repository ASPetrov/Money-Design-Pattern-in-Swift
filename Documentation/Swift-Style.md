# Swift style

MoneyFramework uses the Google Swift Style Guide as its baseline. We use four spaces per indentation level and a 120-column limit. Apply both consistently to library, test, and sample app code. [Google Swift Style Guide](https://google.github.io/swift/)

## Formatting

- Use spaces for indentation, LF line endings, and a final newline.
- Wrap code at 120 columns where practical. Keep indivisible URLs, literals, and imports intact when wrapping would reduce clarity or change their meaning.
- When arguments or parameters need wrapping, put the first item on a new line. Use trailing commas in multiline array and dictionary literals.
- Sort imports alphabetically, place opening braces on the same line when they fit, and omit semicolons between statements.

For `guard`, put the body on its own lines. Keep a short single condition on the `guard` line. For multiple conditions, put each condition on its own indented line after `guard` and align `else` with `guard`. SwiftFormat expands inline guard bodies and indents conditions that wrap. Short lists of conditions can still fit on one line, so split them during editing or review.

## Comments and API design

Choose names and structure that explain what the code does. Add comments when readers need a non-obvious reason, invariant, platform workaround, or financial rounding rule to understand why the code is written that way. Keep public API documentation where it explains a caller-visible contract such as units, rounding, limits, or errors.

Follow the Swift API Design Guidelines when adding or reviewing public interfaces, including services and adapters. Review names and argument labels at the call site and make units and error behavior apparent to callers. [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)

## Enforcement

SwiftFormat checks mechanical formatting using the root `.swiftformat`. Its wrapping rules handle supported constructs. Review remaining long lines against the documented exceptions. Comment usefulness and API clarity are code review criteria.

Enable the tracked `pre-commit` hook with `git config --local core.hooksPath .githooks`. The hook reads staged copies of changed Swift files and the staged formatter configuration. Run `swiftformat path/to/File.swift` to apply the rules, review the diff, and stage the intended changes.

When adding SwiftLint, use it for objective checks that complement SwiftFormat, such as residual line length and selected naming or code-quality rules. Align exceptions with this policy and keep judgment about comments and API design in review. Propose future policy changes alongside corresponding formatter or linter updates.
