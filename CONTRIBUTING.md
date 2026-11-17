# Contributing

Contributions are welcome.

## How to contribute

1. Fork the repository and create a branch from `main`.
2. Make one feature or fix per pull request, and follow the existing code style.
3. Run the checks (see below).
4. Open a pull request against `main`. The checks run on it automatically.

## Guidelines

- Write commits as [Conventional Commits](https://www.conventionalcommits.org/): `feat: ...`, `fix: ...`, `docs: ...`. Write the description for players, because it becomes the changelog line.
- Don't change `CHANGELOG.md` or version numbers; that happens automatically when a release is made.
- Everything that ships with the addon lives in `src/`. Keep the `.toc` file list in load order.
- To test in game, link `src/` into your AddOns folder as `LuaPad`.

## Checks

Needs Python 3 and `luacheck`:

- `python3 scripts/checks/run.py quick`: fast structural checks.
- `python3 scripts/checks/run.py`: everything CI runs.

## Releases (maintainers)

A `feat`, `fix` or breaking commit in `src/` on `main` releases automatically: the pipeline writes the changelog, tags the version and publishes it to GitHub and CurseForge. **Actions > Pipeline > Run workflow** on `main` can force a `patch`, `minor` or `major` release.

Descriptions, website and images on GitHub and CurseForge can only be changed on their websites. The pipeline compares them with the code and, when they differ, shows a warning and a summary with what to paste.

Repository setup:

- Secrets `CF_API_TOKEN` and `CF_PROJECT_ID` for the CurseForge upload.
- `github-actions` must be allowed to push to `main` (for the release commit and the README release block).
