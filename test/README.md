# Frontend unit tests

Widget + pure-Dart tests for everything under `lib/` except `main.dart`
(the `runApp` one-liner, which CI cannot execute). Layout mirrors `lib/`:

- `test/core/` — validators, booking rules, session, theme
- `test/api/` — HTTP client contract against a route-table fake
- `test/features/auth/` — auth API + login/register screens
- `test/features/customer/` — booking flow
- `test/features/shells/` — workspace shell, role shells, resource pages
- `test/shared/` — shared widgets
- `test/helpers/test_helpers.dart` — `FakeAuthApi`, `FakeHttp`,
  `testApi`, and the `shad`/`material`/`shell` harnesses

## Run

```sh
flutter pub get
flutter analyze
flutter test
```

With coverage + the 80% line gate (same as CI):

```sh
flutter test --coverage
dart run tool/coverage_gate.dart coverage/lcov.info 80
```

## CI gate

`.github/workflows/frontend-tests.yml` runs on every PR into `main`
(and every push to `main`): `pub get` → `analyze` → `test --coverage`
→ gate. The job is named **frontend unit tests** — add it as a required
status check in the repo branch ruleset so merges block until green,
same as the backend's **backend unit tests** job.
