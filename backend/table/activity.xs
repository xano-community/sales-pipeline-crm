table "activity" {
  auth = false
  schema {
    int id
    int deal_id? {
      table = "deal"
    }
    int contact_id? {
      table = "contact"
    }
    int owner_id {
      table = "user"
    }
    enum kind?="task" {
      values = ["task", "event"]
    }
    enum subtype?="task" {
      values = ["call", "email", "meeting", "task"]
    }
    text subject filters=trim
    text description?
    timestamp due_at?
    enum status?="not_started" {
      values = ["not_started", "in_progress", "completed", "waiting", "deferred"]
    }
    bool is_closed?=false
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "contact_id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
  ]
  guid = "uYgq8an0oFZiYAR_tgEzLJUXxVk"
}
