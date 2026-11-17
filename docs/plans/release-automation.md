# Plan: automatic releases and metadata

Goal: nothing to do by hand for a release. Commits on `main` decide the version and the changelog, the `Release` workflow tags and starts `Publish`, and the project's descriptions follow the code.

## 1. Version and changelog from conventional commits

`scripts/next-release.py` reads the commits since the tag of the latest version in `CHANGELOG.md` that change `src/`; other commits never release.

| Commit | Version bump | Changelog section |
|---|---|---|
| `feat: ...` | minor (1.2.0) | Added |
| `fix: ...`, `perf: ...` | patch (1.1.1) | Fixed / Changed |
| `feat!: ...` or a `BREAKING CHANGE:` footer | major (2.0.0) | Added, or Changed |
| `chore`, `docs`, `ci`, `test`, `refactor`, `style`, `build`, anything else | none | not listed |

- The commit description becomes the changelog line: `feat(ui): add dark mode` → `- Add dark mode.`
- Lines already written by hand under `## [Unreleased]` are kept and go into the same release. Commit lines that repeat one of them are skipped.
- It writes the new `## [1.2.0 (date)](.../releases/tag/1.2.0)` section, points the Unreleased compare link at the new version and prints the version. It prints nothing when there is nothing to release.

## 2. Release tags and starts Publish

`release.yml` runs the checks (`checks.yml`), then:

- **Push to `main`**: runs `next-release.py`. If it returns a version, the bot commits `chore(release): 1.2.0`, tags `1.2.0`, pushes both atomically, and starts `Publish` on the tag.
- **Manual (Actions → Release → Run workflow, `bump` input)**: same, but `patch`, `minor` or `major` forces that bump even without `feat`/`fix` commits. To only run the checks, run `Checks` by hand.
- **Tag pushed by hand**: a `1.2.3` tag starts `publish.yml` directly.

Pushes made with `GITHUB_TOKEN` do not start new workflow runs, so the release commit does not start Release again. `Publish` is started with `gh workflow run`, which is allowed.

Requirement: the bot must be allowed to push to `main` (no branch protection, or `github-actions` on the bypass list).

## 3. CurseForge description (manual paste, with a warning)

CurseForge has no API for the project description; the upload API only takes files. So `Publish`:

- builds `curseforge-description.md` from `README.md`, with relative links and images turned into absolute GitHub URLs for that tag (`scripts/curseforge-description.sh`);
- attaches it to the GitHub Release;
- shows a **warning** (not a failure) only when `README.md` or `docs/images/` changed since the previous release tag;
- shows a second warning when the `.toc` `## Notes:` line changed, because that is the CurseForge summary.

## 4. Checks and docs

- New check `scripts/check/next-release.sh` runs `next-release.py` against a temporary git repository (feat/fix, nothing to release, breaking change). `Checks` picks it up automatically.
- `CONTRIBUTING.md` explains the commit format and the release flow. `CHANGELOG.md` gets an Unreleased entry.

## Not in scope

- Pushing the CurseForge description automatically through its internal, cookie-based editor endpoint (unofficial, and the cookie expires).
- Pre-releases (`-beta`) and release PRs.
