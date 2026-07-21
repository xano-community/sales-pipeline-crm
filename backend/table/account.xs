table "account" {
  auth = false
  schema {
    int id
    text name filters=trim
    text industry?
    text website?
    decimal annual_revenue?=0
    int owner_id {
      table = "user"
    }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
    {type: "btree", field: [{name: "name"}]}
  ]
  guid = "w1Qcu9Z7UO5m7cT6Zrd-y1Q9wuI"
}
