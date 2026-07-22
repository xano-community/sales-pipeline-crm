table "opportunity_contact_role" {
  description = "Join table linking contacts to deals with their buying role — maps the buying committee on an opportunity (Salesforce OpportunityContactRole)."
  auth = false
  schema {
    int id
    int deal_id {
      description = "Deal the contact is participating in"
      table = "deal"
    }
    int contact_id {
      description = "Contact playing a role on the deal"
      table = "contact"
    }
    enum role?="influencer" {
      description = "The contact's role in the buying decision for this deal"
      values = ["decision_maker", "economic_buyer", "technical_buyer", "influencer", "champion", "other"]
    }
    bool is_primary?=false { description = "Whether this is the primary contact on the deal" }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "contact_id"}]}
  ]
  guid = "NvjWirgCv4wBAhRYUYY2CKXa5_A"
}
