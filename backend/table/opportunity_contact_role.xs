table "opportunity_contact_role" {
  auth = false
  schema {
    int id
    int deal_id {
      table = "deal"
    }
    int contact_id {
      table = "contact"
    }
    enum role?="influencer" {
      values = ["decision_maker", "economic_buyer", "technical_buyer", "influencer", "champion", "other"]
    }
    bool is_primary?=false
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "contact_id"}]}
  ]
  guid = "NvjWirgCv4wBAhRYUYY2CKXa5_A"
}
