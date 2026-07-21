table "user" {
  auth = true
  schema {
    int id
    text name filters=trim
    email email filters=trim|lower {
      sensitive = true
    }
    password password {
      sensitive = true
    }
    enum role?="rep" {
      values = ["rep", "manager"]
    }
    decimal quota_amount?=0
    enum quota_period?="monthly" {
      values = ["monthly", "quarterly"]
    }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "email"}]}
    {type: "btree", field: [{name: "role"}]}
  ]
  guid = "Gci5VlDnOKjjjmh4XFo4Q7I7dUs"
}
