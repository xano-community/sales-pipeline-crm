table "user" {
  description = "Sales team members who log in and own accounts, deals, and activities — reps and managers (Salesforce User)."
  auth = true
  schema {
    int id
    text name filters=trim { description = "User's full display name" }
    email email filters=trim|lower {
      description = "User's login email address"
      sensitive = true
    }
    password password {
      description = "User's hashed login password"
      sensitive = true
    }
    enum role?="rep" {
      description = "Access role: rep sees their own book, manager has broader visibility and can override stage jumps"
      values = ["rep", "manager"]
    }
    decimal quota_amount?=0 { description = "Sales quota target assigned to this user" }
    enum quota_period?="monthly" {
      description = "Cadence the quota is measured over"
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
