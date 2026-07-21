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
    function.run "win_deal" {
      input = { deal_id: $input.deal_id, actor_id: $auth.id, actor_role: $auth.role }
    } as $final
  }
  response = $final
  guid = "fLx-wSkJ4zAc5kjCfj4a_3MZzfo"
}
