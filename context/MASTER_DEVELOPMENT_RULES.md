# MASTER_DEVELOPMENT_RULES.md

> **Purpose:** This is the master development context and rulebook for this repository.
>
> It is intended for AI coding agents, developers, reviewers, and maintainers.
>
> **Read this file before planning, coding, refactoring, testing, reviewing, or shipping changes.**
>
> This document is technology-agnostic and applies to mobile apps, web apps, backend services, APIs, databases, cloud services, integrations, admin panels, dashboards, and production systems.

---

# 1. Golden Rule

**Understand the existing system before changing it.**

Do not start coding immediately.

Before making any change:

1. Read the task completely.
2. Read this file.
3. Read relevant project-specific documentation.
4. Inspect the relevant files.
5. Understand the current architecture.
6. Understand the current user flow.
7. Understand the current backend/data flow.
8. Search for existing implementations.
9. Identify dependencies and affected callers.
10. Identify security, database, API, and migration impact.
11. Decide the smallest complete implementation.
12. Only then modify code.

The goal is not to generate the most code.

The goal is to make the **smallest complete, correct, secure, maintainable, tested change** that fits the existing product.

---

# 2. Instruction Priority

When instructions conflict, use the following order unless the repository defines a stricter hierarchy:

1. Security and data integrity
2. Explicit current task requirements
3. Approved project requirements/specifications
4. Existing API/data contracts
5. Existing architecture
6. This master development rules file
7. Framework conventions
8. Agent/developer preference

Do not silently reinterpret a major requirement.

If a conflict materially affects architecture, security, data, or user experience, surface it clearly.

---

# 3. Mandatory Pre-Coding Inspection

Before editing code, inspect the relevant system.

Check:

- Folder/module structure
- Existing architecture
- State management
- Routing/navigation
- Dependency injection
- Models/entities
- API clients
- Services
- Repositories/data sources
- Controllers/providers/hooks
- Database schema
- Migrations
- Authentication flow
- Authorization model
- Role/permission rules
- Storage rules
- Environment configuration
- Existing components/widgets
- Design system
- Tests
- Lint/static-analysis configuration
- Build configuration
- Deployment configuration
- Existing similar features

Do not create new code before checking whether the same responsibility already exists.

---

# 4. Inspect Before Edit

## DO

- Read relevant files before editing.
- Trace imports and references.
- Search for existing functions/components/services before creating new ones.
- Understand how data enters and leaves the affected feature.
- Understand who calls the code being changed.
- Check tests for the affected feature.
- Check whether the task changes stored data.
- Check whether the task changes API contracts.
- Check whether the task changes permissions.
- Check whether the task requires backend enforcement.
- Preserve existing working behavior unless the requirement explicitly changes it.
- Make focused, reviewable changes.

## DON'T

- Rewrite a file because rewriting feels easier.
- Replace architecture casually.
- Delete code because it looks unused without checking references.
- Create duplicate helpers, services, components, screens, models, or endpoints.
- Guess field names, routes, environment variables, package APIs, or database structure.
- Assume a feature is frontend-only when it requires backend logic.
- Change unrelated behavior.
- Perform broad cleanup unrelated to the requested task.
- Hide incomplete work behind placeholders.

---

# 5. Respect Existing Architecture

Follow the existing architecture unless a change has been explicitly approved.

Maintain consistency in:

- Folder structure
- Naming conventions
- State management
- Dependency injection
- Navigation/routing
- API/service layers
- Repository patterns
- Model serialization
- Error handling
- Logging
- Database access
- Testing style
- UI components
- Design system
- Theming
- Localization
- Configuration

Do not introduce a second architectural pattern for the same responsibility without a strong reason.

If the architecture contains a genuine defect, fix it narrowly and explain the impact.

---

# 6. Scope Discipline

Implement the requested task completely without unnecessary expansion.

## Rules

- Separate required work from optional improvements.
- Avoid unrelated refactors.
- Avoid unnecessary renames.
- Avoid unnecessary API changes.
- Avoid unnecessary database changes.
- Preserve backwards compatibility where practical.
- Document breaking changes.
- Do not change UX flows without a requirement.
- Do not replace functioning code simply because another style is preferred.
- Do not add speculative features.
- Do not add placeholder code and call the feature finished.

A feature is not complete just because the UI exists.

If it requires backend logic, persistence, permissions, payments, storage, notifications, subscriptions, search, sync, or data validation, those layers must also be implemented or explicitly reported as missing.

---

# 7. Backend Is the Source of Truth

Never rely on the frontend alone for security or important business rules.

The trusted backend must enforce, where applicable:

- Authentication
- Authorization
- Ownership
- Roles
- Permissions
- Subscription status
- Premium entitlement
- Payment verification
- Pricing
- Discounts
- Usage limits
- Quotas
- Sensitive business rules
- Data access boundaries
- Admin-only actions
- Protected state transitions
- Resource ownership
- Input validation

## Never trust client-provided values such as

- User ID
- Role
- `isAdmin`
- `isPremium`
- Payment success
- Price
- Discount
- Subscription state
- Ownership
- Permission flags
- Usage counters

The UI may display trusted state, but it must not create authority.

---

# 8. Authentication

For protected functionality:

- Require authenticated sessions.
- Validate authentication server-side.
- Handle expired sessions.
- Handle revoked sessions.
- Handle invalid tokens.
- Never assume a client is authenticated because a screen is hidden.
- Never treat stored local state as sufficient proof of authentication.

Authentication proves identity.

It does not automatically prove permission.

---

# 9. Authorization

Every protected action must verify permission in a trusted layer.

Check:

- Who is making the request
- Which resource is being accessed
- Whether the user owns the resource
- Whether the user has the required role
- Whether the operation is allowed
- Whether tenant/workspace boundaries are respected

## Mandatory rules

- Protect admin routes.
- Enforce role checks server-side.
- Enforce ownership server-side.
- Follow least privilege.
- Prevent predictable-ID data leaks.
- Test protected endpoints as low-privilege users.
- Do not use hidden buttons as authorization.
- Do not trust frontend user IDs.

---

# 10. Multi-Tenant and User Data Isolation

If the app contains user-specific, organization-specific, team-specific, or tenant-specific data:

- Scope every query correctly.
- Prevent cross-user data access.
- Prevent cross-tenant data access.
- Verify ownership on reads.
- Verify ownership on writes.
- Verify ownership on deletes.
- Verify ownership on exports.
- Verify ownership on file access.

Never trust a client-supplied tenant ID without validating membership.

---

# 11. Secrets and Environment Variables

## NEVER

- Hardcode secrets.
- Commit private API keys.
- Commit database credentials.
- Commit service-role keys.
- Commit signing secrets.
- Commit passwords.
- Commit real `.env` files.
- Put server-only secrets in frontend/mobile code.
- Print secrets in logs.
- Include secrets in screenshots or test fixtures.

## ALWAYS

- Use environment variables.
- Use secure secret-management systems where available.
- Provide `.env.example` with placeholders only when useful.
- Add secret files to `.gitignore`.
- Separate public client configuration from server-only secrets.
- Rotate exposed credentials.
- Review Git history after suspected secret leakage.

Compiled, minified, or obfuscated client code is not a secure place for secrets.

---

# 12. Git History and Secret Leakage

If a secret was committed:

1. Treat it as compromised.
2. Rotate/revoke it.
3. Remove it from current code.
4. Clean repository history when necessary.
5. Re-check deployment configuration.
6. Check logs and CI output.
7. Check whether the secret was included in distributed builds.

Deleting a secret from the latest commit does not automatically remove it from repository history.

---

# 13. Database Security

- Use least-privilege database accounts.
- Restrict public access.
- Apply row-level/document-level security where supported.
- Use ownership checks.
- Use constraints.
- Use indexes appropriately.
- Avoid unrestricted public writes.
- Avoid unrestricted public reads of private data.
- Protect sensitive tables.
- Protect admin data.
- Avoid direct client database access unless the platform's security model explicitly supports it safely.

---

# 14. Firebase, Supabase, and Cloud Storage

When using managed backend/storage platforms:

- Configure security rules/policies explicitly.
- Never assume default rules are safe.
- Use least privilege.
- Protect user files.
- Protect private buckets.
- Validate user access.
- Validate resource ownership.
- Prevent unauthenticated writes unless intentionally public.
- Prevent mass reads of private data.
- Keep service-role or admin keys server-side.
- Test policies with unauthorized users.

Frontend visibility is not a security boundary.

---

# 15. Database Migrations

For schema changes:

1. Inspect current models.
2. Inspect existing migrations.
3. Create proper migrations.
4. Consider existing records.
5. Add safe defaults when required.
6. Add indexes where needed.
7. Add constraints where business rules require them.
8. Avoid destructive changes unless explicitly approved.
9. Plan data backfills where required.
10. Verify rollback/recovery options when practical.
11. Update models, APIs, validation, tests, and docs together.

Never claim a database-backed feature is complete when required migration work is missing.

---

# 16. Data Integrity

Use database constraints for important invariants where possible.

Examples:

- Uniqueness
- Foreign keys
- Required relationships
- Allowed states
- Non-null requirements
- Valid ranges

Do not rely solely on UI validation for data integrity.

Use transactions when multiple related operations must succeed or fail together.

---

# 17. API Contracts

Follow existing API conventions.

Check:

- Request shape
- Response shape
- Status codes
- Authentication
- Authorization
- Validation
- Pagination
- Error format
- Versioning
- Backwards compatibility

Do not casually change shared API contracts.

If a breaking API change is necessary:

- Identify affected clients.
- Update them together.
- Document the change.
- Version when appropriate.

---

# 18. API Error Responses

API errors should be:

- Consistent
- Useful
- Sanitized
- Safe

Do not expose:

- Stack traces
- SQL
- Database credentials
- Filesystem paths
- Secret keys
- Infrastructure internals
- Private configuration

Log technical detail securely on the server where appropriate.

Return user-safe messages to clients.

---

# 19. Input Validation

Treat every external input as untrusted.

Sources include:

- Forms
- Query parameters
- Route parameters
- API payloads
- Headers
- Cookies
- Uploaded files
- CSV/Excel imports
- Webhooks
- Third-party APIs
- User-generated content
- Client-provided IDs

Validate:

- Type
- Format
- Length
- Range
- Required fields
- Allowed values
- Ownership
- Permission
- File type
- File size
- Business rules

Client validation improves UX.

Server validation protects the system.

---

# 20. Injection Prevention

Protect against attacks relevant to the stack, including:

- SQL injection
- NoSQL injection
- Command injection
- XSS
- HTML injection
- Path traversal
- Template injection
- Header injection
- Unsafe deserialization

Use:

- Parameterized queries
- Safe ORM APIs
- Output encoding
- Sanitization
- Strict parsing
- Allow-lists where appropriate

Do not concatenate untrusted input into executable queries or commands.

---

# 21. File Upload Security

When supporting file uploads:

- Restrict allowed file types.
- Validate actual content/type.
- Enforce file-size limits.
- Use safe filenames.
- Prevent path traversal.
- Prevent executable uploads in unsafe locations.
- Store private files privately.
- Restrict access.
- Avoid exposing internal paths.
- Safely parse malformed files.
- Scan when the risk model requires it.

Do not trust file extensions alone.

---

# 22. Authentication Abuse Protection

Apply rate limits and abuse controls to sensitive endpoints such as:

- Login
- Signup
- Password reset
- OTP
- Email verification
- Search
- Expensive API calls
- Account recovery
- Invitation endpoints

Use lockout, throttling, CAPTCHA, device checks, or similar controls where justified.

Do not accidentally create denial-of-service vulnerabilities through overly expensive unauthenticated endpoints.

---

# 23. CORS and Security Headers

For web APIs/applications:

- Restrict CORS to required origins.
- Restrict allowed methods.
- Restrict allowed headers.
- Avoid permissive production wildcards unless intentionally required and safe.
- Add appropriate security headers.
- Review CSP where applicable.
- Use HTTPS in production.
- Configure secure cookies where applicable.

Do not expose internal services unnecessarily.

---

# 24. Production Debugging

Before shipping:

- Disable production debug mode.
- Disable verbose stack traces to users.
- Disable debug banners.
- Remove development-only endpoints.
- Remove temporary debug tools.
- Remove test credentials.
- Remove mock bypasses.
- Remove insecure development configuration.

Logs may remain, but they must not leak secrets or sensitive user data.

---

# 25. Dependencies

Before adding a package:

1. Check whether an existing dependency already solves the problem.
2. Confirm the package is actually needed.
3. Prefer actively maintained packages.
4. Check compatibility.
5. Consider security history.
6. Consider bundle/build impact.
7. Consider licensing when relevant.
8. Use the project's package manager.
9. Preserve the lockfile.
10. Avoid unrelated upgrades.

Do not add a large dependency for trivial functionality.

Do not invent package APIs.

Verify against the installed version or authoritative documentation when necessary.

---

# 26. Third-Party Services

For any third-party service:

- Understand why it is required.
- Store credentials securely.
- Handle failures.
- Handle timeouts.
- Handle retries.
- Respect rate limits.
- Validate responses.
- Verify webhook signatures where supported.
- Avoid leaking unnecessary user data.
- Review privacy impact.
- Document required configuration.

Never assume external services are always available.

---

# 27. Payments and Premium Features

For payments, subscriptions, purchases, or premium entitlements:

## Backend authority

- Payment provider/backend is the source of truth.
- Never unlock premium solely from client state.
- Verify payment server-side.
- Verify subscription status server-side.
- Verify webhook authenticity.
- Store provider transaction/subscription IDs safely.
- Reconcile local entitlement with provider state.

## Handle all relevant states

- Pending
- Succeeded
- Failed
- Cancelled
- Refunded
- Expired
- Renewed
- Grace period
- Chargeback/dispute where applicable

## Security

- Do not trust client-supplied price.
- Do not trust client-supplied plan entitlement.
- Do not trust client-supplied payment success.
- Keep payment secret keys server-side.
- Use idempotency for retryable payment operations.
- Handle duplicate webhook callbacks safely.

---

# 28. Webhooks

For webhook endpoints:

- Verify signature/authenticity.
- Validate event type.
- Validate payload.
- Use idempotency.
- Handle duplicate delivery.
- Handle out-of-order delivery.
- Log safely.
- Avoid returning sensitive details.
- Respond fast enough to avoid unnecessary retries.
- Queue expensive follow-up work where architecture supports it.

Never trust a webhook simply because it reached the endpoint.

---

# 29. Error Handling

Every asynchronous user-facing flow should consider:

- Loading
- Success
- Empty state
- Recoverable error
- Permission denied
- Authentication failure
- Network failure
- Timeout
- Offline state
- Partial failure
- Retry

## Rules

- Never swallow important errors silently.
- Do not expose internal stack traces.
- Do not show raw SQL/database errors.
- Do not show secret/internal configuration.
- Provide actionable messages.
- Log enough technical context for developers.
- Avoid logging sensitive user data.
- Do not report success before the operation succeeds.
- Roll back optimistic UI when the backend rejects the operation.

---

# 30. Loading States

Do not leave users wondering whether the app is working.

Use appropriate:

- Progress indicators
- Skeleton loaders
- Disabled action states
- Inline loading states
- Retry actions

Avoid:

- Infinite spinners without failure handling
- Blocking the entire UI for small operations
- Repeated submissions while a request is active

---

# 31. Empty States

Empty states should explain:

- Why nothing is shown
- Whether this is expected
- What the user can do next

Do not show broken-looking blank screens.

---

# 32. Offline and Network Failure

Where relevant:

- Detect failed network operations.
- Preserve user-entered data when practical.
- Provide retry.
- Distinguish offline from server failure where useful.
- Avoid misleading success messages.
- Queue operations only when the architecture safely supports it.

---

# 33. UI/UX Quality Standard

Build interfaces intentionally for the product.

Do not default to generic AI-template design.

## Avoid blindly using

- Purple gradients
- Harsh gradients
- Purple-and-black default themes
- Neon/rainbow decoration
- Radial glowing orbs
- Dot grids
- Excessive drop shadows
- Excessive glass/liquid-glass effects
- Excessive pill-shaped controls
- Emoji as primary UI icons when proper icons exist
- Sparkle icons as generic AI decoration
- Cursor animations
- Excessive hover animations
- Excessive scroll animation
- Animated arrows used decoratively
- Bento layouts without information-architecture justification
- Repetitive three-feature-card sections just because they are common
- Decorative terminal windows with no product purpose
- Generic pastel palettes without brand reasoning
- Generic AI-style marketing layouts
- Unedited AI-generated copy
- AI-generated imagery when real product imagery is expected
- Default font choices solely because AI tools frequently use them

These are not universal bans.

Use any pattern when it genuinely fits the product, brand, accessibility needs, and design system.

The rule is: **do not blindly generate a recognizable template instead of designing the product.**

---

# 34. Product-Specific Design

Prefer:

- Clear visual hierarchy
- Consistent spacing
- Consistent typography
- Consistent component behavior
- Real product screenshots
- Real product demos
- Purposeful interactions
- Clear navigation
- Responsive layouts
- Minimal useful animation
- Existing design-system components
- Brand-specific visual identity
- Predictable interaction patterns

Do not introduce a new visual language into one screen while the rest of the product follows another.

---

# 35. Responsive Design

Where relevant, verify:

- Mobile
- Tablet
- Desktop
- Small screens
- Large screens
- Portrait
- Landscape

Do not fix one viewport by breaking another.

Avoid hardcoded dimensions when responsive layout techniques are appropriate.

---

# 36. Accessibility

Accessibility is part of completion.

Check:

- Semantic structure
- Accessible labels
- Alt text
- Color contrast
- Keyboard navigation
- Visible focus
- Logical focus order
- Form labels
- Validation messages
- Touch target size
- Screen-reader support
- Text scaling
- Reduced motion
- Clear link/button labels

Do not communicate critical meaning using color alone.

Do not make keyboard users depend on a mouse.

---

# 37. Forms

Forms should:

- Have visible/accessible labels.
- Validate inputs clearly.
- Show useful error messages.
- Preserve user-entered values when safe.
- Prevent accidental duplicate submission.
- Use correct input types.
- Use clear button labels.
- Communicate required fields.
- Request only necessary data.

Do not use vague buttons such as “Submit” where a specific action name is clearer.

---

# 38. Content Integrity

Never fabricate trust signals.

## Do not invent

- Reviews
- Testimonials
- Customer names
- Logos
- User counts
- Revenue
- Success rates
- Ratings
- Usage statistics
- Performance claims
- Security certifications
- Awards
- Partner relationships
- “Trusted by” claims
- Customer counters
- Fake social proof

Use:

- Real approved content
- Clearly marked demo/sample data
- Neutral placeholders

Never present sample/demo content as real.

---

# 39. Copy Quality

Avoid:

- Vague hero copy
- Meaningless buzzwords
- Repetitive AI-style phrasing
- Unedited AI output
- False claims
- Overuse of em dashes if it makes the copy feel machine-generated
- Formulaic phrases like “it’s not X, it’s Y” unless genuinely appropriate

Prefer direct, specific, product-relevant language.

Explain what the product actually does.

---

# 40. Images and Media

- Use legally permitted media.
- Respect copyright.
- Provide alt text where appropriate.
- Optimize image sizes.
- Avoid unnecessary huge assets.
- Prefer authentic product media when available.
- Do not use AI-generated “stock-like” visuals simply to fill space.
- Do not add “Made with AI” style decorative tags unless the product genuinely requires them.

---

# 41. Branding

Where applicable, verify:

- Product/app name
- Logo
- App icon
- Favicon
- Theme
- Brand colors
- Typography
- Metadata
- Social preview images
- Store listing assets

Avoid shipping default framework branding.

---

# 42. Website Essentials

For production websites, check:

- Custom domain
- Favicon
- Correct page title
- Metadata
- Responsive layout
- Accessibility
- Privacy page
- Terms page
- Cookie handling when needed
- Contact/business information where appropriate
- Error pages
- Secure HTTPS deployment

---

# 43. Privacy

Collect only data needed for a legitimate product purpose.

Check:

- What data is collected
- Why it is collected
- Where it is stored
- Who can access it
- How long it is retained
- How users can delete/export it
- Which third parties receive it
- Whether tracking is used
- Whether consent is needed

Do not collect unnecessary personal information.

---

# 44. Legal and Compliance

Where applicable, review requirements for:

- Privacy Policy
- Terms & Conditions / Terms of Service
- Cookie Policy
- Cookie consent
- Refund/cancellation policy
- Form consent
- Tracking disclosure
- Third-party embeds
- Business details
- Image/media copyright
- Data retention
- Data deletion
- Applicable privacy laws
- DPDP requirements when relevant

Do not claim legal compliance solely because a page or checkbox exists.

Flag questions requiring project-owner or legal review.

---

# 45. Cookies and Tracking

If cookies or tracking are used:

- Identify which are necessary.
- Identify which are analytics/marketing.
- Obtain consent where required.
- Avoid loading non-essential trackers before consent when applicable.
- Provide clear policy information.
- Respect withdrawal where required.

Do not silently add analytics or marketing trackers.

---

# 46. Third-Party Embeds

Before adding embeds:

- Check privacy implications.
- Check performance impact.
- Check cookie/tracking behavior.
- Check CSP implications.
- Check mobile behavior.
- Check accessibility.
- Confirm the embed is actually needed.

---

# 47. Performance

Avoid obvious regressions.

Review:

- Unnecessary network requests
- Duplicate API calls
- N+1 database queries
- Unbounded queries
- Missing pagination
- Repeated expensive computation
- Excessive rerenders/rebuilds
- Oversized assets
- Memory leaks
- Unnecessary polling
- Large dependency additions
- Blocking UI work
- Poor caching

Do not optimize blindly.

Measure or reason from real bottlenecks.

Correctness and security come before micro-optimization.

---

# 48. Caching

Use caching intentionally.

Consider:

- Cache lifetime
- Staleness
- Invalidation
- User isolation
- Sensitive data
- Offline behavior
- Realtime updates
- Server authority

Never allow cached authorization/payment/subscription state to become the only source of truth for protected actions.

---

# 49. Search

For search features:

- Avoid unnecessary requests.
- Debounce live search where appropriate.
- Use server-side pagination for large datasets.
- Protect private data.
- Enforce search permissions.
- Rate-limit expensive/public search when appropriate.
- Avoid exposing hidden records through search.

---

# 50. Logging

Logs should help debug systems without exposing sensitive data.

Do not log:

- Passwords
- Tokens
- Private keys
- Payment credentials
- Full authentication headers
- Sensitive personal data unnecessarily

Use structured logging when the project supports it.

Include correlation/request IDs when useful.

---

# 51. Monitoring and Observability

For production systems, consider:

- Error tracking
- Uptime monitoring
- Performance monitoring
- Audit logs
- Security events
- Failed job monitoring
- Webhook failure monitoring
- Payment reconciliation

Monitoring should respect user privacy.

---

# 52. Background Jobs

When using queues/jobs:

- Make jobs retry-safe.
- Make important jobs idempotent.
- Handle poison/failing jobs.
- Avoid silent infinite retries.
- Record failures.
- Protect job payloads.
- Avoid putting secrets in exposed queues/logs.

---

# 53. Concurrency

When multiple requests can modify the same resource:

- Consider race conditions.
- Use database constraints.
- Use transactions.
- Use optimistic/pessimistic locking where appropriate.
- Make retryable operations idempotent.

Do not assume users cannot click twice or two processes cannot run simultaneously.

---

# 54. Notifications

For notifications:

- Respect user preferences.
- Avoid duplicate sends.
- Protect private content.
- Handle invalid tokens/endpoints.
- Avoid leaking sensitive information in lock-screen previews where inappropriate.
- Record delivery state only when useful.

---

# 55. Email

For transactional email:

- Use server-side sending.
- Keep provider secrets server-side.
- Validate recipient data.
- Prevent abuse/spam.
- Handle provider failures.
- Avoid exposing sensitive information unnecessarily.
- Use unsubscribe mechanisms for marketing where required.

---

# 56. Admin Features

Admin systems require stronger controls.

- Explicitly protect admin routes.
- Use role/permission checks.
- Log sensitive administrative actions where appropriate.
- Require confirmation for destructive operations.
- Avoid exposing admin APIs to normal users.
- Test as a non-admin.
- Prefer least privilege over a single unrestricted admin role.

---

# 57. Destructive Actions

For deletes/resets/destructive operations:

- Verify authentication.
- Verify authorization.
- Confirm intent where UX requires it.
- Consider soft delete where product requirements justify it.
- Prevent accidental bulk deletion.
- Preserve referential integrity.
- Provide recovery/rollback where feasible.

---

# 58. Dependency on Frontend State

Do not trust:

- Disabled buttons
- Hidden screens
- Route guards
- Local storage flags
- Client-calculated roles
- Client-calculated payment state
- Client-side quotas

These improve UX but do not replace backend enforcement.

---

# 59. Build Configuration

Before release, verify:

- Production environment variables
- Release mode
- Signing configuration
- API endpoints
- Build variants/flavors
- Feature flags
- Debug flags
- Logging level
- App/package identifiers
- Version numbers
- Platform permissions

Do not ship development endpoints or test credentials.

---

# 60. Environment Separation

Keep environments separate:

- Development
- Testing
- Staging
- Production

Avoid sharing production credentials with development.

Avoid test data entering production.

Avoid development webhooks calling production systems.

---

# 61. Feature Flags

Use feature flags when appropriate for risky or staged releases.

Rules:

- Do not use client-only feature flags for security.
- Remove obsolete flags.
- Define defaults.
- Test both states when important.
- Keep flag ownership clear.

---

# 62. Configuration

Configuration should be:

- Explicit
- Documented
- Environment-aware
- Validated at startup where appropriate

Fail fast for missing critical server configuration.

Do not fail silently and continue with insecure defaults.

---

# 63. Testing Strategy

A change is not complete until verified.

Use project-appropriate checks such as:

- Formatting
- Linting
- Static analysis
- Type checking
- Unit tests
- Component/widget tests
- Integration tests
- API tests
- Backend tests
- Migration checks
- Build/compile
- Manual smoke testing

---

# 64. Test Quality

## DO

- Test important new behavior.
- Test relevant failure paths.
- Test authorization boundaries.
- Test validation.
- Test edge cases.
- Test regressions.
- Run focused tests while developing.
- Run broader relevant suites before finishing.

## DON'T

- Delete tests just to make CI pass.
- Weaken assertions to hide bugs.
- Skip security tests for protected features.
- Claim tests passed if they were not run.

---

# 65. Regression Prevention

Before completion:

1. Re-test the changed flow.
2. Test adjacent flows.
3. Verify navigation.
4. Verify imports.
5. Verify APIs.
6. Verify model compatibility.
7. Verify persistence.
8. Verify auth/permissions.
9. Verify loading/error states.
10. Verify no duplicate implementation was introduced.
11. Review the diff.
12. Run relevant automated checks.

A new feature that breaks an existing feature is not complete.

---

# 66. Git Safety

## DO

- Keep changes focused.
- Review the diff.
- Respect `.gitignore`.
- Preserve unrelated user changes.
- Use meaningful commits when asked.

## DON'T

- Force reset without explicit approval.
- Discard unrelated work.
- Rewrite Git history casually.
- Commit secrets.
- Commit temporary debug output.
- Commit build artifacts unless expected.
- Modify unrelated files just to “clean things up.”
- Claim a commit/push occurred unless it actually occurred.

---

# 67. Refactoring

Refactor when it improves the requested change or fixes a real structural issue.

Do not refactor only for stylistic preference.

Before refactoring:

- Understand callers.
- Preserve public behavior.
- Add/update tests.
- Keep scope manageable.
- Avoid combining major refactors with unrelated features.

---

# 68. Code Quality

Prefer code that is:

- Clear
- Simple
- Testable
- Consistent
- Maintainable
- Explicit
- Secure

Avoid:

- Cleverness without benefit
- Deep duplication
- Giant functions
- Hidden side effects
- Magic values
- Unclear naming
- Premature abstraction
- Overengineering

---

# 69. Comments

Comments should explain **why**, not restate obvious code.

Use comments for:

- Non-obvious business rules
- Security decisions
- Workarounds
- External constraints
- Complex algorithms

Remove stale comments.

Do not use comments to excuse broken architecture.

---

# 70. TODOs

Do not leave TODOs for required task behavior unless the limitation is explicitly accepted.

Every TODO should be:

- Specific
- Actionable
- Necessary

Do not use TODOs as substitutes for implementation.

---

# 71. Documentation

Update documentation when changing:

- Setup
- Environment variables
- API contracts
- Database schema
- Migrations
- Architecture
- Permissions
- External services
- Build/deployment
- User-visible documented behavior

Documentation must match reality.

Do not document features that do not exist.

---

# 72. README and Setup

If setup changes:

- Update prerequisites.
- Update environment variables.
- Update commands.
- Update migration steps.
- Update local development instructions.
- Update deployment notes.

A new developer should not have to guess required setup.

---

# 73. Project-Specific Requirements

Project-specific requirements should live in dedicated files where practical.

Examples:

- `PRODUCT_REQUIREMENTS.md`
- `ARCHITECTURE.md`
- `API_CONTRACTS.md`
- `DATABASE_SCHEMA.md`
- `DESIGN_SYSTEM.md`
- `SECURITY.md`
- `DEPLOYMENT.md`

This master file defines general rules.

Project-specific documents define product-specific behavior.

---

# 74. AI Agent Behavior

Any AI coding agent working in this repository must:

1. Read this file.
2. Read project-specific context.
3. Inspect the implementation.
4. Search before creating.
5. Preserve architecture.
6. Keep scope controlled.
7. Use trusted backend enforcement.
8. Protect secrets and data.
9. Test the implementation.
10. Report truthfully.

---

# 75. Agent Must Not Guess

Do not guess important details such as:

- Database schema
- API fields
- Environment variable names
- Existing routes
- Existing user roles
- Permission structure
- Package APIs
- External service behavior
- Existing migration state

Investigate first.

For small implementation details that can safely follow existing patterns, use the codebase as the source of truth.

---

# 76. Agent Must Not Fake Completion

Never claim:

- “Implemented” when only planned.
- “Fixed” when not verified.
- “Tested” when tests were not run.
- “Build passes” when build was not run.
- “No errors” without checking.
- “Secure” because the UI hides something.
- “Production ready” when known blockers remain.
- “Deployed” when deployment did not occur.
- “Committed” when no commit occurred.
- “Pushed” when no push occurred.

Report exact reality.

---

# 77. Agent Must Not Silently Ignore Errors

If commands/tests fail:

- Read the error.
- Determine whether it was introduced by the task.
- Fix task-related errors.
- Clearly report unrelated pre-existing failures.
- Do not hide or suppress them without reason.

---

# 78. Agent Must Preserve User Work

Never discard existing uncommitted changes that belong to the user or another developer.

Before destructive Git operations:

- Inspect status.
- Understand what would be lost.
- Get explicit approval when required.

---

# 79. Agent Must Avoid Unnecessary Questions

Do not block on trivial implementation choices that can be resolved safely from:

- Existing project patterns
- Existing requirements
- Existing architecture
- Existing code

Ask only when uncertainty is materially important and cannot be resolved safely.

---

# 80. Agent Must Not Change Requirements

Do not silently:

- Remove requirements
- Simplify requirements
- Change user flows
- Change security rules
- Change data models
- Change business logic

If the requested implementation conflicts with reality, explain the conflict.

---

# 81. Required Coding Workflow

## Phase A — Understand

- Read task.
- Read instructions.
- Inspect code.
- Search existing implementation.
- Identify affected layers.
- Identify security impact.
- Identify data impact.
- Identify API impact.
- Identify migration impact.
- Define the smallest complete solution.

## Phase B — Implement

- Follow architecture.
- Make focused changes.
- Implement all required layers.
- Handle failures.
- Handle edge cases.
- Preserve existing behavior.
- Add/update tests.

## Phase C — Verify

- Format.
- Lint/analyze.
- Type-check.
- Run tests.
- Build/compile where appropriate.
- Smoke-test the changed flow.
- Review the diff.
- Check regressions.
- Check security boundaries.

## Phase D — Report

Report:

1. What changed
2. Files/components changed
3. Backend changes
4. Database changes
5. API changes
6. Migration changes
7. Tests/checks run
8. Actual test results
9. Config/env changes
10. Remaining risks/limitations

---

# 82. Mandatory Pre-Coding Checklist

Before editing:

- [ ] I understand the requested outcome.
- [ ] I read the relevant existing implementation.
- [ ] I searched for duplicate/existing functionality.
- [ ] I understand affected callers and dependencies.
- [ ] I understand the existing architecture.
- [ ] I know which layer should enforce the behavior.
- [ ] I checked authentication impact.
- [ ] I checked authorization impact.
- [ ] I checked database/schema impact.
- [ ] I checked migration impact.
- [ ] I checked API impact.
- [ ] I checked external-service impact.
- [ ] I checked privacy/security impact.
- [ ] I will preserve existing architecture unless change is necessary.
- [ ] I will not hardcode secrets.
- [ ] I will not trust client state for protected operations.
- [ ] I know how I will verify the result.

---

# 83. UI Completion Checklist

For UI-related tasks:

- [ ] Matches product design system
- [ ] Responsive
- [ ] Accessible
- [ ] Correct loading state
- [ ] Correct error state
- [ ] Correct empty state
- [ ] Correct disabled state
- [ ] Clear labels
- [ ] No fake content
- [ ] No accidental generic AI-template styling
- [ ] Real product behavior rather than decorative placeholders
- [ ] Theme support where applicable
- [ ] Keyboard support where applicable
- [ ] Screen-reader labels where applicable

---

# 84. Backend Completion Checklist

For backend-related tasks:

- [ ] Authentication enforced
- [ ] Authorization enforced
- [ ] Ownership/tenant boundaries enforced
- [ ] Input validated
- [ ] Errors sanitized
- [ ] Sensitive values not logged
- [ ] Database queries safe
- [ ] Rate limits considered
- [ ] Transactions considered
- [ ] Idempotency considered
- [ ] Tests added/updated
- [ ] API contracts documented if changed

---

# 85. Database Completion Checklist

For database-related tasks:

- [ ] Schema change reviewed
- [ ] Migration created
- [ ] Existing data considered
- [ ] Constraints considered
- [ ] Indexes considered
- [ ] Ownership/security rules reviewed
- [ ] Backfill considered
- [ ] Rollback/recovery considered
- [ ] Models updated
- [ ] Tests updated

---

# 86. Security Completion Checklist

Before shipping:

- [ ] No hardcoded secrets
- [ ] `.env` protected
- [ ] Git history checked if leakage suspected
- [ ] Auth enforced
- [ ] Permissions enforced server-side
- [ ] Frontend user IDs not trusted
- [ ] User/tenant data isolated
- [ ] Admin routes protected
- [ ] Database/storage locked down
- [ ] Production debug disabled
- [ ] Detailed errors hidden
- [ ] Inputs validated server-side
- [ ] User content safely handled
- [ ] Uploads secured
- [ ] Injection protections present
- [ ] CORS restricted
- [ ] Security headers considered
- [ ] Login/signup abuse protections considered
- [ ] Tested as an untrusted user

---

# 87. Website Quality Completion Checklist

For websites:

- [ ] Custom domain configured where required
- [ ] Favicon present
- [ ] Accessibility checked
- [ ] Images have alt text where needed
- [ ] Color contrast checked
- [ ] Forms keyboard-friendly
- [ ] Button labels are clear
- [ ] False claims removed
- [ ] Fake metrics removed
- [ ] Fake reviews removed
- [ ] Vague hero copy removed
- [ ] Excessive decorative animation avoided
- [ ] Generic AI-looking patterns avoided
- [ ] Privacy Policy provided where required
- [ ] Terms provided where required
- [ ] Cookie policy/consent handled where required
- [ ] Refund policy handled where required
- [ ] Form consent handled where required
- [ ] Tracking reviewed
- [ ] Third-party embeds reviewed
- [ ] Necessary-data principle followed
- [ ] Copyright reviewed
- [ ] Applicable privacy law reviewed

---

# 88. Payments Completion Checklist

For payment/subscription features:

- [ ] Provider/backend is source of truth
- [ ] Premium cannot be unlocked client-only
- [ ] Payment verification is server-side
- [ ] Webhook signature verified
- [ ] Webhook handling idempotent
- [ ] Duplicate events handled
- [ ] Subscription lifecycle states handled
- [ ] Refund/cancellation handled
- [ ] Entitlement stored safely
- [ ] Secret credentials server-side
- [ ] Client cannot control trusted prices
- [ ] Failed/pending payment UX handled
- [ ] Tests cover critical states

---

# 89. Mandatory Final Completion Checklist

Before reporting completion:

- [ ] Requested behavior is actually implemented.
- [ ] No placeholder is presented as finished functionality.
- [ ] Backend enforcement exists where required.
- [ ] Authentication was considered.
- [ ] Authorization was considered.
- [ ] User/tenant isolation was considered.
- [ ] Input validation exists in the trusted layer.
- [ ] Secrets are not exposed.
- [ ] Database/schema changes are complete where required.
- [ ] Migrations are complete where required.
- [ ] Loading/error/empty/offline states are handled where relevant.
- [ ] UI follows the design system.
- [ ] Accessibility was considered.
- [ ] No fake metrics/reviews/content were introduced.
- [ ] Relevant tests were added/updated.
- [ ] Formatter/linter/analyzer/type checker was run where available.
- [ ] Relevant tests were run.
- [ ] Build/compile was checked where appropriate.
- [ ] Regression risk was reviewed.
- [ ] Diff contains no accidental unrelated changes.
- [ ] Documentation/configuration was updated when needed.
- [ ] Final report reflects actual verification results.

---

# 90. Definition of Done

A task is **DONE** only when all applicable conditions are satisfied:

- Required behavior exists.
- Required backend logic exists.
- Required database changes exist.
- Required migrations exist.
- Authentication/authorization are correct.
- Input validation is correct.
- Relevant errors are handled.
- UI states are complete.
- Accessibility is reasonable.
- No known regression was introduced.
- Relevant tests pass.
- Build/analysis checks pass or unrelated failures are clearly reported.
- Documentation/configuration is updated.
- No secret/security issue was introduced.
- Completion report is truthful.

If any required part is missing, the task is not fully done.

---

# 91. Final Agent Report Template

At the end of a coding task, report using this structure:

## Implemented

- What changed
- Main user-visible behavior
- Backend/data behavior

## Files Changed

- Relevant files/modules only

## Backend / API

- Endpoints/services changed
- Authorization/validation changes

## Database

- Models/schema/migrations changed
- Backfill or migration instructions

## Security

- Important security controls added/verified

## Verification

- Formatter:
- Linter/analyzer/type-check:
- Unit tests:
- Integration tests:
- Build:
- Manual smoke test:

Include the actual result of each check.

## Configuration

- New environment variables
- External-service setup
- Deployment changes

## Remaining Issues

- Known limitations
- Pre-existing failures
- Follow-up work

Do not omit known failures.

---

# 92. Short Version for Agents

Before coding:

**Read → Inspect → Search → Understand → Plan → Implement → Verify → Report**

Never:

- Guess architecture
- Duplicate existing code
- Trust client state for security
- Hardcode secrets
- Fake reviews/metrics/content
- Add generic AI-template design blindly
- Ignore accessibility
- Skip backend enforcement
- Skip validation
- Hide test failures
- Claim work you did not verify
- Destroy unrelated user changes

Always:

- Preserve working behavior
- Use trusted backend checks
- Protect data
- Follow existing patterns
- Keep changes focused
- Test relevant behavior
- Review the diff
- Report truthfully

---

# 93. Final Principle

**Understand first. Change intentionally. Keep trusted logic on trusted systems. Protect user data. Build product-specific interfaces. Test the real behavior. Report only what was actually completed.**

This file is the default development rulebook for the repository unless a stricter project-specific requirement overrides it.
