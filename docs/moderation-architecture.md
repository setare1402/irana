# IRANA Trust & Safety — Technical Architecture

Status: **Mandatory product requirement**
Scope: Flutter client + future API service + PostgreSQL + human moderation console.
Compatibility rule: preserve the existing Flutter app structure and introduce moderation incrementally. Do not rewrite the current app or connect UI to mock enforcement.

## 1. Non-negotiable requirements

IRANA must provide:
- User-submitted reports for posts, comments, stories, messages, profiles, and accounts.
- AI-assisted detection and prioritization for text, images, video, spam, and suspicious behavior.
- Human review for consequential moderation decisions.
- Warnings, scoped temporary restrictions, temporary suspension, and account bans.
- A user appeal path with independent review where practical.
- Append-only administrative audit history for every staff action and every change to a moderation decision.
- Role-based staff permissions and least-privilege access.
- User-facing explanation, duration, and appeal availability for enforcement actions, except where disclosure would create a concrete safety or abuse risk.

AI must not autonomously impose permanent bans. Automated systems may classify, score, deduplicate, prioritize, and apply narrowly scoped temporary safety holds only under an explicitly approved policy with human review and an appeal route.

## 2. Current repository baseline and integration boundary

The inspected branch is `feature/safe-localization`.
The Flutter app currently uses local persistence (including SharedPreferences) for parts of its social data. No `backend/main.py` or `backend/requirements.txt` was present on this branch at inspection time.

Therefore:
- This document defines the future server contract; it does not claim server-side moderation is already running.
- Do not treat local-only reports or local flags as authoritative enforcement.
- Until the API exists, any client-only report feature must be clearly labelled as a prototype and must not claim that a report was delivered to moderators.
- Existing navigation, theme, localization, and social flows must remain intact. Add new screens/routes in isolated files and connect them through the existing app entry points only after API contracts are ready.

## 3. Logical architecture

```text
Flutter IRANA app
  |-- Report flow / My reports / Account status / Appeal flow
  |-- authenticated HTTPS API
        |
        +-- Identity & access control
        +-- Reports service
        +-- Moderation case queue
        +-- Enforcement service
        +-- Appeals service
        +-- Audit service (append-only)
        +-- AI adapter (provider-independent)
        |
        +-- PostgreSQL
        +-- private media/object storage
        +-- background job queue (AI scans, notifications, expiry)
        
Moderator web console
  |-- report queue / AI flags / case details
  |-- warnings, restrictions, suspensions, bans
  |-- appeals / audit trail / staff roles
```

The AI adapter must be replaceable. The core API and database must not depend on a specific AI vendor.

## 4. Core data model (PostgreSQL)

Use UUID primary keys, UTC timestamps, foreign keys, indexes, and migrations. Keep report evidence and moderation decisions separate.

### `moderation_reports`
- `id` UUID PK
- `reporter_user_id` UUID FK
- `target_type` enum: `post`, `comment`, `story`, `message`, `profile`, `account`
- `target_id` UUID/string identifier
- `reason_code` enum: `spam`, `harassment`, `hate`, `violence`, `sexual_content`, `impersonation`, `scam`, `self_harm`, `child_safety`, `other`
- `details` nullable text, length-limited
- `status` enum: `received`, `triaged`, `under_review`, `actioned`, `dismissed`, `duplicate`
- `priority` enum: `low`, `normal`, `high`, `urgent`
- `created_at`, `updated_at`

### `moderation_cases`
- `id` UUID PK
- `target_type`, `target_id`
- `status`: `open`, `in_review`, `awaiting_user`, `resolved`, `reopened`
- `assigned_moderator_id` nullable FK
- `priority`, `created_at`, `resolved_at`
- Multiple reports and AI signals can be linked to one case to prevent duplicate handling.

### `moderation_signals`
- `id` UUID PK
- `case_id` UUID FK
- `source`: `ai_text`, `ai_image`, `ai_video`, `spam_rule`, `user_report`, `staff_review`
- `policy_code`, `confidence` numeric nullable
- `model_provider`, `model_version` nullable
- `evidence_reference` private storage reference, not a public URL
- `created_at`
- Store only evidence needed for review; restrict access and apply retention rules.

### `moderation_actions`
- `id` UUID PK
- `target_user_id` UUID FK
- `case_id` UUID FK nullable
- `action_type`: `warning`, `comment_restriction`, `message_restriction`, `posting_restriction`, `temporary_suspension`, `account_ban`, `restore`
- `scope` nullable (e.g. comments, messages, posting, all account access)
- `reason_code`, `public_reason`
- `starts_at`, `expires_at` nullable
- `issued_by_staff_id` nullable for explicitly approved automated action
- `status`: `active`, `expired`, `revoked`, `superseded`
- `created_at`

### `moderation_appeals`
- `id` UUID PK
- `action_id` UUID FK
- `user_id` UUID FK
- `appeal_text` length-limited
- `status`: `submitted`, `in_review`, `upheld`, `overturned`, `partially_overturned`
- `reviewer_staff_id` nullable
- `decision_reason` nullable
- `created_at`, `decided_at`
- Prevent repeated open appeals for the same action unless the policy permits new evidence.

### `moderation_audit_logs`
- `id` UUID PK
- `actor_type`: `staff`, `system`, `ai_service`
- `actor_id` nullable
- `event_type`, `object_type`, `object_id`
- `before_state` JSONB nullable, `after_state` JSONB nullable
- `reason`, `request_id`, `ip_hash` nullable
- `created_at`
- Append-only: application roles cannot update or delete audit rows. Sensitive evidence and secrets must never be copied into logs.

### Supporting tables
- `moderation_staff_roles`: staff user, role, granted_by, granted_at, revoked_at.
- `moderation_policy_versions`: versioned policy/rules and effective date.
- `user_restriction_cache` (optional): derived active restrictions for fast authorization checks; source of truth remains `moderation_actions`.

## 5. Roles and permissions

- Reporter/user: submit reports, view own report status where policy permits, see own active restrictions, submit appeals.
- Support agent: view limited account context and help with report/appeal navigation; cannot issue bans.
- Moderator: review assigned cases, dismiss reports, issue warnings and policy-approved scoped restrictions.
- Senior moderator: approve serious or long-duration restrictions and review appeals.
- Trust & Safety administrator: manage policy configuration and staff roles; sensitive actions require audit logging.
- System/AI service: create signals and queue cases; no unrestricted staff privileges.

Use server-side authorization on every endpoint. Hiding a button in Flutter is not access control. Require stronger authentication for staff accounts, rate limits, and session revocation.

## 6. Report and review lifecycle

1. User selects report reason and optionally adds a short explanation.
2. API validates the target, checks rate limits, stores the report, and returns a report reference.
3. Deduplication attaches related reports to an existing open case where appropriate.
4. Rules and AI adapter add signals and suggest priority; the suggestion is not a final finding.
5. Moderator reviews the relevant evidence and policy version.
6. Moderator dismisses, requests more context, or applies a proportionate action.
7. API records the action and audit event in one database transaction.
8. User receives a safe, concise notice and an appeal path when applicable.
9. Appeal is assigned for review; overturned decisions revoke or amend the action and append another audit event.

Emergency child-safety or credible imminent-harm reports must be routed to a specially restricted urgent queue and handled under a documented escalation policy. Do not expose sensitive evidence broadly.

## 7. Initial API contract (versioned)

All routes are under `/api/v1` and require HTTPS.

### User endpoints
- `POST /reports` — create a report.
- `GET /me/reports` — list the current user's reports and safe status fields.
- `GET /me/moderation-status` — active restrictions and expiry details.
- `POST /moderation-actions/{action_id}/appeals` — submit an appeal.
- `GET /me/appeals` — list the user's appeals.

### Staff endpoints
- `GET /staff/moderation/cases?status=&priority=&type=`
- `GET /staff/moderation/cases/{case_id}`
- `POST /staff/moderation/cases/{case_id}/assign`
- `POST /staff/moderation/cases/{case_id}/resolve`
- `POST /staff/moderation/actions`
- `GET /staff/moderation/appeals`
- `POST /staff/moderation/appeals/{appeal_id}/decision`
- `GET /staff/moderation/audit?object_id=&actor_id=&from=&to=`

Staff routes require role checks, audit events, pagination, and reason fields. Never expose internal AI confidence, private evidence URLs, reporter identity, or staff-only notes to ordinary users.

## 8. Enforcement rules

- Warnings: explain the policy and link to community standards.
- Scoped restrictions: restrict only the affected capability where possible; always record start and expiry.
- Temporary suspension: reserve for serious or repeated violations; include expiry and appeal details.
- Permanent account ban: require human review and senior approval, except a legally mandated emergency workflow defined by policy.
- Every restriction must be enforced by the API on the relevant write/action endpoints, not merely by disabling Flutter controls.
- Expiry must be enforced server-side even if a background worker is delayed.
- A successful appeal must immediately revoke or amend the corresponding active restriction.

## 9. Privacy, security, and abuse resistance

- Collect only the evidence necessary to assess the report.
- Encrypt transport; protect stored evidence; use private object storage and short-lived signed access.
- Restrict access to private messages and sensitive reports to specifically authorized reviewers, with access logged.
- Define retention/deletion schedules for reports, evidence, appeals, and audit records, subject to applicable legal obligations.
- Rate-limit reports, appeals, and staff actions; detect coordinated/report-spam abuse.
- Use idempotency keys for report creation and action submission.
- Prevent moderators from reviewing their own actions/appeals where feasible.
- Require reason codes and free-text rationale for consequential staff actions.
- Maintain policy version on each decision so later policy changes do not rewrite history.

## 10. AI integration policy

Initial rollout:
1. Human reporting and manual queue first.
2. Add AI text classification and spam signals in shadow/suggestion mode.
3. Add image classification with private evidence references.
4. Add video sampling/transcription only after privacy, storage, and cost controls are approved.
5. Measure false positives/false negatives by language and content type; include Persian, Arabic, and English evaluation before expanding.

AI output schema should be provider-neutral:
`{policy_code, confidence, model_provider, model_version, evidence_refs, suggested_priority}`.
AI must not infer a violation solely from protected identity, nationality, religion, political viewpoint, or other sensitive traits. Do not use AI confidence as the only basis for a severe penalty.

## 11. Delivery phases and acceptance criteria

### Phase A — foundation
- Confirm real backend location and existing authentication/database conventions.
- Create database migrations and role/permission checks.
- Implement report creation and staff case queue.
- Acceptance: report survives app restart and is visible to authorized staff across devices; unauthorized users cannot read it.

### Phase B — human moderation and enforcement
- Implement warnings, scoped restrictions, suspension, bans, user status and notifications.
- Acceptance: API blocks restricted actions; expiry works; each decision has a complete audit record.

### Phase C — appeals and audit console
- Implement appeal submission, review, outcomes, and searchable audit history.
- Acceptance: user can appeal; overturning a decision updates enforcement and adds audit events without erasing the original decision.

### Phase D — AI assistance
- Add provider-neutral adapter, shadow mode, reviewer feedback, and quality monitoring.
- Acceptance: AI suggestions are traceable to model/version; human review remains available; false-positive handling is tested.

### Phase E — Flutter integration
- Add isolated report, account-status, and appeal UI using the existing navigation/theme/localization conventions.
- Acceptance: existing home, search, create, videos, profile, messaging, and language selection continue to work; no local-only action is presented as server-confirmed.

## 12. Immediate next technical step

Before writing runtime code, inspect the repository's actual default branch and connected backend repository/service to identify the real API entry point, authentication mechanism, PostgreSQL schema, and deployment target. Do not create a second backend or database until this is confirmed. Then implement Phase A as a separate, reviewable change with migrations and tests.
