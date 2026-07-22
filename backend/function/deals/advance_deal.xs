// Core guarded stage-transition logic (shared by the endpoint and the tests).
// Reps advance one stage forward at a time; managers may jump. Writes a
// deal_stage_history row (Salesforce OpportunityHistory) with days-in-previous-
// stage and re-snapshots probability + forecast category + expected revenue.
function "deals/advance_deal" {
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
      description = "Load the deal being advanced"
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    group {
      description = "Validate access and deal state"
      stack {
        // Deal must exist
        precondition ($deal != null) {
          error_type = "notfound"
          error = "Deal not found"
        }
        // Only the deal owner or a manager may move it
        precondition ($input.actor_role == "manager" || $deal.owner_id == $input.actor_id) {
          error_type = "accessdenied"
          error = "You do not own this deal"
        }
        // Can't re-stage a won/lost deal
        precondition ($deal.is_closed == false) {
          error_type = "inputerror"
          error = "Deal is already closed"
        }
      }
    }
    group {
      description = "Validate the requested stage move"
      stack {
        db.get "pipeline_stage" {
          description = "Load the target stage the deal is moving to"
          field_name = "id"
          field_value = $input.target_stage_id
        } as $target
        // Target stage must exist
        precondition ($target != null) {
          error_type = "inputerror"
          error = "Unknown stage"
        }
        // Closing must go through the won/lost actions, not a plain advance
        precondition ($target.is_closed == false) {
          error_type = "inputerror"
          error = "Use the won or lost action to close a deal"
        }
        db.get "pipeline_stage" {
          description = "Load the deal's current stage to compare sort order"
          field_name = "id"
          field_value = $deal.stage_id
        } as $current
        // Reps advance forward one stage at a time; managers may jump
        conditional {
          if ($input.actor_role != "manager") {
            // Reps can't move a deal backward
            precondition ($target.sort_order > $current.sort_order) {
              error_type = "inputerror"
              error = "Reps can only move a deal forward"
            }
            // Reps can't skip stages
            precondition ($target.sort_order <= $current.sort_order + 1) {
              error_type = "inputerror"
              error = "Reps can't skip stages; advance one at a time"
            }
          }
        }
      }
    }
    group {
      description = "Record the stage transition"
      stack {
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
        function.run "calc/days_between" {
          description = "Compute days spent in the previous stage"
          input = { from_ts: $prev_ts, to_ts: now }
        } as $days
        var $prob {
          description = "Probability to apply: the override or the target stage default"
          value = ($input.probability == null ? $target.default_probability : $input.probability)
        }
        function.run "calc/calc_expected_revenue" {
          description = "Recompute weighted expected revenue at the new probability"
          input = { amount: $deal.amount, probability: $prob }
        } as $er
        db.add "deal_stage_history" {
          description = "Record the stage transition in OpportunityHistory"
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
          description = "Move the deal to the new stage and re-snapshot probability, expected revenue, and forecast category"
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
    }
  }
  response = $updated
  guid = "7br7FXg9a2JpHI8T_bdjC_lUYmI"
}
