table "lead" {
  description = "Unqualified prospects at the top of the funnel, before conversion into an account/contact/deal (Salesforce Lead)."
  auth = false
  schema {
    int id
    text first_name filters=trim { description = "Lead's first name" }
    text last_name filters=trim { description = "Lead's last name" }
    text company filters=trim { description = "Company the lead is associated with" }
    email email? filters=trim|lower {
      description = "Lead's email address"
      sensitive = true
    }
    text lead_source? { description = "Marketing/sales channel the lead came from" }
    enum status?="new" {
      description = "Where the lead sits in the qualification workflow"
      values = ["new", "working", "nurturing", "qualified", "unqualified", "converted"]
    }
    enum rating?="warm" {
      description = "Sales interest/quality rating of the lead"
      values = ["hot", "warm", "cold"]
    }
    bool is_converted?=false { description = "Whether the lead has been converted into CRM records" }
    int converted_account_id? {
      description = "Account created when the lead was converted"
      table = "account"
    }
    int converted_contact_id? {
      description = "Contact created when the lead was converted"
      table = "contact"
    }
    int converted_opportunity_id? {
      description = "Deal/opportunity created when the lead was converted"
      table = "deal"
    }
    timestamp converted_at? { description = "When the lead was converted" }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "is_converted"}]}
  ]
  guid = "EnMJD5_d2hvY6MucccGwWSezxbs"
}
