# Enjoy Lavash Mobile — session guide

Two reference files are loaded into every session. Use them before searching
the tree, and keep them accurate.

- `PROJECT_STRUCTURE.md` — the **current** layout: where screens, widgets,
  controllers, models, theme and tests live, which folders are legacy, and how
  the code stands against the roadmap. Update it in the same change whenever a
  file under `lib/`, `test/` or `docs/` is added, moved, renamed or deleted.
- `ROADMAP.md` — the **target** clean architecture and the phased refactor
  plan, with the rules every phase follows. When a task is a roadmap phase,
  follow that phase's tasks and rules; when it is ordinary feature work, keep
  new code compatible with the target layout (feature folders, tokens, l10n,
  `Result`/`Failure`, no magic values).

@PROJECT_STRUCTURE.md
@ROADMAP.md

## Working rules

- Verify with `flutter analyze` and `flutter test` before reporting done; run
  `dart format` on changed Dart files.
- Strings through `L.of(context)`, colors/spacing through `AppDesignTokens`,
  motion through `AppMotion` with a reduced-motion path.
- Do not extend legacy folders listed in `PROJECT_STRUCTURE.md`
  (`lib/widgets/ui/`, `lib/widgets/theme/`, `lib/core/data/`, `lib/enums/`).
- Commit only when asked; commit messages are short lowercase summaries.
