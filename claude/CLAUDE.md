# Development Guidelines

## Design Philosophy
- **KISS**: Straightforward, readable solutions. No over-engineering.
- **YAGNI**: No speculative features or future-proofing unless explicitly required.
- **DRY**: Reusable functions, components, and utilities. Single sources of truth.

## Code Quality

### Error Handling
- Structured error handling with specific failure modes (try-catch with custom error types)
- Verify preconditions before critical or irreversible operations
- Timeout and cancellation mechanisms for long-running operations (e.g., `AbortController`)

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

### Input Handling
- Validate and sanitize all inputs before processing (Zod)
- Strict path validation to prevent traversal attacks

### Unsafe Practices to Avoid
- `eval` and unsanitized shell calls
- Command injection vectors
- Logging sensitive data (passwords, tokens, etc.)

## Frontend Aesthetics

Avoid generic "AI slop" aesthetics. Create distinctive frontends.

### Typography
- Choose distinctive, beautiful fonts
- Avoid: Arial, Inter, Roboto, system fonts, Space Grotesk

### Color & Theme
- Dominant colors with sharp accents — not timid, evenly-distributed palettes
- Avoid: purple gradients on white backgrounds
- Use CSS variables for consistency

### Motion & Animation
- Prioritize CSS-only solutions; use Motion library for React
- High-impact moments over scattered micro-interactions

### Anti-Patterns
- Cookie-cutter layouts and predictable component patterns
- Converging on common "safe" choices

## Deployment & Versioning

### Git Commit SHA in Footer
- All web projects must display the short git commit SHA (first 7 chars) in the page footer
- Use `VERCEL_GIT_COMMIT_SHA` env var (provided automatically by Vercel)
- Add it as optional in the Zod env schema
- Render conditionally: only show when the env var is present (won't appear in local dev)
- Style: `text-[10px] font-mono` with muted color matching the footer theme

## Commit Messages

**Format**: `<type>: <description> - <details>`

**Types**: `feat`, `fix`, `docs`, `refactor`

**Rules**:
- **Auto-commit**: Always commit after every change unless told otherwise
- One commit per feature/task
- Specific, descriptive messages (not "implement tasks" or "update code")
- No references to AI tools

## Documentation

- **CHANGELOG.md**: Changes in reverse-chronological order with UTC timestamps (YYYY-MM-DD HH:MM)
- **DOCS.md**: Project architecture
- Keep documentation up to date when modifying features

@RTK.md
