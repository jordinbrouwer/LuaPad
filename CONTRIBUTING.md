# Contributing

Contributions are welcome and appreciated.

## Development guidelines

- Create feature branches. Do not work directly on `main`.
- Keep each change focused on one feature or fix.
- Keep commits meaningful and history clean.
- Write commit messages as [Conventional Commits](https://www.conventionalcommits.org/): `feat: ...`, `fix: ...`, `docs: ...`. They decide the next version and the changelog (see Releases).
- Follow the existing code style in this repository.
- Keep changes simple and avoid unnecessary complexity.
- Everything that ships with the addon lives in `src/` (the `.toc`, icon and Lua code); the release zip is built from that folder only.
- Keep the `.toc` file list in load order.
- To test in game, link `src/` into your AddOns folder as `LuaPad` (for example `Interface/AddOns/LuaPad -> <repo>/src`).
- Document intentional behavior changes in `README.md`, `CHANGELOG.md`, or this file.

## Run checks locally

Use these before opening a PR (`luacheck` is required for lint, `shellcheck` for shell, `zip` for the release dry-run):

- Fast structural pass:
  - `bash ./scripts/check.sh quick`
- Full check suite:
  - `bash ./scripts/check.sh all`
- Individual modes:
  - `bash ./scripts/check.sh --help`
- The `Checks` workflow runs every mode listed by `bash ./scripts/check.sh list` as its own job, so a new `scripts/check/<name>.sh` is picked up automatically.
- Workflows in `.github/workflows/`:

| Workflow | Runs on | Does |
| --- | --- | --- |
| `Checks` (`checks.yml`) | pull requests, by hand, and first inside Release and Publish | all checks |
| `Release` (`release.yml`) | push to `main`, by hand | Checks, then a new version, changelog and tag when the commits ask for it |
| `Publish` (`publish.yml`) | a `1.2.3` tag, started by Release or pushed by hand | Checks and `📦 Build package`, then `🐙 GitHub release` and `🔥 CurseForge upload` (skipped when not run on a tag) |

## Releases

Releases are automatic. After the checks pass on `main`, the `Release` workflow reads the commits since the last tag that change `src/`. Commits that only touch docs, scripts or workflows never release, whatever their type. The `🧭 Next version` job works this out next to the checks, so with nothing to release `🏷️ Tag release` shows as skipped:

| Commit | Next version | Changelog section |
| --- | --- | --- |
| `feat: ...` | minor (`1.2.0`) | Added |
| `fix: ...`, `perf: ...` | patch (`1.1.1`) | Fixed, Changed |
| `feat!: ...` or a `BREAKING CHANGE:` footer | major (`2.0.0`) | Added or Changed |
| `chore`, `docs`, `ci`, `test`, `refactor`, `style`, `build` | no release | not listed |

- You don't edit `CHANGELOG.md` yourself. The commit description becomes the changelog line with a link to the commit, so write it for players: `feat(ui): add dark mode` becomes `- Add dark mode. ([abc1234](.../commit/abc1234...))`. A note you do add under `## [Unreleased]` is kept and released with it.
- The bot commits the changelog as `chore(release): 1.2.0`, tags `1.2.0` and starts `Publish`, which runs the checks on the tag, publishes the GitHub Release and uploads to CurseForge.
- To release by hand: **Actions > Release > Run workflow** on `main` with `bump` set to `auto`, `patch`, `minor` or `major`. Pushing a `1.2.3` tag yourself still works too.
- Try it locally without pushing: `python3 scripts/next-release.py --changelog /tmp/CHANGELOG.md` (copy the file first; it edits it and prints the version).
- CurseForge has no API for the project description. `Publish` attaches `curseforge-description.md` (built from `README.md`) to every release and shows a warning when `README.md`, `docs/images/` or the `.toc` `## Notes:` line changed since the previous release. Paste it into CurseForge when you see that warning.
