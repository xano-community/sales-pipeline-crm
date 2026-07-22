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
      description = "Load the deal being closed as Lost"
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    group {
      description = "Validate access"
      stack {
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
      }
    }
    // Idempotent: only act if the deal is still open
    conditional {
      if ($deal.is_closed == false) {
        group {
          description = "Close the deal as Lost"
          stack {
            db.query "pipeline_stage" {
              description = "Find the configured Closed/Lost stage"
              where = $db.pipeline_stage.is_closed == true && $db.pipeline_stage.is_won == false
              return = { type: "single" }
            } as $lost_stage
            // A lost stage must be configured to close the deal
            precondition ($lost_stage != null) {
              error_type = "standard"
              error = "No lost stage configured"
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
              description = "Record the close-as-Lost transition in OpportunityHistory"
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
              description = "Close the deal as Lost: lost stage, probability 0, forecast Omitted, stamp close date"
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
      }
    }
    db.get "deal" {
      description = "Re-read the deal to return its final closed state"
      field_name = "id"
      field_value = $input.deal_id
    } as $final
  }
  response = $final
  guid = "_QIpe-4Xs4GmMN6zS_2uusiv2rE"
}
