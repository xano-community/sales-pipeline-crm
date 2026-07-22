# AGENTS.md — editing this template's XanoScript backend

This template is meant to be **forked into a Xano workspace and read in the visual builder**, so the
backend (`backend/**/*.xs`) is documented as it's written. If you (human or agent) edit the XanoScript,
follow these two conventions — they're what keep the forked workspace legible.

## 1. Describe everything

Add `description = "…"` **everywhere it is a functional property** — it renders as the object's or step's
description in the Xano builder:

- **Every construct** — `function`, `query` (endpoint), `table` (+ every schema field except the auto
  `id` / `created_at` / `updated_at`), `api_group`. Function/query descriptions are a **single line**,
  placed as the first property inside the block.
- **Every `group { }` block** (see §2).
- **Every description-bearing statement** in a `stack` — `db.*` (get/query/add/patch/delete/…), `var`,
  `var.update`, `function.run`, `api.request`, `foreach` / `for` / `while` / `switch`, `throw`,
  `try_catch`. Put the `description` as the **first line** inside the statement's `{ }`.

**Exception — `precondition` and `conditional` have no `description` property.** Document them with a
`//` comment on the line directly above the block instead.

```xs
db.get "deal" {
  description = "Load the deal being advanced"
  field_name = "id"
  field_value = $input.deal_id
} as $deal

// Reps can only advance one stage; managers may jump
precondition ($me.role == "manager" || $target.sort_order == $current.sort_order + 1) {
  error_type = "accessdenied"
  error = "Reps can only advance one stage at a time"
}
```

Table fields: a simple field gains a trailing `{ description = "…" }`; a field that already has a `{ }`
block (FK `table =`, `enum` `values`) gains a `description` line as the first entry.

```xs
text name filters=trim { description = "Deal name" }
int account_id {
  description = "Account this deal is being sold to"
  table = "account"
}
```

Descriptions must be **specific and true to what the code does**, in the CRM domain voice (Salesforce
analogues where useful — deal ≈ Opportunity, `expected_revenue` ≈ ExpectedRevenue). No generic filler
("Get data", "Update record").

## 2. Group related / repeated logic

When several steps form **one logical unit** (a lookup → guard → history-write → update sequence) or a
**repeated pattern** (seeding one entity type; one phase of a long analytics stack), wrap them in a
`group { }`. This mirrors how a domain expert reads the flow as folders in the builder.

**Group syntax (common mistakes):**
- A group takes **no string label** — `group "Validate access" { }` is a **parse error**; the label goes
  in `description`.
- A group **requires an inner `stack { }`**.
- **Every group needs a `description`.**

```xs
// Validate the actor can advance this deal
group {
  description = "Validate access"
  stack {
    // Only the deal owner or a manager can advance it
    precondition ($me.role == "manager" || $deal.owner_id == $me.id) {
      error_type = "accessdenied"
      error = "You do not own this deal"
    }
  }
}

group {
  description = "Record the stage transition"
  stack {
    db.add "deal_stage_history" { description = "Append a history row for the move" data = { … } } as $hist
    db.patch "deal" { description = "Move the deal to the new stage" field_name = "id" field_value = $deal.id data = { … } } as $updated
  }
}
```

**Group when:** several steps mean one thing, a repeated block (seed section, forecast bucket), or a
distinct phase of a long stack. **Don't group** a lone statement or a stack of only 1–3 statements, and
don't nest deeper than one level unless a phase genuinely has sub-phases. Variables set inside a group
remain accessible after it (groups are organizational, not a new scope), and `response = …` stays at the
construct's top level, outside any group.

## 3. Validate before you commit

Every `.xs` must parse, and every construct / group / field / statement must be described:

```bash
# syntax — via the Xano developer MCP tool
xano_validate_xanoscript(directory: "backend")

# documentation gate (from the xano-community-hub checkout)
node scripts/check-descriptions.mjs <this-slug> --strict   # must report 0 errors
```

`--strict` treats a missing description on any field or statement as an error, not just constructs and
groups. Fix and re-run until clean. Descriptions and groups are **metadata/organizational only** — they
never change runtime behavior — but they must be present and valid before shipping.
