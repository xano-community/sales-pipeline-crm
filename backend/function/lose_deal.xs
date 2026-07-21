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
