table "contact" {
  auth = false
  schema {
    int id
    int account_id {
      table = "account"
    }
    text first_name filters=trim
    text last_name filters=trim
    email email? filters=trim|lower {
      sensitive = true
    }
    text phone?
    text title?
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "account_id"}]}
    {type: "btree", field: [{name: "email"}]}
  ]
  guid = "JA7D6tBo8I-8_YKvug4RPSjl_Yw"
}
