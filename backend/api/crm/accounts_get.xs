// List accounts. Managers see all; reps see the accounts they own.
query "accounts" verb=GET {
  api_group = "Crm"
  description = "List accounts (managers: all; reps: their own)."
  auth = "user"
  input {}
  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr { value = ($me.role == "manager") }
    db.query "account" {
      where = $is_mgr == true || $db.account.owner_id == $auth.id
      sort = { name: "asc" }
    } as $accounts
  }
  response = $accounts
  guid = "7gwT0XR-LHXbh6_QQxejz5W0NQI"
}
