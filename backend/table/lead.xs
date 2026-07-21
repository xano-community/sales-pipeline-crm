table "lead" {
  auth = false
  schema {
    int id
    text first_name filters=trim
    text last_name filters=trim
    text company filters=trim
    email email? filters=trim|lower {
      sensitive = true
    }
    text lead_source?
    enum status?="new" {
      values = ["new", "working", "nurturing", "qualified", "unqualified", "converted"]
    }
    enum rating?="warm" {
      values = ["hot", "warm", "cold"]
    }
    bool is_converted?=false
    int converted_account_id? {
      table = "account"
    }
    int converted_contact_id? {
      table = "contact"
    }
    int converted_opportunity_id? {
      table = "deal"
    }
    timestamp converted_at?
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "is_converted"}]}
  ]
  guid = "EnMJD5_d2hvY6MucccGwWSezxbs"
}
