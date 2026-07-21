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
