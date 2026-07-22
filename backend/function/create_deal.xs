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
      description = "Load the opening stage to snapshot its probability and forecast category"
      field_name = "id"
      field_value = $input.stage_id
    } as $stage
    // Opening stage must exist
    precondition ($stage != null) {
      error_type = "inputerror"
      error = "Unknown stage"
    }
    var $prob {
      description = "Probability for the new deal: the rep override or the stage default"
      value = ($input.probability == null ? $stage.default_probability : $input.probability)
    }
    function.run "calc_expected_revenue" {
      description = "Compute weighted expected revenue for the new deal"
      input = { amount: $input.amount, probability: $prob }
    } as $er
    db.add "deal" {
      description = "Create the deal with stage-snapshotted probability, forecast category, and expected revenue"
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
      description = "Write the opening stage-history row for the new deal"
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
