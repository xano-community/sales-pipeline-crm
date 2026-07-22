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
      description = "Load the deal being closed as Won"
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    // Deal must exist
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
    // Only the deal owner or a manager may close it
    precondition ($input.actor_role == "manager" || $deal.owner_id == $input.actor_id) {
      error_type = "accessdenied"
      error = "You do not own this deal"
    }
    // Idempotent: only act if the deal is still open
    conditional {
      if ($deal.is_closed == false) {
        db.query "pipeline_stage" {
          description = "Find the configured Won stage"
          where = $db.pipeline_stage.is_won == true
          return = { type: "single" }
        } as $won_stage
        // A won stage must be configured to close the deal
        precondition ($won_stage != null) {
          error_type = "standard"
          error = "No won stage configured"
        }
        db.query "deal_stage_history" {
          description = "Find the most recent stage-history row to time the previous stage"
          where = $db.deal_stage_history.deal_id == $input.deal_id
          sort = { changed_at: "desc" }
          return = { type: "single" }
        } as $last
        var $prev_ts {
          description = "Timestamp the deal entered its current stage (or created_at if none)"
          value = ($last == null ? $deal.created_at : $last.changed_at)
        }
        function.run "days_between" {
          description = "Compute days spent in the stage being closed out"
          input = { from_ts: $prev_ts, to_ts: now }
        } as $days
        db.add "deal_stage_history" {
          description = "Record the close-as-Won transition in OpportunityHistory"
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
          description = "Close the deal as Won: won stage, probability 100, forecast Closed, stamp close date"
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
      description = "Re-read the deal to return its final closed state"
      field_name = "id"
      field_value = $input.deal_id
    } as $final
  }
  response = $final
  guid = "BKKRua7c-6tQZR6SQV0m0Aoudy4"
}
