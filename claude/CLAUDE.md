# Development Guidelines

## Design Philosophy
- **KISS**: Straightforward, readable solutions. No over-engineering.
- **YAGNI**: No speculative features or future-proofing unless explicitly required.
- **DRY**: Reusable functions, components, and utilities. Single sources of truth.

## Code Quality

### Type Safety (TypeScript projects)
- Strict mode: `noImplicitAny`, `strictNullChecks`
- No `any` types

### Maintenance
- Remove unused files, imports, and code during feature reorganization
- Update all references when moving features between sections
- Never commit `.claude/settings.local.json` files

## Security

### Environment Variables
- Use for all configuration — never hardcode credentials
- Centralized env validation with Zod (fail fast at startup)
- Never access `process.env` directly — use a validated `Env` module
- **Next.js projects**: Use `.env.local` and `.env.prod` only (no `.env` file)
- Env files are encrypted in the repo with **git-crypt** (key: `~/git-crypt-key`)
- **Vercel projects**: Always add a `.vercelignore` file excluding env files so they're never copied into the build context, even when encrypted. Minimum contents:
  ```
  .env
  .env.*
  !.env.production
  ```

## Frontend Aesthetics
- Use the **frontend-design** skill when building UI
- Avoid generic "AI slop" aesthetics — create distinctive frontends

## Preferred Stack
- **Vercel** + **Next.js** when they make sense for the project (web apps, marketing sites, APIs)
- **Supabase** for backend services (auth, database, storage)
- **Turso** (libSQL) for small projects — lightweight and fast. Use `iloire@gmail.com` account for free databases (happy with it so far)
- **Redis** (Upstash) for caching, rate limiting, queues — pairs well with Vercel

## Deployment & Versioning

### Git Commit SHA in Footer
- Web projects: display short commit SHA (7 chars) in the footer using `VERCEL_GIT_COMMIT_SHA`
- Render conditionally (only when env var is present)

## Commit Messages

**Format**: `<type>: <description> - <details>`

**Types**: `feat`, `fix`, `docs`, `refactor`

**Rules**:
- **Auto-commit**: Always commit after every change unless told otherwise
- Run lint and typecheck before committing
- One commit per feature/task
- Specific, descriptive messages (not "implement tasks" or "update code")
- No references to AI tools

## Planning

- When asked to create a plan, write it directly in the `docs/` folder (not in `.claude/plans/`)
- After completing items from a plan or task file, update the document to mark them done — strikethrough the line and append ✅. Keeps the doc usable as a living checklist instead of drifting out of sync with reality

## Documentation

- **CHANGELOG.md**: Changes in reverse-chronological order with UTC timestamps (YYYY-MM-DD HH:MM)
- **/docs folder**: Project architecture. Keep documentation up to date when modifying features

@RTK.md
