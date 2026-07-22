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
    db.get "user" {
      description = "Load the acting user to pass their role into the guarded transition"
      field_name = "id"
      field_value = $auth.id
    } as $me
    function.run "advance_deal" {
      description = "Run the guarded stage transition, logging history and re-snapshotting probability"
      input = {
        deal_id: $input.deal_id,
        target_stage_id: $input.stage_id,
        actor_id: $auth.id,
        actor_role: $me.role,
        probability: $input.probability
      }
    } as $updated
  }
  response = $updated
  guid = "SdAEfvpoCaB_Pj7QBZUgitMcKv8"
}
