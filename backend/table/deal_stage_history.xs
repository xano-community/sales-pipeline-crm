table "deal_stage_history" {
  auth = false
  schema {
    int id
    int deal_id {
      table = "deal"
    }
    int from_stage_id? {
      table = "pipeline_stage"
    }
    int to_stage_id {
      table = "pipeline_stage"
    }
    decimal amount_snapshot?=0
    int probability_snapshot?=0
    int changed_by {
      table = "user"
    }
    int days_in_previous_stage?=0
    timestamp changed_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "changed_at", op: "desc"}]}
  ]
  guid = "hvjdp5FeYeqVPyktig2FDCPMqRc"
}
