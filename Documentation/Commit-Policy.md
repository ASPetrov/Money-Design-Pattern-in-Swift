# Commit message policy

Use Conventional Commits 1.0 for new project commits. Write the subject in English with a lowercase type, an optional scope, and a concise summary of the change. Keep the complete subject within 72 characters. [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

```text
type(scope): summary
```

- Use `feat` for new behavior and `fix` for corrections. Use `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert` when they describe the change more accurately. Use the Commitizen prompt for the full list supported by the configured adapter.
- Add a scope such as `amount`, `currency`, or `spm` when it helps identify the affected area. Start the summary with an action, as in `fix(amount): reject fractional minor units`.
- Separate an optional body or footer from the subject with a blank line. Use the body to explain decisions, effects, or migration details where useful.
- Mark an incompatible change with `!` after the type or scope or with a `BREAKING CHANGE:` footer. Describe the impact and how callers migrate.

## Local validation

Use the installed Commitizen CLI with `cz commit` for an interactive prompt or write the message with `git commit`. Both paths can use the same `commit-msg` check. The hook validates the proposed message against `.cz.toml` and rejects empty messages, invalid subjects, and subjects longer than 72 characters. Git-generated merge, revert, and autosquash messages are allowed through their configured prefixes. [Commitizen check](https://commitizen-tools.github.io/commitizen/commands/check/)

Enable the tracked hooks from the repository root:

```sh
git config --local core.hooksPath .githooks
```

This directory includes the SwiftFormat `pre-commit` hook and the Commitizen `commit-msg` hook. If the checkout already uses a different hooks directory, integrate both checks with that setup. Ensure `cz` is on the `PATH` used by Git. Run `cz check --message-length-limit 72 --message 'docs: explain checked division'` for a manual check. 
