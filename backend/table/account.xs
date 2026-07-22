table "account" {
  description = "Companies you sell to — the customer/organization records deals and contacts hang off of (Salesforce Account)."
  auth = false
  schema {
    int id
    text name filters=trim { description = "Company/organization name" }
    text industry? { description = "Industry vertical the account operates in" }
    text website? { description = "Account's primary website URL" }
    decimal annual_revenue?=0 { description = "Account's reported annual revenue, used for segmentation and prioritization" }
    int owner_id {
      description = "Sales rep who owns this account"
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
