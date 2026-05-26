# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Firecraft is a published Flutter package (pub.dev) that wraps `cloud_firestore` with a simplified, type-safe API. It is a library — there is no app to run. SDK constraints: Dart `^3.5.0`, Flutter `>=3.24.0`.

## Commands

```bash
flutter pub get                              # install deps
dart analyze                                 # lint (very_good_analysis 6.0.0)
dart format --set-exit-if-changed lib        # format check
flutter test                                 # run all tests (no test/ dir exists yet — must be created)
flutter test test/path/to/file_test.dart     # single test file
flutter test --name "pattern"                # filter by test name
dart pub publish --dry-run                   # validate before publishing
```

CI runs via `VeryGoodOpenSource/very_good_workflows/flutter_package.yml` on PRs to `main`, plus semantic PR title check and cspell on markdown.

## Architecture

The package surface is intentionally tiny — one class, one model — but every method follows the same conventions, so changes must be made consistently across all of them.

**Entry point:** [lib/firecraft.dart](lib/firecraft.dart) is the only public export; everything else lives under `lib/src/` and is exposed selectively. New public types must be added to this barrel.

**Singleton:** `Firecraft` has a private constructor and is consumed exclusively via `Firecraft.instance`. `_firestore` is captured as `FirebaseFirestore.instance` at construction — there is no DI hook for tests. Tests that want to substitute Firestore will need to introduce one (e.g., optional constructor param) rather than mocking the singleton in place.

**Two non-obvious invariants every method preserves** — when adding a new method, mirror these or you will silently break callers:

1. **`id` is injected into the data map before `fromJson`.** Every read path (`fetchCollection`, `fetchDocument`, `streamDocument`, `streamCollection`, `paginatedCollection`, `fetchInitialPage`, `fetchNextPage`) calls `data['id'] = doc.id;` before handing the map to the caller's `fromJson`. Models therefore expect `id` to come from the map, not from a separate parameter. `streamDocumentField` and the count APIs are the only readers that do not do this.

2. **Pagination detects `hasMore` by over-fetching by one.** All three paginated methods request `limit + 1`, then `take(limit)` for `items` and set `hasMore = docs.length > limit`. `lastDocument` is taken from the *unsliced* docs list (`docs[docs.length - 1]`), which means it can point at the over-fetched extra. If you change one of the three, change all three — they are not extracted into a helper.

**Error handling pattern:** every method wraps its body in `try { ... } on FirebaseException catch (_) { rethrow; }`. The catch is intentional (it scopes which exceptions surface as `FirebaseException` vs. propagate as-is) — keep it when adding methods.

**Batch writes:** `updateWhereField` filters in-memory after the query (the `condition` callback runs on Dart-side data, not as a Firestore `where`), then commits in chunks of `batchSize` (default 500, Firestore's hard limit). Do not raise the default above 500.

## Conventions

- Lints are `very_good_analysis` — strict. Trailing commas, doc comments on public APIs, and `final` on locals are enforced. New public methods need a `///` doc block matching the existing parameter-list style.
- Public symbols use `T Function(Map<String, dynamic> json) fromJson` and `Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>>) queryBuilder` — keep these exact signatures for consistency with the rest of the API.
- `.github/cspell.json` governs the spell check on markdown; add new technical terms there if CI flags them.
- Version bumps go in `pubspec.yaml` and `CHANGELOG.md` together.
