# Development Guidelines

## Development Workflow
### Planning & Tracking
- **TODO.md**: The agent must autonomously pick up and execute tasks from the TODO.md file in order of priority, following the instructions described in the file itself.
- **Commit frequently**: Make incremental commits for better version history.
- **Test thoroughly**: Write unit tests (e.g., Jest), integration tests (e.g., for API interactions), and end-to-end tests (e.g., Cypress) for navigation and UI flows.

### Documentation to be maintained
- **CHANGELOG.md**: Log changes in reverse-chronological order with UTC timestamps in `YYYY-MM-DD HH:MM` format (e.g., `2025-08-31 14:30 UTC`).
- **DOCS.md**: Central documentation covering project architecture.
- **SETUP.md**: Brief documentation to get the project setup.
- **API.md**: Dedicated API reference with endpoints, request/response formats, and examples (e.g., `POST /users - Request: { "name": string } - Response: { "id": number }`).
- Commit changes after each task with detailed messages following the commit guidelines.

## Commit Message Guidelines
- **One commit per feature**: Create separate commits for each task or feature from `TODO.md`.
- **Detailed messages**: Describe what was changed and how, using the prefix `feat:`, `fix:`, `docs:`, or `refactor:` (e.g., `feat: add user login form - implemented with React Hook Form and Zod validation`).
- **Avoid generic messages**: Use specific, descriptive messages instead of "implement tasks" or "update code."
- **No tool references**: Exclude references to code generation tools or AI assistance (e.g., avoid "Generated with Claude.." sort of text).
- **Examples**:
  - `feat: add user profile page - created Profile component with API integration`
  - `fix: resolve null pointer error in user fetch - added null check in API handler`
  - `docs: update API.md with new endpoint - added POST /users example`
  - `refactor: simplify navigation logic - consolidated duplicate routes in Navbar component`

### Code Quality Standards
- **Error handling**: Implement structured error handling with specific failure modes (e.g., try-catch with custom error types).
- **Docstrings**: Include concise, purpose-driven docstrings for every function (e.g., `/** Validates user input and returns sanitized data */`).
- **Preconditions**: Verify preconditions before critical or irreversible operations (e.g., check if user exists before deletion).
- **Timeouts**: Implement timeout and cancellation mechanisms for long-running operations (e.g., use `setTimeout` or `AbortController`).
- **File operations**: Verify existence and permissions before accessing files or paths.
- **Clean up unused code**: Remove unused files, imports, and code during feature reorganization.
- **Maintain consistency**: Update all references (e.g., routes, links) when moving features between sections.


### Security Compliance Guidelines
- **Environment Variables**: Use for configuration; never commit secrets.
- **Path Validation**: Implement strict validation to prevent path traversal attacks.
- **Hardcoded credentials**: Forbidden—use environment variables or secrets management (e.g., AWS Secrets Manager, HashiCorp Vault).
- **Input sanitization**: Use libraries like DOMPurify for HTML or validator.js for strings to prevent injection attacks.
- **Input validation**: Validate, sanitize, and type-check all inputs before processing (e.g., use Zod for schema validation).
- **Avoid unsafe practices**: Prohibit `eval`, unsanitized shell calls, or command injection vectors.
- **Least privilege**: Apply to file and process operations (e.g., restrict file access to read-only where possible).
- **Logging**: Log sensitive operations, excluding sensitive data (e.g., log "User login attempted" but not passwords).
- **Permissions**: Check system-level permissions before accessing protected services or paths.

## Design Philosophy Principles
### KISS (Keep It Simple, Stupid)
- Solutions must be straightforward and easy to understand.
- Avoid over-engineering (e.g., complex class hierarchies for simple data models).
- Prioritize code readability and maintainability.

### YAGNI (You Aren’t Gonna Need It)
- Avoid speculative features or future-proofing unless explicitly required.
- Focus on immediate requirements and deliverables.
- Minimize code bloat and technical debt.

### DRY (Don’t Repeat Yourself)
- Avoid duplicating code—use reusable functions, components, or utilities.
- Refactor repeated logic into shared modules or hooks.
- Ensure single sources of truth for configurations and data.

## Technical Stack & Architecture Guidelines
### Core Technology Stack
- **Framework**: Next.js with App Router for server-side rendering.
- **Language**: TypeScript with strict type checking (`noImplicitAny`, `strictNullChecks`).
- **Database for simple projects**: SQLite with Prisma ORM for simplicity and portability.
- **Database for complex projects**: Consider MongoDB for flexible schemas or PostgreSQL for relational needs. Consult the team before finalizing.
- **UI Framework**: shadcn/ui or similar, built on Radix UI for accessible components.
- **Styling**: Tailwind CSS with CSS variables for theming.
- **Forms**: React Hook Form with Zod for schema-based validation.
- **State Management**: Use React hooks (`useState`, `useReducer`); avoid external libraries unless necessary.
- **Date Handling**: date-fns for formatting and manipulation.
- **Notifications**: React-Toastify for toast notifications.
- **Icons**: Lucide React for consistent icons.
- **Charts**: Chart.js for customizable bar, line, and pie charts.

### Database Architecture
- **ORM**: Use Prisma for type-safe database operations and migrations.
- **Schema Patterns**:
  - Auto-incrementing primary keys.
  - Include `createdAt` and `updatedAt` timestamps.
  - Use nullable fields for optional data.
  - Avoid enums; use string fields with documented valid values.
  - Use JSON fields for complex data structures.
- **Migration Strategy**: Generate and apply migrations for all schema changes using Prisma.
- **Indexing**: Add indexes for frequently queried fields (e.g., `userId`, `email`).


### UI/UX Design Patterns
- **Component Library**: Use shadcn/ui for consistent, reusable components.
- **Theme System**: Support dark/light modes with CSS variables.
- **Form Patterns**:
  - Use React Hook Form with Zod for validation.
  - Modal forms for create/edit operations.
  - Inline editing for simple field updates.
- **Table Patterns**:
  - Sortable headers with custom components.
  - Color-coded rows for status (e.g., green for active, red for deleted).
  - Clickable rows for navigation with event propagation handling.
  - Hover effects and loading states.
- **Navigation**:
  - Single-level main navigation with subsections for restricted areas.
  - Breadcrumb-style contextual navigation.
  - Logo as home link.
  - Minimize page loads: Use client-side updates (e.g., dynamic rendering, API calls) for list updates or filtering.
- **HTML Entities**: Use entities (e.g., `&apos;` for `'`) to avoid `react/no-unescaped-entities` errors.

### API Architecture
- **API Routes**: Use Next.js API routes.
- **Server Actions**: Prefer server actions for database operations.
- **Response Format**: Use `{ success: boolean, data?: any, error?: string }` pattern.
- **Error Handling**: Use try-catch with user-friendly error messages (e.g., `Failed to fetch user: Invalid ID`).
- **Validation**: Apply Zod schema validation on both client and server.

### File Organization
```
app/
├── api/               # API endpoints
├── admin/             # Restricted/admin pages
├── features/          # Core feature modules
└── history/           # Historical data views
components/
├── ui/               # Base UI components
├── forms/            # Form-related components
├── tables/           # Table components
├── charts/           # Visualization components
└── widgets/          # Third-party integrations
actions/              # Server-side actions
lib/
├── types.ts          # Type definitions
├── utils.ts          # Helper functions
├── validations.ts    # Validation schemas
└── db.ts             # Database client configuration
scripts/              # External scripts for integrations
db/                   # Database schema and migrations
templates/            # Configuration templates
logs/                 # Application logs
```

### Integration Patterns
- **External APIs**: Use scripts or abstractions for third-party integrations (e.g., fetch wrappers for REST APIs).
- **API Abstractions**: Create internal interfaces or adapters for external services to allow easy switching.
- **Configuration Templates**: Use JSON-based systems for customizable external widgets.
- **File Storage**: Use file system storage for configurations and logs.
- **Logging**: Control logging levels via environment variables (e.g., `LOG_LEVEL=DEBUG`).

### Development Best Practices
- **Type Safety**: Enforce strict TypeScript; avoid `any` types.
- **Component Patterns**: Prefer server components; use client components only for interactivity.
- **Error Boundaries**: Implement error boundaries with user-friendly messages.
- **Loading States**: Display indicators for async operations (e.g., spinners, progress bars).
- **Responsive Design**: Use Tailwind's responsive classes for mobile-friendly layouts.
- **Accessibility**: Follow WCAG 2.1, use semantic HTML, and include ARIA attributes (e.g., `aria-label` for buttons, `role="alert"` for notifications).
- **Automation**: Use ESLint for linting and Prettier for code formatting.

### Internationalization (i18n) Guidelines
- **URL-based Language Routing**: Use Next.js App Router's built-in internationalization with URL segments for SEO optimization (e.g., `/en/about`, `/es/about`, `/fr/about`).
- **No Dynamic Language Switching**: Avoid client-side language switching that doesn't change URLs - each language must have its own URL for proper SEO indexing.
- **Folder Structure**: Organize pages by language using Next.js `[locale]` dynamic segments:
  ```
  app/
  ├── [locale]/
  │   ├── page.tsx          # Homepage for each locale
  │   ├── about/
  │   │   └── page.tsx      # /en/about, /es/about, etc.
  │   └── layout.tsx        # Locale-specific layout
  └── layout.tsx            # Root layout
  ```
- **Translation Files**: Store translations in JSON files organized by locale (e.g., `locales/en.json`, `locales/es.json`, `locales/fr.json`).
- **Translation Library**: Use `next-intl` or similar for type-safe translations with namespace support.
- **Language Detection**: Implement server-side language detection based on:
  1. URL segment (highest priority)
  2. `Accept-Language` header
  3. User preferences from database/cookies
  4. Default fallback language
- **Metadata**: Generate locale-specific metadata for each page including `hreflang` tags, localized titles, and descriptions.
- **Redirects**: Implement proper redirects from root paths to localized paths (e.g., `/` → `/en/` or user's preferred language).
- **Sitemap**: Generate separate sitemaps for each language or include all localized URLs in a single sitemap with proper `hreflang` annotations.

## Deployment Considerations
- **Platform**: Target serverless platforms like Vercel for hosting.
- **Build Optimization**: Use Next.js static generation and serverless functions for fast builds.
- **Environment Configuration**: Set up environment variables in the deployment platform for secrets and configs.
- **Monitoring**: Enable Vercel Analytics and integrate Sentry for error tracking and performance metrics.
- **Backup and Rollback**: Create database backups before migrations and maintain rollback scripts.
- **Scaling**: Leverage auto-scaling for traffic handling; optimize database connections for serverless environments.
- **Domain and SSL**: Use platform tools for custom domains and automatic SSL certificates.
