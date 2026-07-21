# Sales Pipeline CRM

A custom Salesforce alternative for deal management, built entirely on Xano. Reps and managers work opportunities through a stage pipeline — with stage-driven probability, expected revenue, forecast categories, activities, stage history, and lead conversion — over a Kanban board and a forecast dashboard. Self-contained: it ships its own seed data and runs end to end with no Salesforce account or third-party credentials.

## Why this exists

Sales teams pay per seat for Salesforce to do the core of deal management — a stage pipeline, weighted forecasting, activity tracking, and lead conversion — yet the logic that drives those numbers is locked inside a system you don't own and can't easily change. When you want a different stage model, a custom rotting-deal rule, or forecasting your own way, you're fighting the platform.

This template rebuilds that core as transparent Xano logic you own outright. Every Salesforce-mirrored behavior — how probability follows the stage, how ExpectedRevenue is computed, how forecast categories roll up, how stage history is recorded, how a lead converts — is a plain XanoScript function or endpoint you can read and edit. It's a working starting point for a CRM you control, not a black box, and it's modeled on Salesforce's *documented* behavior (sources below), not reverse-engineered from a live org.

## How it works

The pipeline itself is data, not code: a `pipeline_stage` table holds the ten standard Salesforce opportunity stages, each with a default probability, a forecast category, and `is_closed`/`is_won` flags — so you reshape the pipeline by editing rows, exactly as an admin edits the Opportunity Stage picklist in Salesforce. The Salesforce-mirrored logic lives in small, testable pieces:

- **Stage-driven probability.** Advancing a deal snapshots the target stage's default probability onto the deal; a rep can override it. Salesforce Probability is *"implied, but not directly controlled, by the StageName field… you can override this field"* ([Opportunity object reference](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunity.htm)).
- **Expected revenue.** `expected_revenue = amount × probability / 100`, recomputed on every stage/probability change — Salesforce's `ExpectedRevenue`, *"a read-only field that is equal to the product of the opportunity Amount field and the Probability"* ([same reference](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunity.htm)).
- **Forecast categories + rollup.** Each stage maps to a forecast category (Pipeline, Best Case, Commit, Omitted, Closed); the dashboard reports the cumulative columns — Open Pipeline = Pipeline+Best Case+Commit, Commit = Commit+Closed, etc. — as unweighted amounts ([Forecast category mapping](https://help.salesforce.com/s/articleView?id=sales.faq_forecasts_category_mapping.htm&language=en_US&type=5), [cumulative rollup methods](https://help.salesforce.com/s/articleView?id=sales.forecasts3_cumulative_columns_overview.htm&language=en_US&type=5)).
- **Guarded transitions + stage history.** Reps advance one stage at a time (managers may jump); each move writes a `deal_stage_history` row with days-in-previous-stage — Salesforce's `OpportunityHistory`, where *"anytime a user changes the Amount, Probability, Stage, or Close Date… a new entry is added"* ([OpportunityHistory reference](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunityhistory.htm)). `IsClosed`/`IsWon` are set by moving to the won/lost stage, mirroring how those flags are *"directly controlled by StageName"* in Salesforce.
- **Attention alerts.** Each open card surfaces the three Salesforce Kanban alerts — an overdue task, no open activities, or no activity for 30 days ([Kanban view](https://help.salesforce.com/s/articleView?id=sf.kanban_use.htm&language=en_US&type=5)) — driven by the `activity` table and each deal's rolled-up `last_activity_at` (the most recent completed activity due date).
- **Lead conversion.** Converting a lead creates/links an account, a contact, and (optionally) an opportunity, then flags the lead converted with the created record ids — Salesforce's `convertLead` ([convertLead API](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_convertlead.htm)).
- **Quota attainment.** Per-rep closed-won vs a monthly/quarterly quota, bucketed into Salesforce Collaborative Forecasts' color bands — grey 0%, red 1–33%, orange 34–66%, green 67%+ ([forecast quotas](https://help.salesforce.com/s/articleView?id=sales.forecasts3_quotas_intro.htm&language=en_US&type=5)).

**Honest caveat on the numbers.** Salesforce does not publish an exact default probability for every stage; only a subset appears in its documentation. The seeded stage probabilities follow Salesforce's documented example mapping plus the commonly-cited defaults — in a real Salesforce org these are configurable data, not fixed constants.

## Quick start

1. Create a Xano workspace and import this template's `backend/` export (or fork the repo and push it).
2. Load the demo data with one call:
   ```bash
   curl -X POST "https://<your-instance>.xano.io/api:salescrm-seed/seed"
   ```
3. Open `frontend/index.html` in a browser. On first load it asks for your Xano instance base URL (e.g. `https://<your-instance>.xano.io`).
4. Sign in as a seeded user — `morgan.lee@northwind.example` (manager) or `alex.chen@northwind.example` (rep), password `DemoPass1` — and work the Pipeline, Leads, and Forecast views.

## API surface

**`api:salescrm-auth`** — authentication

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/signup` | Register a rep or manager; returns an auth token. |
| `POST` | `/login` | Log in by email + password. |
| `GET` | `/me` | The authenticated user's profile (incl. quota). |

**`api:salescrm-crm`** — accounts, contacts, leads, stages, deals, roles, activities

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/accounts` | List accounts (scoped by role). |
| `POST` | `/accounts` | Create an account. |
| `GET` | `/contacts` | List contacts (optional account filter). |
| `POST` | `/contacts` | Create a contact. |
| `GET` | `/leads` | List leads (optional status filter). |
| `POST` | `/leads` | Create a lead. |
| `POST` | `/leads/{lead_id}/convert` | Convert a lead into account + contact + opportunity. |
| `GET` | `/stages` | The pipeline stage definitions, in order. |
| `GET` | `/board` | Kanban board: stages with deals + attention alerts. |
| `GET` | `/deals` | List deals (scoped, with stage/status filters). |
| `POST` | `/deals` | Create a deal (probability snapshots from the stage). |
| `GET` | `/deals/{deal_id}` | Deal detail: roles, activities, stage history. |
| `POST` | `/deals/{deal_id}/advance` | Guarded stage transition (logs stage history). |
| `POST` | `/deals/{deal_id}/won` | Close the deal as Won. |
| `POST` | `/deals/{deal_id}/lost` | Close the deal as Lost (requires a reason). |
| `POST` | `/deals/{deal_id}/contact-roles` | Attach a contact to a deal with a role. |
| `POST` | `/deals/{deal_id}/contact-roles/{role_id}/primary` | Mark a contact role primary. |
| `POST` | `/deals/{deal_id}/activities` | Log an activity on a deal. |
| `POST` | `/activities/{activity_id}/complete` | Complete an activity (updates last-activity). |

**`api:salescrm-analytics`** — pipeline analytics

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/dashboard/stats` | Forecast rollups, win rate, pipeline-by-stage, leaderboard. |
| `GET` | `/forecast` | Per-rep quota attainment. |

**`api:salescrm-seed`** — demo data

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/seed` | Idempotent demo-data loader (no auth). |
| `GET` | `/health` | Reachability check for the seed group. |

## Database Tables

- **user** — sales reps and managers (role flag + monthly/quarterly quota); the auth table.
- **account** — companies, owned by a user.
- **contact** — people at an account.
- **lead** — inbound leads with status/rating and the converted-record ids after conversion.
- **pipeline_stage** — the ten Salesforce opportunity stages: order, default probability, forecast category, and closed/won flags.
- **deal** — opportunities: amount, snapshot probability, expected revenue, stage, forecast category, status, and rolled-up last-activity date.
- **opportunity_contact_role** — the many-to-many link of contacts to a deal, with a role and a primary flag.
- **deal_stage_history** — one row per stage change (from/to stage, snapshots, days in previous stage) — the audit trail behind velocity metrics.
- **activity** — logged calls, emails, meetings, and tasks (open vs. completed) that drive the timeline and attention alerts.

## Testing

The core deal logic lives in reusable functions (`create_deal`, `advance_deal`, `win_deal`, `lose_deal`, `convert_lead`) that the endpoints wrap as thin, auth-checking shells — so the tests exercise exactly the code path the API runs. The template ships its tests in `backend/`:

- **Unit tests** — embedded `test` blocks on the pure functions cover the math: expected-revenue, the cumulative forecast rollup, the quota color bands, the three Kanban alerts, and the day counter. Run with `xano unit_test run_all`.
- **Workflow tests** (`backend/workflow_test/`) — end-to-end flows against the seeded data through the shared logic functions: the full deal lifecycle (create → advance → win, asserting the probability snapshot, forecast category, and that a stage-history row is written at each step), the forecast rollup plus lead conversion, and the rep stage-skip guardrail. Run with `xano workflow_test run_all`.
- **Live smoke** — every published GET endpoint is checked reachable over HTTP after deploy.
- **HTTP integration test** (`tests/api_smoke.py`) — a black-box Python script that hits every endpoint over real HTTP with real auth tokens (the layer the XanoScript tests can't reach), asserting authentication + negatives, manager/rep role scoping, the deal math, the stage-skip guard and cross-owner 403, won/lost effects, one-primary-contact enforcement, lead conversion, and the analytics response shapes. Run it after loading the seed: `python3 tests/api_smoke.py https://your-instance.xano.io`.

All tests run unattended in a fresh workspace — this is a self-contained template, so no credentials are required.

## Seed data

`POST /api:salescrm-seed/seed` is idempotent (safe to call repeatedly — every row is guarded by a natural-key lookup). It loads the 10 standard stages, 5 users (a manager + four reps with quotas, password `DemoPass1`), 10 accounts, 12 contacts, 5 leads, and 20 deals spread across stages and owners — including already-won and lost deals, deliberately stale deals that trip the attention alerts, plus activities, stage history, and contact roles — so the board, dashboard, and forecast are populated the moment you open the app. It's also what the workflow tests load in setup.

## Frontend

`frontend/index.html` is a single self-contained file (no build step, no external dependencies). It prompts for your instance base URL on first load, stores the auth token in `localStorage`, and drives the real endpoints: a **Kanban board** with advance/won/lost actions and the attention-alert badges, a **deal drawer** with contact roles, an activity timeline, and stage history, a **Leads** view with one-click conversion, and a **Forecast** dashboard with the cumulative forecast columns, win rate, pipeline-by-stage, and the quota-attainment leaderboard.
