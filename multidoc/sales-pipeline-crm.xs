workspace templates {
  acceptance = {ai_terms: false}
  preferences = {
    internal_docs    : false
    track_performance: true
    sql_names        : false
    sql_columns      : true
  }
}
---
table "account" {
  auth = false
  schema {
    int id
    text name filters=trim
    text industry?
    text website?
    decimal annual_revenue?=0
    int owner_id {
      table = "user"
    }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
    {type: "btree", field: [{name: "name"}]}
  ]
  guid = "w1Qcu9Z7UO5m7cT6Zrd-y1Q9wuI"
}
---
table "activity" {
  auth = false
  schema {
    int id
    int deal_id? {
      table = "deal"
    }
    int contact_id? {
      table = "contact"
    }
    int owner_id {
      table = "user"
    }
    enum kind?="task" {
      values = ["task", "event"]
    }
    enum subtype?="task" {
      values = ["call", "email", "meeting", "task"]
    }
    text subject filters=trim
    text description?
    timestamp due_at?
    enum status?="not_started" {
      values = ["not_started", "in_progress", "completed", "waiting", "deferred"]
    }
    bool is_closed?=false
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "contact_id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
  ]
  guid = "uYgq8an0oFZiYAR_tgEzLJUXxVk"
}
---
table "contact" {
  auth = false
  schema {
    int id
    int account_id {
      table = "account"
    }
    text first_name filters=trim
    text last_name filters=trim
    email email? filters=trim|lower {
      sensitive = true
    }
    text phone?
    text title?
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "account_id"}]}
    {type: "btree", field: [{name: "email"}]}
  ]
  guid = "JA7D6tBo8I-8_YKvug4RPSjl_Yw"
}
---
table "deal_stage_history" {
  auth = false
  schema {
    int id
    int deal_id {
      table = "deal"
    }
    int from_stage_id? {
      table = "pipeline_stage"
    }
    int to_stage_id {
      table = "pipeline_stage"
    }
    decimal amount_snapshot?=0
    int probability_snapshot?=0
    int changed_by {
      table = "user"
    }
    int days_in_previous_stage?=0
    timestamp changed_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "changed_at", op: "desc"}]}
  ]
  guid = "hvjdp5FeYeqVPyktig2FDCPMqRc"
}
---
table "deal" {
  auth = false
  schema {
    int id
    text name filters=trim
    int account_id {
      table = "account"
    }
    int owner_id {
      table = "user"
    }
    decimal amount?=0
    int probability?=0
    decimal expected_revenue?=0
    int stage_id {
      table = "pipeline_stage"
    }
    enum forecast_category?="Pipeline" {
      values = ["Pipeline", "BestCase", "Commit", "Omitted", "Closed"]
    }
    timestamp close_date?
    timestamp actual_close_date?
    enum status?="open" {
      values = ["open", "won", "lost"]
    }
    bool is_closed?=false
    bool is_won?=false
    text lost_reason?
    text next_step?
    enum type?="new_business" {
      values = ["new_business", "existing_business"]
    }
    text lead_source?
    timestamp last_activity_at?
    timestamp created_at?=now
    timestamp updated_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "account_id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
    {type: "btree", field: [{name: "stage_id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
  guid = "cJQX-rebEWs0LMYI0CwRFSpUULE"
}
---
table "lead" {
  auth = false
  schema {
    int id
    text first_name filters=trim
    text last_name filters=trim
    text company filters=trim
    email email? filters=trim|lower {
      sensitive = true
    }
    text lead_source?
    enum status?="new" {
      values = ["new", "working", "nurturing", "qualified", "unqualified", "converted"]
    }
    enum rating?="warm" {
      values = ["hot", "warm", "cold"]
    }
    bool is_converted?=false
    int converted_account_id? {
      table = "account"
    }
    int converted_contact_id? {
      table = "contact"
    }
    int converted_opportunity_id? {
      table = "deal"
    }
    timestamp converted_at?
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "is_converted"}]}
  ]
  guid = "EnMJD5_d2hvY6MucccGwWSezxbs"
}
---
table "opportunity_contact_role" {
  auth = false
  schema {
    int id
    int deal_id {
      table = "deal"
    }
    int contact_id {
      table = "contact"
    }
    enum role?="influencer" {
      values = ["decision_maker", "economic_buyer", "technical_buyer", "influencer", "champion", "other"]
    }
    bool is_primary?=false
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "contact_id"}]}
  ]
  guid = "NvjWirgCv4wBAhRYUYY2CKXa5_A"
}
---
table "pipeline_stage" {
  auth = false
  schema {
    int id
    text name filters=trim
    int sort_order
    int default_probability?=0
    enum forecast_category?="Pipeline" {
      values = ["Pipeline", "BestCase", "Commit", "Omitted", "Closed"]
    }
    bool is_closed?=false
    bool is_won?=false
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "sort_order"}]}
    {type: "btree", field: [{name: "name"}]}
  ]
  guid = "1tALuWWTmSPHkIbcLxZsCgpxRUw"
}
---
table "user" {
  auth = true
  schema {
    int id
    text name filters=trim
    email email filters=trim|lower {
      sensitive = true
    }
    password password {
      sensitive = true
    }
    enum role?="rep" {
      values = ["rep", "manager"]
    }
    decimal quota_amount?=0
    enum quota_period?="monthly" {
      values = ["monthly", "quarterly"]
    }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "email"}]}
    {type: "btree", field: [{name: "role"}]}
  ]
  guid = "Gci5VlDnOKjjjmh4XFo4Q7I7dUs"
}
---
// Core guarded stage-transition logic (shared by the endpoint and the tests).
// Reps advance one stage forward at a time; managers may jump. Writes a
// deal_stage_history row (Salesforce OpportunityHistory) with days-in-previous-
// stage and re-snapshots probability + forecast category + expected revenue.
function "advance_deal" {
  description = "Advance a deal to another open stage with Salesforce-style guards and stage history."
  input {
    int deal_id
    int target_stage_id
    int actor_id
    text actor_role
    int probability?
  }
  stack {
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
    precondition ($input.actor_role == "manager" || $deal.owner_id == $input.actor_id) {
      error_type = "accessdenied"
      error = "You do not own this deal"
    }
    precondition ($deal.is_closed == false) {
      error_type = "inputerror"
      error = "Deal is already closed"
    }
    db.get "pipeline_stage" {
      field_name = "id"
      field_value = $input.target_stage_id
    } as $target
    precondition ($target != null) {
      error_type = "inputerror"
      error = "Unknown stage"
    }
    precondition ($target.is_closed == false) {
      error_type = "inputerror"
      error = "Use the won or lost action to close a deal"
    }
    db.get "pipeline_stage" {
      field_name = "id"
      field_value = $deal.stage_id
    } as $current
    conditional {
      if ($input.actor_role != "manager") {
        precondition ($target.sort_order > $current.sort_order) {
          error_type = "inputerror"
          error = "Reps can only move a deal forward"
        }
        precondition ($target.sort_order <= $current.sort_order + 1) {
          error_type = "inputerror"
          error = "Reps can't skip stages; advance one at a time"
        }
      }
    }
    db.query "deal_stage_history" {
      where = $db.deal_stage_history.deal_id == $input.deal_id
      sort = { changed_at: "desc" }
      return = { type: "single" }
    } as $last
    var $prev_ts { value = ($last == null ? $deal.created_at : $last.changed_at) }
    function.run "days_between" {
      input = { from_ts: $prev_ts, to_ts: now }
    } as $days
    var $prob { value = ($input.probability == null ? $target.default_probability : $input.probability) }
    function.run "calc_expected_revenue" {
      input = { amount: $deal.amount, probability: $prob }
    } as $er
    db.add "deal_stage_history" {
      data = {
        deal_id: $deal.id,
        from_stage_id: $deal.stage_id,
        to_stage_id: $target.id,
        amount_snapshot: $deal.amount,
        probability_snapshot: $prob,
        changed_by: $input.actor_id,
        days_in_previous_stage: $days,
        changed_at: now
      }
    }
    db.patch "deal" {
      field_name = "id"
      field_value = $deal.id
      data = {
        stage_id: $target.id,
        probability: $prob,
        expected_revenue: $er,
        forecast_category: $target.forecast_category,
        updated_at: now
      }
    } as $updated
  }
  response = $updated
  guid = "7br7FXg9a2JpHI8T_bdjC_lUYmI"
}
---
// Quota-attainment color band, mirroring Salesforce Collaborative Forecasts.
// Ref: help.salesforce.com forecasts3_quotas_intro - attainment is shown with
// color-coded progress (grey 0%, red 1-33%, orange 34-66%, green 67%+).
function "attainment_band" {
  description = "Maps a quota-attainment percentage to Salesforce's color band (grey/red/orange/green)."
  input {
    decimal pct
  }
  stack {
    var $band { value = "grey" }
    conditional {
      if ($input.pct >= 1 && $input.pct < 34) {
        var.update $band { value = "red" }
      }
    }
    conditional {
      if ($input.pct >= 34 && $input.pct < 67) {
        var.update $band { value = "orange" }
      }
    }
    conditional {
      if ($input.pct >= 67) {
        var.update $band { value = "green" }
      }
    }
  }
  response = { band: $band, pct: $input.pct }

  test "zero is grey" {
    input = { pct: 0 }
    expect.to_equal ($response.band) { value = "grey" }
  }
  test "twenty is red" {
    input = { pct: 20 }
    expect.to_equal ($response.band) { value = "red" }
  }
  test "fifty is orange" {
    input = { pct: 50 }
    expect.to_equal ($response.band) { value = "orange" }
  }
  test "eighty is green" {
    input = { pct: 80 }
    expect.to_equal ($response.band) { value = "green" }
  }
  guid = "tnYgfLgqpEIi3MLlcKgcFUzrgGk"
}
---
// Salesforce Opportunity.ExpectedRevenue = Amount * Probability.
// Ref: developer.salesforce.com Object Reference - Opportunity ("Read-only field
// that is equal to the product of the opportunity Amount field and the Probability").
function "calc_expected_revenue" {
  description = "Weighted expected revenue for a deal: amount * probability / 100 (Salesforce ExpectedRevenue)."
  input {
    decimal amount
    int probability
  }
  stack {
    var $expected { value = ($input.amount * $input.probability / 100)|round:2 }
  }
  response = $expected

  test "90% of 10000 is 9000" {
    input = { amount: 10000, probability: 90 }
    expect.to_equal ($response) { value = 9000 }
  }
  test "0% probability yields 0" {
    input = { amount: 50000, probability: 0 }
    expect.to_equal ($response) { value = 0 }
  }
  test "50% of 24000 is 12000" {
    input = { amount: 24000, probability: 50 }
    expect.to_equal ($response) { value = 12000 }
  }
  guid = "sF4_hwmYv_-f50ku5n3gV8XcfxY"
}
---
// Core lead-conversion logic (shared by the endpoint and the tests). Creates or
// links an account + contact and optionally an opportunity, then flags the lead
// converted with the created record ids — Salesforce convertLead.
function "convert_lead" {
  description = "Convert a lead into an account, contact, and optional opportunity (Salesforce convertLead)."
  input {
    int lead_id
    int actor_id
    bool create_opportunity?
    text opportunity_name?
    decimal amount?=0
    int stage_id?
  }
  stack {
    db.get "lead" {
      field_name = "id"
      field_value = $input.lead_id
    } as $lead
    precondition ($lead != null) {
      error_type = "notfound"
      error = "Lead not found"
    }
    precondition ($lead.is_converted == false) {
      error_type = "inputerror"
      error = "Lead is already converted"
    }
    db.get "account" {
      field_name = "name"
      field_value = $lead.company
    } as $account
    conditional {
      if ($account == null) {
        db.add "account" {
          data = { name: $lead.company, owner_id: $input.actor_id }
        } as $account
      }
    }
    db.add "contact" {
      data = {
        account_id: $account.id,
        first_name: $lead.first_name,
        last_name: $lead.last_name,
        email: $lead.email
      }
    } as $contact
    var $opp_id { value = null }
    conditional {
      if ($input.create_opportunity == true) {
        db.query "pipeline_stage" {
          where = $db.pipeline_stage.id ==? $input.stage_id
          sort = { sort_order: "asc" }
          return = { type: "single" }
        } as $stage
        var $prob { value = $stage.default_probability }
        function.run "calc_expected_revenue" {
          input = { amount: $input.amount, probability: $prob }
        } as $er
        db.add "deal" {
          data = {
            name: ($input.opportunity_name == null ? ($lead.company ~ " - New Opportunity") : $input.opportunity_name),
            account_id: $account.id,
            owner_id: $input.actor_id,
            amount: $input.amount,
            probability: $prob,
            expected_revenue: $er,
            stage_id: $stage.id,
            forecast_category: $stage.forecast_category,
            status: "open",
            is_closed: $stage.is_closed,
            is_won: $stage.is_won,
            lead_source: $lead.lead_source,
            updated_at: now
          }
        } as $deal
        db.add "deal_stage_history" {
          data = {
            deal_id: $deal.id,
            from_stage_id: null,
            to_stage_id: $stage.id,
            amount_snapshot: $input.amount,
            probability_snapshot: $prob,
            changed_by: $input.actor_id,
            days_in_previous_stage: 0,
            changed_at: now
          }
        }
        db.add "opportunity_contact_role" {
          data = { deal_id: $deal.id, contact_id: $contact.id, role: "decision_maker", is_primary: true }
        }
        var.update $opp_id { value = $deal.id }
      }
    }
    db.patch "lead" {
      field_name = "id"
      field_value = $input.lead_id
      data = {
        status: "converted",
        is_converted: true,
        converted_account_id: $account.id,
        converted_contact_id: $contact.id,
        converted_opportunity_id: $opp_id,
        converted_at: now
      }
    } as $updated_lead
  }
  response = {
    lead: $updated_lead,
    account: $account,
    contact: $contact,
    opportunity_id: $opp_id
  }
  guid = "NbfmhqZJ0zvvkjqmIKTjxCWbGD8"
}
---
// Core deal-creation logic (shared by the endpoint and the tests). Snapshots
// probability + forecast category from the stage (rep may override probability),
// computes ExpectedRevenue, and writes the opening stage-history row.
function "create_deal" {
  description = "Create a deal, snapshotting probability + forecast category from the stage and computing expected revenue."
  input {
    text name
    int account_id
    int owner_id
    int stage_id
    decimal amount?=0
    int probability?
    timestamp close_date?
    text next_step?
    text type?
    text lead_source?
  }
  stack {
    db.get "pipeline_stage" {
      field_name = "id"
      field_value = $input.stage_id
    } as $stage
    precondition ($stage != null) {
      error_type = "inputerror"
      error = "Unknown stage"
    }
    var $prob { value = ($input.probability == null ? $stage.default_probability : $input.probability) }
    function.run "calc_expected_revenue" {
      input = { amount: $input.amount, probability: $prob }
    } as $er
    db.add "deal" {
      data = {
        name: $input.name,
        account_id: $input.account_id,
        owner_id: $input.owner_id,
        amount: $input.amount,
        probability: $prob,
        expected_revenue: $er,
        stage_id: $stage.id,
        forecast_category: $stage.forecast_category,
        close_date: $input.close_date,
        status: "open",
        is_closed: $stage.is_closed,
        is_won: $stage.is_won,
        next_step: $input.next_step,
        type: ($input.type == null ? "new_business" : $input.type),
        lead_source: $input.lead_source,
        updated_at: now
      }
    } as $deal
    db.add "deal_stage_history" {
      data = {
        deal_id: $deal.id,
        from_stage_id: null,
        to_stage_id: $stage.id,
        amount_snapshot: $input.amount,
        probability_snapshot: $prob,
        changed_by: $input.owner_id,
        days_in_previous_stage: 0,
        changed_at: now
      }
    }
  }
  response = $deal
  guid = "m3IfJohNyrTIUDVzXTf2pCinnTg"
}
---
// Whole days between two epoch-millisecond timestamps (floored).
// Used to record days_in_previous_stage on each stage transition (Salesforce
// OpportunityHistory records a new entry on every stage change).
function "days_between" {
  description = "Whole days between two epoch-millisecond timestamps, floored (never negative)."
  input {
    int from_ts
    int to_ts
  }
  stack {
    var $diff { value = $input.to_ts - $input.from_ts }
    conditional {
      if ($diff < 0) {
        var.update $diff { value = 0 }
      }
    }
    var $days { value = ($diff / 86400000)|floor }
  }
  response = $days

  test "one day" {
    input = { from_ts: 0, to_ts: 86400000 }
    expect.to_equal ($response) { value = 1 }
  }
  test "three days" {
    input = { from_ts: 0, to_ts: 259200000 }
    expect.to_equal ($response) { value = 3 }
  }
  test "negative clamps to zero" {
    input = { from_ts: 86400000, to_ts: 0 }
    expect.to_equal ($response) { value = 0 }
  }
  guid = "QKAYINFhML0h1218szeFc32DkVA"
}
---
// The three Salesforce Opportunity Kanban attention alerts.
// Ref: help.salesforce.com kanban_use - "three types of alerts: overdue tasks,
// no open activities, or no activity for 30 days." Closed deals never alert.
function "deal_alerts" {
  description = "Computes the three Salesforce Kanban attention flags for a deal."
  input {
    bool is_closed
    bool has_overdue_task
    bool has_open_activity
    int reference_days
  }
  stack {
    var $overdue { value = false }
    var $no_open { value = false }
    var $stale { value = false }
    conditional {
      if ($input.is_closed == false) {
        var.update $overdue { value = $input.has_overdue_task }
        var.update $no_open { value = ($input.has_open_activity == false) }
        var.update $stale { value = ($input.reference_days >= 30) }
      }
    }
    var $needs { value = ($overdue || $no_open || $stale) }
  }
  response = {
    overdue_task: $overdue,
    no_open_activities: $no_open,
    no_activity_30_days: $stale,
    needs_attention: $needs
  }

  test "closed deal never alerts" {
    input = { is_closed: true, has_overdue_task: true, has_open_activity: false, reference_days: 100 }
    expect.to_be_false ($response.needs_attention)
  }
  test "overdue task flags attention" {
    input = { is_closed: false, has_overdue_task: true, has_open_activity: true, reference_days: 2 }
    expect.to_be_true ($response.overdue_task)
    expect.to_be_true ($response.needs_attention)
  }
  test "no open activity and stale both flag" {
    input = { is_closed: false, has_overdue_task: false, has_open_activity: false, reference_days: 45 }
    expect.to_be_true ($response.no_open_activities)
    expect.to_be_true ($response.no_activity_30_days)
  }
  test "healthy open deal is calm" {
    input = { is_closed: false, has_overdue_task: false, has_open_activity: true, reference_days: 3 }
    expect.to_be_false ($response.needs_attention)
  }
  guid = "Bc41-5JxDLaRwbMCgctQN6zsXDc"
}
---
// Cumulative, unweighted forecast rollup by Salesforce Forecast Category.
// Ref: help.salesforce.com forecasts3_cumulative_columns_overview -
//   Open Pipeline = Pipeline + Best Case + Commit
//   Best Case Forecast = Best Case + Commit + Closed
//   Commit Forecast = Commit + Closed
//   Closed Only = Closed
// Category rollups are raw (unweighted) amounts. `weighted_expected` is the
// separate probability-weighted ExpectedRevenue sum over open deals.
function "forecast_rollup" {
  description = "Cumulative unweighted forecast rollup by Salesforce forecast category, plus a weighted expected-revenue total."
  input {
    json deals
  }
  stack {
    var $pipeline { value = 0 }
    var $best { value = 0 }
    var $commit { value = 0 }
    var $closed { value = 0 }
    var $weighted { value = 0 }
    foreach ($input.deals) {
      each as $d {
        conditional {
          if ($d.forecast_category == "Pipeline") {
            var.update $pipeline { value = $pipeline + $d.amount }
          }
        }
        conditional {
          if ($d.forecast_category == "BestCase") {
            var.update $best { value = $best + $d.amount }
          }
        }
        conditional {
          if ($d.forecast_category == "Commit") {
            var.update $commit { value = $commit + $d.amount }
          }
        }
        conditional {
          if ($d.forecast_category == "Closed") {
            var.update $closed { value = $closed + $d.amount }
          }
        }
        conditional {
          if ($d.status == "open") {
            var.update $weighted { value = $weighted + ($d.amount * $d.probability / 100) }
          }
        }
      }
    }
  }
  response = {
    pipeline: $pipeline,
    best_case: $best,
    commit: $commit,
    closed: $closed,
    open_pipeline: ($pipeline + $best + $commit),
    best_case_forecast: ($best + $commit + $closed),
    commit_forecast: ($commit + $closed),
    closed_only: $closed,
    weighted_expected: $weighted|round:2
  }

  test "cumulative rollup matches Salesforce columns" {
    input = { deals: [
      { forecast_category: "Pipeline", amount: 10000, probability: 10, status: "open" },
      { forecast_category: "BestCase", amount: 20000, probability: 70, status: "open" },
      { forecast_category: "Commit",   amount: 30000, probability: 90, status: "open" },
      { forecast_category: "Closed",   amount: 40000, probability: 100, status: "won" }
    ] }
    expect.to_equal ($response.open_pipeline) { value = 60000 }
    expect.to_equal ($response.commit_forecast) { value = 70000 }
    expect.to_equal ($response.best_case_forecast) { value = 90000 }
    expect.to_equal ($response.closed_only) { value = 40000 }
  }
  test "weighted expected counts only open deals" {
    input = { deals: [
      { forecast_category: "Commit", amount: 10000, probability: 90, status: "open" },
      { forecast_category: "Closed", amount: 50000, probability: 100, status: "won" }
    ] }
    expect.to_equal ($response.weighted_expected) { value = 9000 }
  }
  guid = "NAPwaANiiiNRk_rSx6WqxjHGpWY"
}
---
// Core close-as-Lost logic (shared by the endpoint and the tests). Requires a
// reason; moves the deal to the is_lost stage, probability 0, forecast Omitted
// (Salesforce requires Closed/Lost stages to map to Omitted). Idempotent.
function "lose_deal" {
  description = "Close a deal as Lost with a reason (lost stage, probability 0, omitted). Idempotent."
  input {
    int deal_id
    int actor_id
    text actor_role
    text lost_reason
  }
  stack {
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
    precondition ($input.actor_role == "manager" || $deal.owner_id == $input.actor_id) {
      error_type = "accessdenied"
      error = "You do not own this deal"
    }
    conditional {
      if ($deal.is_closed == false) {
        db.query "pipeline_stage" {
          where = $db.pipeline_stage.is_closed == true && $db.pipeline_stage.is_won == false
          return = { type: "single" }
        } as $lost_stage
        precondition ($lost_stage != null) {
          error_type = "standard"
          error = "No lost stage configured"
        }
        db.query "deal_stage_history" {
          where = $db.deal_stage_history.deal_id == $input.deal_id
          sort = { changed_at: "desc" }
          return = { type: "single" }
        } as $last
        var $prev_ts { value = ($last == null ? $deal.created_at : $last.changed_at) }
        function.run "days_between" {
          input = { from_ts: $prev_ts, to_ts: now }
        } as $days
        db.add "deal_stage_history" {
          data = {
            deal_id: $deal.id,
            from_stage_id: $deal.stage_id,
            to_stage_id: $lost_stage.id,
            amount_snapshot: $deal.amount,
            probability_snapshot: 0,
            changed_by: $input.actor_id,
            days_in_previous_stage: $days,
            changed_at: now
          }
        }
        db.patch "deal" {
          field_name = "id"
          field_value = $deal.id
          data = {
            stage_id: $lost_stage.id,
            probability: 0,
            expected_revenue: 0,
            forecast_category: "Omitted",
            status: "lost",
            is_won: false,
            is_closed: true,
            lost_reason: $input.lost_reason,
            actual_close_date: now,
            updated_at: now
          }
        }
      }
    }
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $final
  }
  response = $final
  guid = "_QIpe-4Xs4GmMN6zS_2uusiv2rE"
}
---
// Core close-as-Won logic (shared by the endpoint and the tests). Moves the deal
// to the is_won stage, probability 100, forecast Closed, stamps actual_close_date.
// Idempotent: a no-op if already closed. Mirrors Salesforce IsClosed/IsWon being
// controlled by StageName.
function "win_deal" {
  description = "Close a deal as Won (won stage, probability 100, closed). Idempotent."
  input {
    int deal_id
    int actor_id
    text actor_role
  }
  stack {
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
    precondition ($input.actor_role == "manager" || $deal.owner_id == $input.actor_id) {
      error_type = "accessdenied"
      error = "You do not own this deal"
    }
    conditional {
      if ($deal.is_closed == false) {
        db.query "pipeline_stage" {
          where = $db.pipeline_stage.is_won == true
          return = { type: "single" }
        } as $won_stage
        precondition ($won_stage != null) {
          error_type = "standard"
          error = "No won stage configured"
        }
        db.query "deal_stage_history" {
          where = $db.deal_stage_history.deal_id == $input.deal_id
          sort = { changed_at: "desc" }
          return = { type: "single" }
        } as $last
        var $prev_ts { value = ($last == null ? $deal.created_at : $last.changed_at) }
        function.run "days_between" {
          input = { from_ts: $prev_ts, to_ts: now }
        } as $days
        db.add "deal_stage_history" {
          data = {
            deal_id: $deal.id,
            from_stage_id: $deal.stage_id,
            to_stage_id: $won_stage.id,
            amount_snapshot: $deal.amount,
            probability_snapshot: 100,
            changed_by: $input.actor_id,
            days_in_previous_stage: $days,
            changed_at: now
          }
        }
        db.patch "deal" {
          field_name = "id"
          field_value = $deal.id
          data = {
            stage_id: $won_stage.id,
            probability: 100,
            expected_revenue: $deal.amount,
            forecast_category: "Closed",
            status: "won",
            is_won: true,
            is_closed: true,
            actual_close_date: now,
            updated_at: now
          }
        }
      }
    }
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $final
  }
  response = $final
  guid = "BKKRua7c-6tQZR6SQV0m0Aoudy4"
}
---
api_group Analytics {
  canonical = "salescrm-analytics"
  description = "Pipeline analytics: forecast rollups, win rate, pipeline-by-stage, and quota attainment."
  tags = ["crm", "analytics", "forecast"]
  guid = "Zq7jLWk5hA83k0rKFZXzG1WlsGY"
}
---
// Dashboard rollups: Salesforce-style cumulative forecast columns + weighted
// ExpectedRevenue, win rate, pipeline-by-stage, a count of stale ("no activity
// for 30 days") open deals, and a quota-attainment leaderboard. Managers see the
// whole org; reps see their own book.
query "dashboard/stats" verb=GET {
  api_group = "Analytics"
  description = "Forecast rollups, win rate, pipeline-by-stage, stale-deal count, and quota leaderboard."
  auth = "user"
  input {}
  stack {
    var $is_mgr { value = ($auth.role == "manager") }
    db.query "deal" {
      where = $is_mgr == true || $db.deal.owner_id == $auth.id
    } as $deals

    function.run "forecast_rollup" {
      input = { deals: $deals }
    } as $forecast

    var $won { value = 0 }
    var $lost { value = 0 }
    var $stale { value = 0 }
    foreach ($deals) {
      each as $d {
        conditional {
          if ($d.status == "won") {
            var.update $won { value = $won + 1 }
          }
        }
        conditional {
          if ($d.status == "lost") {
            var.update $lost { value = $lost + 1 }
          }
        }
        conditional {
          if ($d.is_closed == false) {
            var $ref { value = ($d.last_activity_at == null ? $d.created_at : $d.last_activity_at) }
            function.run "days_between" {
              input = { from_ts: $ref, to_ts: now }
            } as $rd
            conditional {
              if ($rd >= 30) {
                var.update $stale { value = $stale + 1 }
              }
            }
          }
        }
      }
    }
    var $decided { value = $won + $lost }
    var $win_rate { value = ($decided == 0 ? 0 : (($won * 100 / $decided)|round:1)) }

    db.query "pipeline_stage" {
      sort = { sort_order: "asc" }
    } as $stages
    var $by_stage { value = [] }
    foreach ($stages) {
      each as $s {
        db.query "deal" {
          where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id == $s.id
        } as $sd
        var $cnt { value = 0 }
        var $sum { value = 0 }
        var $wsum { value = 0 }
        foreach ($sd) {
          each as $d2 {
            var.update $cnt { value = $cnt + 1 }
            var.update $sum { value = $sum + $d2.amount }
            var.update $wsum { value = $wsum + $d2.expected_revenue }
          }
        }
        var.update $by_stage {
          value = $by_stage|push:({ stage_id: $s.id, stage_name: $s.name, count: $cnt, amount: $sum, weighted: $wsum|round:2 })
        }
      }
    }

    db.query "user" {
      sort = { name: "asc" }
    } as $users
    var $leaderboard { value = [] }
    foreach ($users) {
      each as $u {
        conditional {
          if ($is_mgr == true || $u.id == $auth.id) {
            db.query "deal" {
              where = $db.deal.owner_id == $u.id && $db.deal.status == "won"
            } as $uw
            var $usum { value = 0 }
            foreach ($uw) {
              each as $d3 {
                var.update $usum { value = $usum + $d3.amount }
              }
            }
            var $att { value = (($u.quota_amount == null || $u.quota_amount == 0) ? 0 : (($usum * 100 / $u.quota_amount)|round:1)) }
            function.run "attainment_band" {
              input = { pct: $att }
            } as $band
            var.update $leaderboard {
              value = $leaderboard|push:({ user_id: $u.id, name: $u.name, won_amount: $usum, quota: $u.quota_amount, attainment_pct: $att, band: $band.band })
            }
          }
        }
      }
    }
  }
  response = {
    forecast: $forecast,
    win_rate: $win_rate,
    won_count: $won,
    lost_count: $lost,
    stale_deals: $stale,
    pipeline_by_stage: $by_stage,
    leaderboard: $leaderboard
  }
  guid = "DH8Zd3qfWRNgUswbiFmRdv3leiU"
}
---
// Per-rep forecast: closed-won this book vs quota (attainment % + Salesforce
// color band) alongside weighted open pipeline. Managers get every rep; a rep
// gets just their own line.
query "forecast" verb=GET {
  api_group = "Analytics"
  description = "Per-rep quota attainment (won vs quota, color band) and weighted open pipeline."
  auth = "user"
  input {}
  stack {
    var $is_mgr { value = ($auth.role == "manager") }
    db.query "user" {
      sort = { name: "asc" }
    } as $users
    var $rows { value = [] }
    foreach ($users) {
      each as $u {
        conditional {
          if ($is_mgr == true || $u.id == $auth.id) {
            db.query "deal" {
              where = $db.deal.owner_id == $u.id
            } as $udeals
            var $won_amount { value = 0 }
            var $weighted_open { value = 0 }
            foreach ($udeals) {
              each as $d {
                conditional {
                  if ($d.status == "won") {
                    var.update $won_amount { value = $won_amount + $d.amount }
                  }
                }
                conditional {
                  if ($d.status == "open") {
                    var.update $weighted_open { value = $weighted_open + $d.expected_revenue }
                  }
                }
              }
            }
            var $att { value = (($u.quota_amount == null || $u.quota_amount == 0) ? 0 : (($won_amount * 100 / $u.quota_amount)|round:1)) }
            function.run "attainment_band" {
              input = { pct: $att }
            } as $band
            var.update $rows {
              value = $rows|push:({
                user_id: $u.id,
                name: $u.name,
                role: $u.role,
                quota: $u.quota_amount,
                quota_period: $u.quota_period,
                won_amount: $won_amount,
                weighted_open: $weighted_open|round:2,
                attainment_pct: $att,
                band: $band.band
              })
            }
          }
        }
      }
    }
  }
  response = $rows
  guid = "I2Cutiiu0v9MOEFKcwdLfTRwMg0"
}
---
api_group Auth {
  canonical = "salescrm-auth"
  description = "Authentication for the Sales Pipeline CRM (signup, login, me)."
  tags = ["auth", "crm"]
  guid = "sZKATK3uJax3tGCrTTqxdQWiEfQ"
}
---
// Authenticate by email + password, return a 24h auth token.
query "login" verb=POST {
  api_group = "Auth"
  description = "Log in with email and password; returns an auth token."
  input {
    email email filters=trim|lower
    text password
  }
  stack {
    db.get "user" {
      field_name = "email"
      field_value = $input.email
    } as $user
    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }
    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $ok
    precondition ($ok == true) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }
    security.create_auth_token {
      table = "user"
      id = $user.id
      extras = { role: $user.role }
      expiration = 86400
    } as $token
  }
  response = {
    authToken: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "KCLgBpfbtxxHExH6UGx_dJvJa2I"
}
---
// The authenticated user's profile (incl. quota).
query "me" verb=GET {
  api_group = "Auth"
  description = "Return the authenticated user's profile."
  auth = "user"
  input {}
  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
    } as $user
  }
  response = {
    id: $user.id,
    name: $user.name,
    email: $user.email,
    role: $user.role,
    quota_amount: $user.quota_amount,
    quota_period: $user.quota_period
  }
  guid = "eYCUXGl6lZEZl_LISvF8h7bXD00"
}
---
// Register a sales rep or manager and return a 24h auth token.
query "signup" verb=POST {
  api_group = "Auth"
  description = "Create a user (rep or manager) and return an auth token."
  input {
    text name filters=trim
    email email filters=trim|lower
    text password filters=min:6
    text role? filters=trim|lower
  }
  stack {
    db.has "user" {
      field_name = "email"
      field_value = $input.email
    } as $exists
    precondition ($exists == false) {
      error_type = "inputerror"
      error = "Email already registered"
    }
    db.add "user" {
      data = {
        name: $input.name,
        email: $input.email,
        password: $input.password,
        role: ($input.role == null ? "rep" : $input.role)
      }
    } as $user
    security.create_auth_token {
      table = "user"
      id = $user.id
      extras = { role: $user.role }
      expiration = 86400
    } as $token
  }
  response = {
    authToken: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "cnk3zaD_IRCDkXNw6Y3wMryEfWY"
}
---
// List accounts. Managers see all; reps see the accounts they own.
query "accounts" verb=GET {
  api_group = "Crm"
  description = "List accounts (managers: all; reps: their own)."
  auth = "user"
  input {}
  stack {
    var $is_mgr { value = ($auth.role == "manager") }
    db.query "account" {
      where = $is_mgr == true || $db.account.owner_id == $auth.id
      sort = { name: "asc" }
    } as $accounts
  }
  response = $accounts
  guid = "7gwT0XR-LHXbh6_QQxejz5W0NQI"
}
---
// Create an account owned by the authenticated user.
query "accounts" verb=POST {
  api_group = "Crm"
  description = "Create an account."
  auth = "user"
  input {
    text name filters=trim
    text industry?
    text website?
    decimal annual_revenue?=0
  }
  stack {
    db.add "account" {
      data = {
        name: $input.name,
        industry: $input.industry,
        website: $input.website,
        annual_revenue: $input.annual_revenue,
        owner_id: $auth.id
      }
    } as $account
  }
  response = $account
  guid = "UuRjYGQ15r_ComRl7pbWHiuq-AI"
}
---
// Complete an open activity and roll its due date up to the deal's
// LastActivityDate (Salesforce derives LastActivityDate from closed activities).
query "activities/{activity_id}/complete" verb=POST {
  api_group = "Crm"
  description = "Mark an activity completed and update the deal's last_activity_at."
  auth = "user"
  input {
    int activity_id { table = "activity" }
  }
  stack {
    db.get "activity" {
      field_name = "id"
      field_value = $input.activity_id
    } as $activity
    precondition ($activity != null) {
      error_type = "notfound"
      error = "Activity not found"
    }
    db.patch "activity" {
      field_name = "id"
      field_value = $input.activity_id
      data = { status: "completed", is_closed: true }
    } as $updated
    var $due { value = ($activity.due_at == null ? now : $activity.due_at) }
    conditional {
      if ($activity.deal_id != null) {
        db.patch "deal" {
          field_name = "id"
          field_value = $activity.deal_id
          data = { last_activity_at: $due, updated_at: now }
        }
      }
    }
  }
  response = $updated
  guid = "2lYi1LNODwkZgVytfAQdpQ7qKtA"
}
---
// Log an activity (call/email/meeting/task) against a deal. A meeting is stored
// as an Event; everything else as a Task. Completing the activity updates the
// deal's LastActivityDate (Salesforce: most recent closed task/event due date).
query "deals/{deal_id}/activities" verb=POST {
  api_group = "Crm"
  description = "Log an activity on a deal; a completed activity updates last_activity_at."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    text subject filters=trim
    text subtype? filters=trim|lower
    int contact_id?
    text description?
    timestamp due_at?
    bool completed?
  }
  stack {
    var $subtype { value = ($input.subtype == null ? "task" : $input.subtype) }
    var $kind { value = ($subtype == "meeting" ? "event" : "task") }
    var $completed { value = ($input.completed == null ? false : $input.completed) }
    var $status { value = ($completed == true ? "completed" : "not_started") }
    var $due { value = ($input.due_at == null ? now : $input.due_at) }
    db.add "activity" {
      data = {
        deal_id: $input.deal_id,
        contact_id: $input.contact_id,
        owner_id: $auth.id,
        kind: $kind,
        subtype: $subtype,
        subject: $input.subject,
        description: $input.description,
        due_at: $due,
        status: $status,
        is_closed: $completed
      }
    } as $activity
    conditional {
      if ($completed == true) {
        db.patch "deal" {
          field_name = "id"
          field_value = $input.deal_id
          data = { last_activity_at: $due, updated_at: now }
        }
      }
    }
  }
  response = $activity
  guid = "VL3-E3HnFv11ytW3-ccgkO5qpxk"
}
---
api_group Crm {
  canonical = "salescrm-crm"
  description = "Core CRM: accounts, contacts, leads, pipeline stages, deals, contact roles, and activities."
  tags = ["crm", "sales", "deals"]
  guid = "tNsFEZzd4bSUcoQqLTIuG8p84hI"
}
---
// The Kanban board: stages in order, each with its deals, and per-deal the three
// Salesforce Kanban attention alerts (overdue task, no open activities, no
// activity for 30 days). Managers see all deals; reps see their own.
query "board" verb=GET {
  api_group = "Crm"
  description = "Kanban board: stages with their deals and Salesforce-style attention alerts."
  auth = "user"
  input {}
  stack {
    var $is_mgr { value = ($auth.role == "manager") }
    db.query "pipeline_stage" {
      sort = { sort_order: "asc" }
    } as $stages
    var $board { value = [] }
    foreach ($stages) {
      each as $s {
        db.query "deal" {
          where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id == $s.id
          sort = { amount: "desc" }
        } as $sdeals
        var $cards { value = [] }
        foreach ($sdeals) {
          each as $d {
            db.query "activity" {
              where = $db.activity.deal_id == $d.id && $db.activity.is_closed == false
              return = { type: "count" }
            } as $open_cnt
            db.query "activity" {
              where = $db.activity.deal_id == $d.id && $db.activity.is_closed == false && $db.activity.due_at < now
              return = { type: "count" }
            } as $overdue_cnt
            var $ref_ts { value = ($d.last_activity_at == null ? $d.created_at : $d.last_activity_at) }
            function.run "days_between" {
              input = { from_ts: $ref_ts, to_ts: now }
            } as $ref_days
            function.run "deal_alerts" {
              input = {
                is_closed: $d.is_closed,
                has_overdue_task: ($overdue_cnt > 0),
                has_open_activity: ($open_cnt > 0),
                reference_days: $ref_days
              }
            } as $alerts
            var.update $cards { value = $cards|push:($d|set:"alerts":$alerts) }
          }
        }
        var.update $board { value = $board|push:({ stage: $s, deals: $cards }) }
      }
    }
  }
  response = $board
  guid = "A2OHTmKz_ii_ynRXvVwY1iuBY88"
}
---
// Add a contact role to a deal (Salesforce OpportunityContactRole: Role +
// IsPrimary). Setting is_primary demotes any existing primary first.
query "deals/{deal_id}/contact-roles" verb=POST {
  api_group = "Crm"
  description = "Attach a contact to a deal with a role; optionally mark it primary."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    int contact_id { table = "contact" }
    text role? filters=trim|lower
    bool is_primary?
  }
  stack {
    var $primary { value = ($input.is_primary == null ? false : $input.is_primary) }
    conditional {
      if ($primary == true) {
        db.query "opportunity_contact_role" {
          where = $db.opportunity_contact_role.deal_id == $input.deal_id && $db.opportunity_contact_role.is_primary == true
        } as $current_primary
        foreach ($current_primary) {
          each as $r {
            db.patch "opportunity_contact_role" {
              field_name = "id"
              field_value = $r.id
              data = { is_primary: false }
            }
          }
        }
      }
    }
    db.add "opportunity_contact_role" {
      data = {
        deal_id: $input.deal_id,
        contact_id: $input.contact_id,
        role: ($input.role == null ? "influencer" : $input.role),
        is_primary: $primary
      }
    } as $role
  }
  response = $role
  guid = "kH9m9Vxj9AGWo2D1esOKNRnEJlY"
}
---
// Mark one contact role as the deal's primary contact, demoting the others.
query "deals/{deal_id}/contact-roles/{role_id}/primary" verb=POST {
  api_group = "Crm"
  description = "Set a contact role as the deal's primary contact."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    int role_id { table = "opportunity_contact_role" }
  }
  stack {
    db.query "opportunity_contact_role" {
      where = $db.opportunity_contact_role.deal_id == $input.deal_id && $db.opportunity_contact_role.is_primary == true
    } as $current_primary
    foreach ($current_primary) {
      each as $r {
        db.patch "opportunity_contact_role" {
          field_name = "id"
          field_value = $r.id
          data = { is_primary: false }
        }
      }
    }
    db.patch "opportunity_contact_role" {
      field_name = "id"
      field_value = $input.role_id
      data = { is_primary: true }
    } as $role
  }
  response = $role
  guid = "OLUp4vLaWG3Y_ZMLwAxJ6xheGG4"
}
---
// List contacts, optionally filtered to one account.
query "contacts" verb=GET {
  api_group = "Crm"
  description = "List contacts, optionally filtered by account_id."
  auth = "user"
  input {
    int account_id?
  }
  stack {
    db.query "contact" {
      where = $db.contact.account_id ==? $input.account_id
      sort = { last_name: "asc" }
    } as $contacts
  }
  response = $contacts
  guid = "NjKBQSF6OtOaENCxI9378-pf1AM"
}
---
// Create a contact under an account.
query "contacts" verb=POST {
  api_group = "Crm"
  description = "Create a contact."
  auth = "user"
  input {
    int account_id { table = "account" }
    text first_name filters=trim
    text last_name filters=trim
    email email? filters=trim|lower
    text phone?
    text title?
  }
  stack {
    db.add "contact" {
      data = {
        account_id: $input.account_id,
        first_name: $input.first_name,
        last_name: $input.last_name,
        email: $input.email,
        phone: $input.phone,
        title: $input.title
      }
    } as $contact
  }
  response = $contact
  guid = "Qmd0A6f3S-Ggbg7XvUDEkTjm6mE"
}
---
// Guarded stage transition (thin wrapper over the advance_deal function). Reps
// can only move a deal forward one stage at a time; managers can jump. Writes a
// deal_stage_history row (Salesforce OpportunityHistory) with days_in_previous_
// stage, and re-snapshots probability + forecast category + expected revenue.
// Use the won/lost actions to close a deal.
query "deals/{deal_id}/advance" verb=POST {
  api_group = "Crm"
  description = "Advance a deal to another open stage (guarded), logging stage history."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    int stage_id { table = "pipeline_stage" }
    int probability?
  }
  stack {
    function.run "advance_deal" {
      input = {
        deal_id: $input.deal_id,
        target_stage_id: $input.stage_id,
        actor_id: $auth.id,
        actor_role: $auth.role,
        probability: $input.probability
      }
    } as $updated
  }
  response = $updated
  guid = "SdAEfvpoCaB_Pj7QBZUgitMcKv8"
}
---
// Full deal detail: the deal, its account/owner/stage, contact roles (with the
// contact), the activity timeline, and the stage-change history.
query "deals/{deal_id}" verb=GET {
  api_group = "Crm"
  description = "Deal detail with account, owner, contact roles, activities, and stage history."
  auth = "user"
  input {
    int deal_id { table = "deal" }
  }
  stack {
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
    db.get "account" {
      field_name = "id"
      field_value = $deal.account_id
    } as $account
    db.get "pipeline_stage" {
      field_name = "id"
      field_value = $deal.stage_id
    } as $stage
    db.get "user" {
      field_name = "id"
      field_value = $deal.owner_id
    } as $owner
    db.query "opportunity_contact_role" {
      where = $db.opportunity_contact_role.deal_id == $input.deal_id
      join = {
        contact: { table: "contact", where: $db.opportunity_contact_role.contact_id == $db.contact.id }
      }
      eval = {
        contact_name: $db.contact.first_name ~ " " ~ $db.contact.last_name,
        contact_title: $db.contact.title
      }
    } as $roles
    db.query "activity" {
      where = $db.activity.deal_id == $input.deal_id
      sort = { created_at: "desc" }
    } as $activities
    db.query "deal_stage_history" {
      where = $db.deal_stage_history.deal_id == $input.deal_id
      sort = { changed_at: "asc" }
    } as $history
  }
  response = {
    deal: $deal,
    account: $account,
    stage: $stage,
    owner: { id: $owner.id, name: $owner.name, email: $owner.email },
    contact_roles: $roles,
    activities: $activities,
    stage_history: $history
  }
  guid = "d_81fA8EcQQZZZMa-uDH07IgCps"
}
---
// List deals (managers: all; reps: their own), optional stage/status filters.
query "deals" verb=GET {
  api_group = "Crm"
  description = "List deals with optional stage_id/status filters (scoped by role)."
  auth = "user"
  input {
    int stage_id?
    text status? filters=trim|lower
  }
  stack {
    var $is_mgr { value = ($auth.role == "manager") }
    db.query "deal" {
      where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id ==? $input.stage_id && $db.deal.status ==? $input.status
      sort = { updated_at: "desc" }
    } as $deals
  }
  response = $deals
  guid = "UaSP8X-guF6vc5eZid3hJxTyFuQ"
}
---
// Close a deal as Lost with a reason (thin wrapper over the lose_deal function).
// Moves it to the is_lost stage, probability 0, forecast Omitted, and stamps
// actual_close_date. Idempotent.
query "deals/{deal_id}/lost" verb=POST {
  api_group = "Crm"
  description = "Mark a deal Lost with a reason (moves to the lost stage, probability 0, omitted)."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    text lost_reason filters=trim
  }
  stack {
    function.run "lose_deal" {
      input = { deal_id: $input.deal_id, actor_id: $auth.id, actor_role: $auth.role, lost_reason: $input.lost_reason }
    } as $final
  }
  response = $final
  guid = "pl484nlL_kBzKXq9knGnkh0GtUo"
}
---
// Create a deal. Snapshots probability + forecast category from the chosen stage
// (rep may override probability) and computes ExpectedRevenue, mirroring how a
// Salesforce Opportunity derives Probability/ForecastCategory from StageName.
query "deals" verb=POST {
  api_group = "Crm"
  description = "Create a deal; snapshots probability + forecast category from the stage and computes expected revenue."
  auth = "user"
  input {
    text name filters=trim
    int account_id { table = "account" }
    int stage_id { table = "pipeline_stage" }
    decimal amount?=0
    int probability?
    timestamp close_date?
    text next_step?
    text type? filters=trim|lower
    text lead_source?
  }
  stack {
    function.run "create_deal" {
      input = {
        name: $input.name,
        account_id: $input.account_id,
        owner_id: $auth.id,
        stage_id: $input.stage_id,
        amount: $input.amount,
        probability: $input.probability,
        close_date: $input.close_date,
        next_step: $input.next_step,
        type: $input.type,
        lead_source: $input.lead_source
      }
    } as $deal
  }
  response = $deal
  guid = "6m8GjGqVlkba-E7xF_MrK_3VDIo"
}
---
// Close a deal as Won (thin wrapper over the win_deal function). Moves it to the
// is_won stage, sets probability 100, forecast Closed, and stamps
// actual_close_date. Idempotent.
query "deals/{deal_id}/won" verb=POST {
  api_group = "Crm"
  description = "Mark a deal Won (moves to the won stage, probability 100, closed)."
  auth = "user"
  input {
    int deal_id { table = "deal" }
  }
  stack {
    function.run "win_deal" {
      input = { deal_id: $input.deal_id, actor_id: $auth.id, actor_role: $auth.role }
    } as $final
  }
  response = $final
  guid = "fLx-wSkJ4zAc5kjCfj4a_3MZzfo"
}
---
// Convert a lead into an Account + Contact and (optionally) an Opportunity, then
// mark the lead converted (thin wrapper over the convert_lead function). Mirrors
// Salesforce convertLead: a converted lead produces/links an account, a contact,
// and optionally an opportunity, and is flagged IsConverted with the created ids.
query "leads/{lead_id}/convert" verb=POST {
  api_group = "Crm"
  description = "Convert a lead into an account, contact, and optional opportunity (Salesforce convertLead)."
  auth = "user"
  input {
    int lead_id { table = "lead" }
    bool create_opportunity?
    text opportunity_name?
    decimal amount?=0
    int stage_id?
  }
  stack {
    function.run "convert_lead" {
      input = {
        lead_id: $input.lead_id,
        actor_id: $auth.id,
        create_opportunity: $input.create_opportunity,
        opportunity_name: $input.opportunity_name,
        amount: $input.amount,
        stage_id: $input.stage_id
      }
    } as $result
  }
  response = $result
  guid = "iBhhH3krPS6ALThmoEZ29_GOOeA"
}
---
// List leads, optionally filtered by status.
query "leads" verb=GET {
  api_group = "Crm"
  description = "List leads, optionally filtered by status."
  auth = "user"
  input {
    text status? filters=trim|lower
  }
  stack {
    db.query "lead" {
      where = $db.lead.status ==? $input.status
      sort = { created_at: "desc" }
    } as $leads
  }
  response = $leads
  guid = "OaJoDqIEve-FPEnw1IU-f1M0yfc"
}
---
// Create a lead.
query "leads" verb=POST {
  api_group = "Crm"
  description = "Create a lead."
  auth = "user"
  input {
    text first_name filters=trim
    text last_name filters=trim
    text company filters=trim
    email email? filters=trim|lower
    text lead_source?
    text rating? filters=trim|lower
  }
  stack {
    db.add "lead" {
      data = {
        first_name: $input.first_name,
        last_name: $input.last_name,
        company: $input.company,
        email: $input.email,
        lead_source: $input.lead_source,
        rating: ($input.rating == null ? "warm" : $input.rating),
        status: "new",
        is_converted: false
      }
    } as $lead
  }
  response = $lead
  guid = "WFEYibGhON1lRlmr0ukXwOwzxsc"
}
---
// The pipeline stage definitions (Salesforce OpportunityStage), in order.
query "stages" verb=GET {
  api_group = "Crm"
  description = "List pipeline stages ordered by sort_order."
  auth = "user"
  input {}
  stack {
    db.query "pipeline_stage" {
      sort = { sort_order: "asc" }
    } as $stages
  }
  response = $stages
  guid = "lV1sSTQXZuXiRffSl9dHc6IGZ6o"
}
---
api_group Seed {
  canonical = "salescrm-seed"
  description = "One-call idempotent demo-data loader for the Sales Pipeline CRM."
  tags = ["crm", "seed"]
  guid = "8XEdYFGbwVmNU0PT4RDAdenVBBo"
}
---
// Lightweight reachability check for the seed API group.
query "health" verb=GET {
  api_group = "Seed"
  description = "Health check for the seed group."
  input {}
  stack {
    db.query "deal" { return = { type: "count" } } as $deals
  }
  response = { ok: true, deals: $deals }
  guid = "5BNDA1sENCbEJyR9xbaO1CW93qg"
}
---
// Idempotent demo-data loader for the Sales Pipeline CRM.
// Guarded by a deal-count check; parents are upserted by natural key.
// Stages use the 10 standard Salesforce opportunity stages with the
// documented-example probabilities + forecast-category mapping
// (help.salesforce.com faq_forecasts_category_mapping). Exact per-stage default
// probabilities are org-configured in Salesforce; the values here follow the
// documented example plus the commonly-cited defaults.
// Demo login: any seeded email with password "DemoPass1".
query "seed" verb=POST {
  api_group = "Seed"
  description = "Load idempotent demo data (stages, users, accounts, contacts, leads, deals, activities, roles, history)."
  input {}
  stack {
    // Fully idempotent: every entity is guarded by a natural-key lookup, so
    // calling /seed twice is safe and never duplicates rows.

    // --- Pipeline stages (Salesforce OpportunityStage) ---
    var $stages { value = [
      { name: "Prospecting",          sort_order: 1,  default_probability: 10,  forecast_category: "Pipeline", is_closed: false, is_won: false },
      { name: "Qualification",        sort_order: 2,  default_probability: 10,  forecast_category: "Pipeline", is_closed: false, is_won: false },
      { name: "Needs Analysis",       sort_order: 3,  default_probability: 20,  forecast_category: "Pipeline", is_closed: false, is_won: false },
      { name: "Value Proposition",    sort_order: 4,  default_probability: 50,  forecast_category: "Pipeline", is_closed: false, is_won: false },
      { name: "Id. Decision Makers",  sort_order: 5,  default_probability: 60,  forecast_category: "BestCase", is_closed: false, is_won: false },
      { name: "Perception Analysis",  sort_order: 6,  default_probability: 70,  forecast_category: "BestCase", is_closed: false, is_won: false },
      { name: "Proposal/Price Quote", sort_order: 7,  default_probability: 75,  forecast_category: "BestCase", is_closed: false, is_won: false },
      { name: "Negotiation/Review",   sort_order: 8,  default_probability: 90,  forecast_category: "Commit",   is_closed: false, is_won: false },
      { name: "Closed Won",           sort_order: 9,  default_probability: 100, forecast_category: "Closed",   is_closed: true,  is_won: true },
      { name: "Closed Lost",          sort_order: 10, default_probability: 0,   forecast_category: "Omitted",  is_closed: true,  is_won: false }
    ] }
    foreach ($stages) {
      each as $s {
        db.get "pipeline_stage" {
          field_name = "name"
          field_value = $s.name
        } as $ex
        conditional {
          if ($ex == null) {
            db.add "pipeline_stage" {
              data = {
                name: $s.name, sort_order: $s.sort_order, default_probability: $s.default_probability,
                forecast_category: $s.forecast_category, is_closed: $s.is_closed, is_won: $s.is_won
              }
            }
          }
        }
      }
    }

    // --- Users (a manager + four reps). Password: DemoPass1 ---
    var $users { value = [
      { name: "Morgan Lee",  email: "morgan.lee@northwind.example",  role: "manager", quota_amount: 600000, quota_period: "quarterly" },
      { name: "Alex Chen",   email: "alex.chen@northwind.example",   role: "rep",     quota_amount: 200000, quota_period: "quarterly" },
      { name: "Priya Patel", email: "priya.patel@northwind.example", role: "rep",     quota_amount: 200000, quota_period: "quarterly" },
      { name: "Sam Rivera",  email: "sam.rivera@northwind.example",  role: "rep",     quota_amount: 250000, quota_period: "quarterly" },
      { name: "Jordan Kim",  email: "jordan.kim@northwind.example",  role: "rep",     quota_amount: 200000, quota_period: "quarterly" }
    ] }
    foreach ($users) {
      each as $u {
        db.get "user" {
          field_name = "email"
          field_value = $u.email
        } as $ex
        conditional {
          if ($ex == null) {
            db.add "user" {
              data = { name: $u.name, email: $u.email, password: "DemoPass1", role: $u.role, quota_amount: $u.quota_amount, quota_period: $u.quota_period }
            }
          }
        }
      }
    }

    // --- Accounts (owner resolved by email) ---
    var $accounts { value = [
      { name: "Acme Robotics",    industry: "Manufacturing",     owner: "alex.chen@northwind.example",   annual_revenue: 12000000 },
      { name: "Globex Health",    industry: "Healthcare",        owner: "priya.patel@northwind.example", annual_revenue: 45000000 },
      { name: "Initech Software", industry: "Technology",        owner: "sam.rivera@northwind.example",  annual_revenue: 8000000 },
      { name: "Umbrella Retail",  industry: "Retail",            owner: "jordan.kim@northwind.example",  annual_revenue: 30000000 },
      { name: "Soylent Foods",    industry: "Food & Beverage",   owner: "alex.chen@northwind.example",   annual_revenue: 22000000 },
      { name: "Stark Industrial", industry: "Manufacturing",     owner: "priya.patel@northwind.example", annual_revenue: 90000000 },
      { name: "Wayne Logistics",  industry: "Logistics",         owner: "sam.rivera@northwind.example",  annual_revenue: 15000000 },
      { name: "Wonka Brands",     industry: "Consumer Goods",    owner: "jordan.kim@northwind.example",  annual_revenue: 18000000 },
      { name: "Hooli Cloud",      industry: "Technology",        owner: "alex.chen@northwind.example",   annual_revenue: 60000000 },
      { name: "Pied Piper Data",  industry: "Technology",        owner: "priya.patel@northwind.example", annual_revenue: 5000000 }
    ] }
    foreach ($accounts) {
      each as $a {
        db.get "account" {
          field_name = "name"
          field_value = $a.name
        } as $ex
        conditional {
          if ($ex == null) {
            db.get "user" {
              field_name = "email"
              field_value = $a.owner
            } as $owner
            db.add "account" {
              data = { name: $a.name, industry: $a.industry, owner_id: $owner.id, annual_revenue: $a.annual_revenue }
            }
          }
        }
      }
    }

    // --- Contacts (account resolved by name) ---
    var $contacts { value = [
      { first_name: "John",   last_name: "Carter", account: "Acme Robotics",    email: "john.carter@acme.example",    title: "VP Operations", phone: "+1-202-555-0111" },
      { first_name: "Lisa",   last_name: "Ng",     account: "Acme Robotics",    email: "lisa.ng@acme.example",        title: "Procurement Lead", phone: "+1-202-555-0112" },
      { first_name: "Raj",    last_name: "Mehta",  account: "Globex Health",    email: "raj.mehta@globex.example",    title: "CIO", phone: "+1-202-555-0113" },
      { first_name: "Emma",   last_name: "Stone",  account: "Globex Health",    email: "emma.stone@globex.example",   title: "Director of IT", phone: "+1-202-555-0114" },
      { first_name: "Tom",    last_name: "Blake",  account: "Initech Software", email: "tom.blake@initech.example",   title: "CTO", phone: "+1-202-555-0115" },
      { first_name: "Nina",   last_name: "Patel",  account: "Umbrella Retail",  email: "nina.patel@umbrella.example", title: "Head of Retail Ops", phone: "+1-202-555-0116" },
      { first_name: "Carlos", last_name: "Diaz",   account: "Soylent Foods",    email: "carlos.diaz@soylent.example", title: "Supply Chain Manager", phone: "+1-202-555-0117" },
      { first_name: "Grace",  last_name: "Lee",    account: "Stark Industrial", email: "grace.lee@stark.example",     title: "VP Engineering", phone: "+1-202-555-0118" },
      { first_name: "Owen",   last_name: "Frost",  account: "Wayne Logistics",  email: "owen.frost@wayne.example",    title: "Ops Director", phone: "+1-202-555-0119" },
      { first_name: "Mia",    last_name: "Wong",   account: "Wonka Brands",     email: "mia.wong@wonka.example",      title: "Brand Manager", phone: "+1-202-555-0120" },
      { first_name: "Ethan",  last_name: "Cole",   account: "Hooli Cloud",      email: "ethan.cole@hooli.example",    title: "Platform Lead", phone: "+1-202-555-0121" },
      { first_name: "Ava",    last_name: "Reed",   account: "Pied Piper Data",  email: "ava.reed@piedpiper.example",  title: "Founder", phone: "+1-202-555-0122" }
    ] }
    foreach ($contacts) {
      each as $c {
        db.get "contact" {
          field_name = "email"
          field_value = $c.email
        } as $ex
        conditional {
          if ($ex == null) {
            db.get "account" {
              field_name = "name"
              field_value = $c.account
            } as $acct
            db.add "contact" {
              data = { account_id: $acct.id, first_name: $c.first_name, last_name: $c.last_name, email: $c.email, title: $c.title, phone: $c.phone }
            }
          }
        }
      }
    }

    // --- Leads ---
    var $leads { value = [
      { first_name: "Rachel", last_name: "Green",  company: "Vandelay Imports", email: "rachel.green@vandelay.example", lead_source: "Web",        rating: "warm", status: "new" },
      { first_name: "Kevin",  last_name: "Hart",   company: "Dunder Data",      email: "kevin.hart@dunder.example",    lead_source: "Trade Show",  rating: "hot",  status: "working" },
      { first_name: "Sofia",  last_name: "Marin",  company: "Prestige Health",  email: "sofia.marin@prestige.example", lead_source: "Referral",    rating: "hot",  status: "qualified" },
      { first_name: "Liam",   last_name: "Ford",   company: "Oscorp Labs",      email: "liam.ford@oscorp.example",     lead_source: "Advertisement", rating: "cold", status: "nurturing" },
      { first_name: "Nora",   last_name: "Bishop", company: "Cyberdyne Retail", email: "nora.bishop@cyberdyne.example", lead_source: "Web",        rating: "warm", status: "new" }
    ] }
    foreach ($leads) {
      each as $l {
        db.get "lead" {
          field_name = "email"
          field_value = $l.email
        } as $ex
        conditional {
          if ($ex == null) {
            db.add "lead" {
              data = { first_name: $l.first_name, last_name: $l.last_name, company: $l.company, email: $l.email, lead_source: $l.lead_source, rating: $l.rating, status: $l.status, is_converted: false }
            }
          }
        }
      }
    }

    // --- Deals ---
    var $deals { value = [
      { name: "Acme line automation",     account: "Acme Robotics",    owner: "alex.chen@northwind.example",   stage: "Prospecting",          amount: 45000,  status: "open", created_days: 40,  activity_days: 35, next_step: "Book discovery workshop", lost_reason: null },
      { name: "Acme spare parts",         account: "Acme Robotics",    owner: "alex.chen@northwind.example",   stage: "Qualification",        amount: 30000,  status: "open", created_days: 25,  activity_days: 5,  next_step: "Confirm budget", lost_reason: null },
      { name: "Globex telehealth rollout", account: "Globex Health",   owner: "priya.patel@northwind.example", stage: "Proposal/Price Quote", amount: 180000, status: "open", created_days: 60,  activity_days: 3,  next_step: "Send revised quote", lost_reason: null },
      { name: "Globex analytics addon",   account: "Globex Health",    owner: "priya.patel@northwind.example", stage: "Negotiation/Review",   amount: 90000,  status: "open", created_days: 50,  activity_days: 40, next_step: "Chase legal", lost_reason: null },
      { name: "Initech platform license", account: "Initech Software", owner: "sam.rivera@northwind.example",  stage: "Needs Analysis",       amount: 60000,  status: "open", created_days: 20,  activity_days: 2,  next_step: "Map requirements", lost_reason: null },
      { name: "Umbrella POS upgrade",     account: "Umbrella Retail",  owner: "jordan.kim@northwind.example",  stage: "Value Proposition",    amount: 120000, status: "open", created_days: 30,  activity_days: 10, next_step: "Present ROI", lost_reason: null },
      { name: "Soylent supply portal",    account: "Soylent Foods",    owner: "alex.chen@northwind.example",   stage: "Id. Decision Makers",  amount: 75000,  status: "open", created_days: 45,  activity_days: 33, next_step: "Identify economic buyer", lost_reason: null },
      { name: "Stark robotics contract",  account: "Stark Industrial", owner: "priya.patel@northwind.example", stage: "Negotiation/Review",   amount: 260000, status: "open", created_days: 70,  activity_days: 4,  next_step: "Redline contract", lost_reason: null },
      { name: "Wayne fleet tracking",     account: "Wayne Logistics",  owner: "sam.rivera@northwind.example",  stage: "Perception Analysis",  amount: 95000,  status: "open", created_days: 38,  activity_days: 12, next_step: "Address security questions", lost_reason: null },
      { name: "Wonka packaging deal",     account: "Wonka Brands",     owner: "jordan.kim@northwind.example",  stage: "Prospecting",          amount: 40000,  status: "open", created_days: 10,  activity_days: 1,  next_step: "Qualify need", lost_reason: null },
      { name: "Hooli migration",          account: "Hooli Cloud",      owner: "alex.chen@northwind.example",   stage: "Proposal/Price Quote", amount: 150000, status: "open", created_days: 55,  activity_days: 6,  next_step: "Finalize SOW", lost_reason: null },
      { name: "Pied Piper pilot",         account: "Pied Piper Data",  owner: "priya.patel@northwind.example", stage: "Qualification",        amount: 25000,  status: "open", created_days: 15,  activity_days: 45, next_step: "Re-engage founder", lost_reason: null },
      { name: "Acme retrofit",            account: "Acme Robotics",    owner: "alex.chen@northwind.example",   stage: "Closed Won",           amount: 85000,  status: "won",  created_days: 90,  activity_days: 20, next_step: null, lost_reason: null },
      { name: "Globex clinic expansion",  account: "Globex Health",    owner: "priya.patel@northwind.example", stage: "Closed Won",           amount: 220000, status: "won",  created_days: 120, activity_days: 30, next_step: null, lost_reason: null },
      { name: "Initech renewal",          account: "Initech Software", owner: "sam.rivera@northwind.example",  stage: "Closed Won",           amount: 70000,  status: "won",  created_days: 80,  activity_days: 15, next_step: null, lost_reason: null },
      { name: "Umbrella loyalty app",     account: "Umbrella Retail",  owner: "jordan.kim@northwind.example",  stage: "Closed Won",           amount: 130000, status: "won",  created_days: 100, activity_days: 25, next_step: null, lost_reason: null },
      { name: "Stark maintenance",        account: "Stark Industrial", owner: "priya.patel@northwind.example", stage: "Closed Won",           amount: 95000,  status: "won",  created_days: 60,  activity_days: 10, next_step: null, lost_reason: null },
      { name: "Wayne warehouse bid",      account: "Wayne Logistics",  owner: "sam.rivera@northwind.example",  stage: "Closed Lost",          amount: 110000, status: "lost", created_days: 75,  activity_days: 40, next_step: null, lost_reason: "Chose competitor on price" },
      { name: "Wonka vending trial",      account: "Wonka Brands",     owner: "jordan.kim@northwind.example",  stage: "Closed Lost",          amount: 35000,  status: "lost", created_days: 50,  activity_days: 45, next_step: null, lost_reason: "Budget cut this quarter" },
      { name: "Hooli security suite",     account: "Hooli Cloud",      owner: "alex.chen@northwind.example",   stage: "Closed Won",           amount: 160000, status: "won",  created_days: 110, activity_days: 18, next_step: null, lost_reason: null }
    ] }
    foreach ($deals) {
      each as $d {
        db.get "account" {
          field_name = "name"
          field_value = $d.account
        } as $acct
        db.get "user" {
          field_name = "email"
          field_value = $d.owner
        } as $owner
        db.get "pipeline_stage" {
          field_name = "name"
          field_value = $d.stage
        } as $stage
        db.get "deal" {
          field_name = "name"
          field_value = $d.name
        } as $existing_deal
        conditional {
          if ($existing_deal == null) {
            var $er { value = ($d.amount * $stage.default_probability / 100)|round:2 }
            var $created { value = (now|to_int) - ($d.created_days * 86400000) }
            var $last_act { value = ($d.activity_days == null ? null : (now|to_int) - ($d.activity_days * 86400000)) }
            var $acd { value = null }
            conditional {
              if ($d.status != "open") {
                var.update $acd { value = (now|to_int) - 259200000 }
              }
            }
            db.add "deal" {
              data = {
                name: $d.name, account_id: $acct.id, owner_id: $owner.id, amount: $d.amount,
                probability: $stage.default_probability, expected_revenue: $er, stage_id: $stage.id,
                forecast_category: $stage.forecast_category, close_date: ((now|to_int) + 1728000000),
                actual_close_date: $acd, status: $d.status, is_closed: $stage.is_closed, is_won: $stage.is_won,
                lost_reason: $d.lost_reason, next_step: $d.next_step, type: "new_business",
                last_activity_at: $last_act, created_at: $created, updated_at: now
              }
            } as $deal
            db.add "deal_stage_history" {
              data = {
                deal_id: $deal.id, from_stage_id: null, to_stage_id: $stage.id,
                amount_snapshot: $d.amount, probability_snapshot: $stage.default_probability,
                changed_by: $owner.id, days_in_previous_stage: 0, changed_at: $created
              }
            }
          }
        }
      }
    }

    // --- Activities (deal resolved by name) ---
    var $activities { value = [
      { deal: "Acme line automation",     subtype: "call",    subject: "Intro call with ops lead",   due_days: -35, completed: true },
      { deal: "Umbrella POS upgrade",     subtype: "task",    subject: "Send POS pricing sheet",     due_days: -2,  completed: false },
      { deal: "Stark robotics contract",  subtype: "meeting", subject: "On-site solution demo",      due_days: 3,   completed: false },
      { deal: "Globex telehealth rollout", subtype: "call",   subject: "Proposal walkthrough",       due_days: -3,  completed: true },
      { deal: "Initech platform license", subtype: "email",   subject: "Share security whitepaper",  due_days: -2,  completed: true },
      { deal: "Hooli migration",          subtype: "task",    subject: "Finalize statement of work", due_days: 5,   completed: false },
      { deal: "Wayne fleet tracking",     subtype: "call",    subject: "Check-in with ops director", due_days: -12, completed: true },
      { deal: "Acme spare parts",         subtype: "task",    subject: "Follow up on quote",         due_days: -1,  completed: false },
      { deal: "Wonka packaging deal",     subtype: "call",    subject: "Discovery call",             due_days: -1,  completed: true },
      { deal: "Stark robotics contract",  subtype: "task",    subject: "Legal redline review",       due_days: 2,   completed: false }
    ] }
    foreach ($activities) {
      each as $act {
        db.get "deal" {
          field_name = "name"
          field_value = $act.deal
        } as $deal
        db.query "activity" {
          where = $db.activity.deal_id == $deal.id && $db.activity.subject == $act.subject
          return = { type: "exists" }
        } as $act_exists
        conditional {
          if ($act_exists == false) {
            var $kind { value = ($act.subtype == "meeting" ? "event" : "task") }
            var $status { value = ($act.completed == true ? "completed" : "not_started") }
            db.add "activity" {
              data = {
                deal_id: $deal.id, owner_id: $deal.owner_id, kind: $kind, subtype: $act.subtype,
                subject: $act.subject, due_at: ((now|to_int) + ($act.due_days * 86400000)),
                status: $status, is_closed: $act.completed
              }
            }
          }
        }
      }
    }

    // --- Opportunity contact roles (deal + contact resolved by natural key) ---
    var $roles { value = [
      { deal: "Acme line automation",     contact: "john.carter@acme.example",  role: "decision_maker", is_primary: true },
      { deal: "Globex telehealth rollout", contact: "raj.mehta@globex.example", role: "decision_maker", is_primary: true },
      { deal: "Globex telehealth rollout", contact: "emma.stone@globex.example", role: "technical_buyer", is_primary: false },
      { deal: "Stark robotics contract",  contact: "grace.lee@stark.example",   role: "decision_maker", is_primary: true },
      { deal: "Umbrella POS upgrade",     contact: "nina.patel@umbrella.example", role: "economic_buyer", is_primary: true },
      { deal: "Hooli migration",          contact: "ethan.cole@hooli.example",  role: "champion", is_primary: true }
    ] }
    foreach ($roles) {
      each as $r {
        db.get "deal" {
          field_name = "name"
          field_value = $r.deal
        } as $deal
        db.get "contact" {
          field_name = "email"
          field_value = $r.contact
        } as $contact
        db.query "opportunity_contact_role" {
          where = $db.opportunity_contact_role.deal_id == $deal.id && $db.opportunity_contact_role.contact_id == $contact.id
          return = { type: "exists" }
        } as $role_exists
        conditional {
          if ($role_exists == false) {
            db.add "opportunity_contact_role" {
              data = { deal_id: $deal.id, contact_id: $contact.id, role: $r.role, is_primary: $r.is_primary }
            }
          }
        }
      }
    }
  }
  response = { seeded: true, deals: 20, stages: 10, users: 5, accounts: 10, contacts: 12, leads: 5 }
  guid = "mI89dO3rmeUqSMzCyLLc-Aa1RkM"
}
---
// Proves the analytics + lead-conversion outcomes against the seeded book: the
// cumulative forecast rollup reports closed-won revenue and a weighted pipeline,
// and a qualified lead converts into an account + contact + opportunity and is
// flagged converted.
workflow_test "sales_pipeline_crm_dashboard_and_convert" {
  tags = ["crm", "analytics", "e2e"]
  stack {
    api.call "seed" verb=POST { api_group = "Seed" } as $seed
    expect.to_be_true ($seed.seeded)

    // Forecast rollup over the whole seeded book.
    db.query "deal" {} as $deals
    function.call "forecast_rollup" {
      input = { deals: $deals }
    } as $forecast
    expect.to_be_greater_than ($forecast.closed_only) { value = 0 }
    expect.to_be_greater_than ($forecast.weighted_expected) { value = 0 }
    expect.to_be_greater_than ($forecast.open_pipeline) { value = 0 }

    // Convert the seeded qualified lead into account + contact + opportunity.
    db.get "user" {
      field_name = "email"
      field_value = "priya.patel@northwind.example"
    } as $rep
    db.query "lead" {
      where = $db.lead.status == "qualified"
      return = { type: "single" }
    } as $lead
    expect.to_not_be_null ($lead)

    function.call "convert_lead" {
      input = { lead_id: $lead.id, actor_id: $rep.id, create_opportunity: true, opportunity_name: "Converted Opp", amount: 40000 }
    } as $converted
    expect.to_not_be_null ($converted.opportunity_id)
    expect.to_be_defined ($converted.account.id)
    expect.to_be_defined ($converted.contact.id)
    expect.to_be_true ($converted.lead.is_converted)
  }
  guid = "UbkLDXDAYWh2YM5m3S5zKYSihWY"
}
---
// End-to-end deal lifecycle through the shared logic functions (the same code the
// endpoints call): create a deal (probability snapshots from the stage), advance
// it (re-snapshot + stage history), then win it — asserting the Salesforce-
// mirrored state at each step, against the seeded pipeline.
workflow_test "sales_pipeline_crm_deal_lifecycle" {
  tags = ["crm", "e2e"]
  stack {
    api.call "seed" verb=POST { api_group = "Seed" } as $seed
    expect.to_be_true ($seed.seeded)

    db.get "user" {
      field_name = "email"
      field_value = "morgan.lee@northwind.example"
    } as $mgr
    expect.to_not_be_null ($mgr)

    db.query "pipeline_stage" { sort = { sort_order: "asc" } } as $stages
    var $s1 { value = $stages[0] }
    var $s2 { value = $stages[1] }

    db.add "account" {
      data = { name: "Lifecycle Test Co", owner_id: $mgr.id }
    } as $acct

    function.call "create_deal" {
      input = { name: "Lifecycle Deal", account_id: $acct.id, owner_id: $mgr.id, stage_id: $s1.id, amount: 100000 }
    } as $deal
    expect.to_equal ($deal.probability) { value = $s1.default_probability }
    expect.to_be_greater_than ($deal.expected_revenue) { value = -1 }

    function.call "advance_deal" {
      input = { deal_id: $deal.id, target_stage_id: $s2.id, actor_id: $mgr.id, actor_role: "manager" }
    } as $adv
    expect.to_equal ($adv.stage_id) { value = $s2.id }
    expect.to_equal ($adv.probability) { value = $s2.default_probability }

    function.call "win_deal" {
      input = { deal_id: $deal.id, actor_id: $mgr.id, actor_role: "manager" }
    } as $won
    expect.to_be_true ($won.is_won)
    expect.to_be_true ($won.is_closed)
    expect.to_equal ($won.status) { value = "won" }
    expect.to_equal ($won.forecast_category) { value = "Closed" }
    expect.to_equal ($won.probability) { value = 100 }

    // Stage history recorded each transition (open row + advance + win = 3).
    db.query "deal_stage_history" {
      where = $db.deal_stage_history.deal_id == $deal.id
      return = { type: "count" }
    } as $history_count
    expect.to_be_greater_than ($history_count) { value = 2 }
  }
  guid = "0qqoCA-roz9lSTxybRA3J6vHkTs"
}
---
// Proves the guarded stage transition: a rep cannot skip stages. Everything the
// throwing call needs is built inside the to_throw stack (its scope is isolated):
// a rep-owned deal in the first stage, then a jump two stages forward as that rep
// must be rejected with the guardrail error.
workflow_test "sales_pipeline_crm_rep_stage_guard" {
  tags = ["crm", "guardrail"]
  stack {
    api.call "seed" verb=POST { api_group = "Seed" } as $seed
    expect.to_be_true ($seed.seeded)

    expect.to_throw {
      stack {
        db.get "user" {
          field_name = "email"
          field_value = "alex.chen@northwind.example"
        } as $rep
        db.query "pipeline_stage" { sort = { sort_order: "asc" } } as $stages
        var $s1 { value = $stages[0] }
        var $s3 { value = $stages[2] }
        db.add "account" {
          data = { name: "Guardrail Test Co", owner_id: $rep.id }
        } as $acct
        function.call "create_deal" {
          input = { name: "Guardrail Deal", account_id: $acct.id, owner_id: $rep.id, stage_id: $s1.id, amount: 50000 }
        } as $deal
        function.call "advance_deal" {
          input = { deal_id: $deal.id, target_stage_id: $s3.id, actor_id: $rep.id, actor_role: "rep" }
        } as $bad
      }
      exception = "Reps can't skip stages; advance one at a time"
    }
  }
  guid = "nGWMvKpUKpdC0EuZx5hpuMGk_Lc"
}
