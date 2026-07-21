// List leads, optionally filtered by status.
query "leads" verb=GET {
  api_group = "Crm"
  description = "List leads, optionally filtered by status."
  auth = "user"
  input {
    text status? filters=trim|lower
  }
  stack {
    db.query "lead" {
      where = $db.lead.status ==? $input.status
      sort = { created_at: "desc" }
    } as $leads
  }
  response = $leads
  guid = "OaJoDqIEve-FPEnw1IU-f1M0yfc"
}
