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
    db.get "user" {
      description = "Load the acting user to pass their role into the guarded close"
      field_name = "id"
      field_value = $auth.id
    } as $me
    function.run "deals/win_deal" {
      description = "Close the deal as Won"
      input = { deal_id: $input.deal_id, actor_id: $auth.id, actor_role: $me.role }
    } as $final
  }
  response = $final
  guid = "fLx-wSkJ4zAc5kjCfj4a_3MZzfo"
}
