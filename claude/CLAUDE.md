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

## Modal Dialogs — No Outside-Click Dismissal

Modals must NOT close on outside-click or Escape. Require an explicit X / Cancel / Close click.

**Why:** dialogs often contain editable content (textareas, forms, multi-step flows). Outside-click silently discards edits.

```tsx
<DialogContent
  onInteractOutside={(e) => e.preventDefault()}
  onEscapeKeyDown={(e) => e.preventDefault()}
  ...
>
```

Apply to every `<Dialog>`, not just ones with forms — so users don't have to learn which dialogs behave which way.

## Dependency Weight Awareness

Before adding an npm dependency that touches the public bundle (layout, page, header, footer, or any client component reachable from them), check the cost. Public-page bytes ship to every visitor.

**Before installing, ask:**

1. **What does it weigh?** Check [bundlephobia.com](https://bundlephobia.com) or `npm install --dry-run`. ~50 KB+ minified is a budget call.
2. **Is it tree-shakable?** AST-pipeline libraries (`react-markdown` + `remark-*`, full `lodash`, full `date-fns/locale`) aren't — one entry point pulls the whole graph.
3. **Do we already have something?** Check `src/lib/utils.ts` or similar utility files first.
4. **Will it run on initial paint?** Opt-in features (modals, chat panels, admin tools) MUST be code-split via `next/dynamic`.
5. **Is the feature behind a flag?** A static `import` at the top of a file pulls the dependency in regardless of the flag — use `next/dynamic` so the import is evaluated at render time.

If a candidate fails the checklist: pick a smaller alternative, hand-roll, lazy-load the heavy path, or move it server-side.

## Database Query Performance (Public Pages)

Every query a public page runs shows up on every visitor's TTFB. Treat the home page, locale-prefixed routes, marketing pages, and the booking/checkout flow as hot paths.

When adding or modifying a query on a public route:

- **Bound result sets** — always pass `take` / `LIMIT`. Never `findMany` without one on a table that grows.
- **Index hot paths** — composite indexes for the exact `WHERE` + `ORDER BY` shape. Ship the migration in the same PR as the query.
- **Select only what you render** — `select: { ... }` to avoid wide rows (especially text/JSON columns).
- **Avoid N+1** — one query with `include`/`select` beats a loop of awaits. Check the query log when in doubt.
- **Cache where it makes sense** — Next.js `unstable_cache`, route segment `revalidate`, or Redis (Upstash) for slow-changing data. Public pages should rarely hit the DB on every request for data that changes hourly or slower.
- **Audit before merging** — sanity-check row count and execution plan against prod-like data. An empty local DB hides scans.

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
