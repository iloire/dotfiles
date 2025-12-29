# Development Guidelines

## Table of Contents
- [Design Philosophy](#design-philosophy)
- [Code Quality Standards](#code-quality-standards)
- [Security Guidelines](#security-guidelines)
- [Technical Stack](#technical-stack)
- [Architecture Patterns](#architecture-patterns)
- [UI/UX Patterns](#uiux-patterns)
- [Internationalization](#internationalization-i18n)
- [Development Workflow](#development-workflow)
- [Deployment](#deployment)

---

## Design Philosophy

### KISS (Keep It Simple, Stupid)
- Solutions must be straightforward and easy to understand
- Avoid over-engineering (e.g., complex class hierarchies for simple data models)
- Prioritize code readability and maintainability

### YAGNI (You Aren't Gonna Need It)
- Avoid speculative features or future-proofing unless explicitly required
- Focus on immediate requirements and deliverables
- Minimize code bloat and technical debt

### DRY (Don't Repeat Yourself)
- Avoid duplicating code—use reusable functions, components, or utilities
- Refactor repeated logic into shared modules or hooks
- Ensure single sources of truth for configurations and data

---

## Code Quality Standards

### Error Handling
- Implement structured error handling with specific failure modes (e.g., try-catch with custom error types)
- Verify preconditions before critical or irreversible operations (e.g., check if user exists before deletion)
- Implement timeout and cancellation mechanisms for long-running operations (e.g., `AbortController`)

### Documentation
- Include concise, purpose-driven docstrings for every function (e.g., `/** Validates user input and returns sanitized data */`)

### File Operations
- Verify existence and permissions before accessing files or paths

### Code Maintenance
- Remove unused files, imports, and code during feature reorganization
- Update all references (e.g., routes, links) when moving features between sections

### Type Safety
- Enforce strict TypeScript with `noImplicitAny` and `strictNullChecks`
- Avoid `any` types

### Automation
- Use ESLint for linting and Prettier for code formatting

---

## Security Guidelines

### Environment Variables
- Use for all configuration
- Use git-crypt to encrypt `.env` files for safe repository commits
- **Never access `process.env` directly** - create a centralized `Env` module:

```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
});

const parsed = envSchema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  throw new Error('Invalid environment variables');
}

export const Env = parsed.data;
```

- **Fail fast**: Validate all required environment variables at startup
- **Import early**: Import the `Env` module at the application entry point

### Input Handling
- Validate, sanitize, and type-check all inputs before processing (use Zod)
- Use DOMPurify for HTML, validator.js for strings
- Implement strict path validation to prevent traversal attacks

### Credentials
- Never hardcode credentials—use environment variables or secrets management (AWS Secrets Manager, HashiCorp Vault)

### Unsafe Practices to Avoid
- `eval` and unsanitized shell calls
- Command injection vectors

### Permissions & Logging
- Apply least privilege to file and process operations
- Check system-level permissions before accessing protected services
- Log sensitive operations, excluding sensitive data (e.g., log "User login attempted" but not passwords)

---

## Technical Stack

### Core Technologies
| Category | Technology |
|----------|------------|
| Framework | Next.js with App Router |
| Language | TypeScript (strict mode) |
| Database (simple) | SQLite with Prisma ORM |
| Database (complex) | PostgreSQL or MongoDB |
| UI Components | shadcn/ui (Radix UI) |
| Styling | Tailwind CSS with CSS variables |
| Forms | React Hook Form + Zod |
| State | React hooks (`useState`, `useReducer`) |
| Dates | date-fns |
| Notifications | React-Toastify |
| Icons | Lucide React |
| Charts | Chart.js |

### Database Schema Patterns
- Auto-incrementing primary keys
- Include `createdAt` and `updatedAt` timestamps
- Use nullable fields for optional data
- Avoid enums; use string fields with documented valid values
- Use JSON fields for complex data structures
- Add indexes for frequently queried fields (e.g., `userId`, `email`)
- Generate and apply migrations for all schema changes using Prisma

---

## Architecture Patterns

### File Organization
```
app/
├── api/               # API endpoints
├── admin/             # Restricted/admin pages
├── features/          # Core feature modules
└── history/           # Historical data views
components/
├── ui/                # Base UI components
├── forms/             # Form-related components
├── tables/            # Table components
├── charts/            # Visualization components
└── widgets/           # Third-party integrations
actions/               # Server-side actions
lib/
├── types.ts           # Type definitions
├── utils.ts           # Helper functions
├── validations.ts     # Validation schemas
├── env.ts             # Environment configuration
└── db.ts              # Database client configuration
scripts/               # External scripts for integrations
db/                    # Database schema and migrations
templates/             # Configuration templates
logs/                  # Application logs
```

### API Architecture
- **Routes**: Use Next.js API routes
- **Server Actions**: Prefer for database operations
- **Response Format**: `{ success: boolean, data?: any, error?: string }`
- **Error Handling**: Use try-catch with user-friendly messages
- **Validation**: Apply Zod on both client and server

#### BaseController Pattern
```typescript
// lib/base-controller.ts
export abstract class BaseController {
  protected async handle(req: Request, handler: () => Promise<Response>): Promise<Response> {
    const correlationId = crypto.randomUUID();
    try {
      this.logRequest(req, correlationId);
      await this.authenticate(req);
      const response = await handler();
      this.logResponse(response, correlationId);
      return response;
    } catch (error) {
      return this.handleError(error, correlationId);
    }
  }
  protected abstract authenticate(req: Request): Promise<void>;
  // ... logging, caching, error handling methods
}
```

Encapsulates: authentication, authorization, rate limiting, CSRF protection, logging with correlation IDs, caching, and consistent error formatting.

### Integration Patterns
- Use abstractions/adapters for external APIs to allow easy switching
- Use JSON-based configuration templates for external widgets
- Control logging levels via environment variables (e.g., `LOG_LEVEL=DEBUG`)

### Component Patterns
- Prefer server components; use client components only for interactivity
- Implement error boundaries with user-friendly messages
- Display loading indicators for async operations

---

## UI/UX Patterns

### Theme System
- Support dark/light modes with CSS variables

### Form Patterns
- Use React Hook Form with Zod for validation
- Modal forms for create/edit operations
- Inline editing for simple field updates

### Table Patterns
- Sortable headers with custom components
- Color-coded rows for status (green=active, red=deleted)
- Clickable rows for navigation with event propagation handling
- Hover effects and loading states

### Navigation
- Single-level main navigation with subsections for restricted areas
- Breadcrumb-style contextual navigation
- Logo as home link
- Minimize page loads: use client-side updates for list updates or filtering

### Accessibility
- Follow WCAG 2.1
- Use semantic HTML
- Include ARIA attributes (e.g., `aria-label` for buttons, `role="alert"` for notifications)

### Responsive Design
- Use Tailwind's responsive classes for mobile-friendly layouts

### HTML Entities
- Use entities (e.g., `&apos;` for `'`) to avoid `react/no-unescaped-entities` errors

---

## Internationalization (i18n)

### URL-based Routing
- Use URL segments for SEO optimization (e.g., `/en/about`, `/es/about`)
- Each language must have its own URL—avoid client-side language switching without URL changes

### Folder Structure
```
app/
├── [locale]/
│   ├── page.tsx          # Homepage for each locale
│   ├── about/
│   │   └── page.tsx      # /en/about, /es/about, etc.
│   └── layout.tsx        # Locale-specific layout
└── layout.tsx            # Root layout
```

### Translation Setup
- Store translations in JSON files by locale (`locales/en.json`, `locales/es.json`)
- Use `next-intl` or similar for type-safe translations

### Language Detection Priority
1. URL segment (highest)
2. `Accept-Language` header
3. User preferences from database/cookies
4. Default fallback language

### SEO
- Generate locale-specific metadata with `hreflang` tags
- Implement redirects from root to localized paths (e.g., `/` → `/en/`)
- Generate sitemaps with proper `hreflang` annotations

---

## Development Workflow

### Documentation
All documentation in the `docs/` folder:
- **CHANGELOG.md**: Changes in reverse-chronological order with UTC timestamps (`YYYY-MM-DD HH:MM`)
- **DOCS.md**: Project architecture
- **SETUP.md**: Setup instructions
- **API.md**: Endpoints, request/response formats, examples

### Commit Message Guidelines

**Format**: `<type>: <description> - <details>`

**Types**: `feat`, `fix`, `docs`, `refactor`

**Rules**:
- One commit per feature/task
- Specific, descriptive messages (not "implement tasks" or "update code")
- No references to AI tools

**Examples**:
```
feat: add user profile page - created Profile component with API integration
fix: resolve null pointer error in user fetch - added null check in API handler
docs: update API.md with new endpoint - added POST /users example
refactor: simplify navigation logic - consolidated duplicate routes in Navbar
```

---

## Deployment

### Platform
- Target serverless platforms like Vercel

### Build
- Use Next.js static generation and serverless functions

### Configuration
- Set environment variables in deployment platform

### Monitoring
- Enable Vercel Analytics
- Integrate Sentry for error tracking

### Database
- Create backups before migrations
- Maintain rollback scripts
- Optimize connections for serverless environments

### Infrastructure
- Leverage auto-scaling for traffic
- Use platform tools for custom domains and SSL certificates
