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
