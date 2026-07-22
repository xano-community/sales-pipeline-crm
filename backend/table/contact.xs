table "contact" {
  description = "People at an account you sell to — the individuals attached to deals as buyers and influencers (Salesforce Contact)."
  auth = false
  schema {
    int id
    int account_id {
      description = "Account this contact works for"
      table = "account"
    }
    text first_name filters=trim { description = "Contact's first name" }
    text last_name filters=trim { description = "Contact's last name" }
    email email? filters=trim|lower {
      description = "Contact's email address"
      sensitive = true
    }
    text phone? { description = "Contact's phone number" }
    text title? { description = "Contact's job title at the account" }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "account_id"}]}
    {type: "btree", field: [{name: "email"}]}
  ]
  guid = "JA7D6tBo8I-8_YKvug4RPSjl_Yw"
}
