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
    db.get "user" {
      description = "Load the acting user to pass their role into the guarded close"
      field_name = "id"
      field_value = $auth.id
    } as $me
    function.run "deals/lose_deal" {
      description = "Close the deal as Lost with the given reason"
      input = { deal_id: $input.deal_id, actor_id: $auth.id, actor_role: $me.role, lost_reason: $input.lost_reason }
    } as $final
  }
  response = $final
  guid = "pl484nlL_kBzKXq9knGnkh0GtUo"
}
