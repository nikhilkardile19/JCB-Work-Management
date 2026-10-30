# Engineering Conventions

## Branching & review
- `main` is always releasable. Work on `feature/<sprint>-<short-name>` or `fix/<short-name>`.
- Pull request required to merge into `main`; at least one review.
- PR checklist: formatted, analyzer/lint clean, tests pass, UI checked on a
  small (360dp) and large (≥411dp) Android screen, Mobile UI/UX Definition of
  Done (sprint doc §1.3) satisfied.
- Commit messages: imperative mood, e.g. `Add client master list screen`.

## Dart / Flutter
- `dart format` (80 cols). `flutter analyze` must report zero issues.
- Files `snake_case.dart`; classes `PascalCase`; providers end in `Provider`.
- No hard-coded colors, spacing or radii in feature code — use `AppTokens` /
  `Theme.of(context)`.
- Every screen handles loading / empty / error / offline states using the
  shared `StateView` widgets.
- Money: `int` paise. Meter readings: `int` hundredths of an hour.

## TypeScript / React
- `npm run lint` (oxlint) and `npm run build` (tsc) must pass.
- Components `PascalCase.tsx`; hooks `useThing.ts`.
- CSS via CSS custom properties defined in `src/styles/tokens.css`.

## Commands
| Task | Mobile (`mobile/`) | Admin (`admin/`) | Backend (`backend/`) |
|------|--------------------|------------------|----------------------|
| Install | `flutter pub get` | `npm install` | `npm ci` |
| Codegen | `dart run build_runner build -d` | — | `npx prisma generate` |
| Run | `flutter run --dart-define=APP_ENV=dev` | `npm run dev` | `npm run dev` |
| Lint / types | `flutter analyze` | `npm run lint` | `npm run typecheck` |
| Test | `flutter test` | `npm test` | `npm test` (needs `TEST_DATABASE_URL`) |
| DB migration | — | — | `npm run db:migrate -- --name <change>` |

## Backend
- Every route is declared with `api.route()` (`src/lib/http.ts`): its Zod
  schemas validate the request and generate the OpenAPI document.
- Never trust client-sent roles, company or license state; read them from
  PostgreSQL (`modules/companies/access.ts`, `modules/admin/adminAccess.ts`).
- Money: `BIGINT` paise. Readings/litres: `INTEGER` hundredths. No floats.
- A schema change needs a migration; CI fails on drift.
