// List deals (managers: all; reps: their own), optional stage/status filters.
query "deals" verb=GET {
  api_group = "Crm"
  description = "List deals with optional stage_id/status filters (scoped by role)."
  auth = "user"
  input {
    int stage_id?
    text status? filters=trim|lower
  }
  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr { value = ($me.role == "manager") }
    db.query "deal" {
      where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id ==? $input.stage_id && $db.deal.status ==? $input.status
      sort = { updated_at: "desc" }
    } as $deals
  }
  response = $deals
  guid = "UaSP8X-guF6vc5eZid3hJxTyFuQ"
}
