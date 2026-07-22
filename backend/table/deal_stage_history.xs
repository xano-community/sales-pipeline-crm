table "deal_stage_history" {
  description = "Audit trail of every pipeline-stage change on a deal — powers velocity and stage-duration reporting (Salesforce OpportunityHistory)."
  auth = false
  schema {
    int id
    int deal_id {
      description = "Deal whose stage change is being recorded"
      table = "deal"
    }
    int from_stage_id? {
      description = "Stage the deal moved out of (null for the initial stage)"
      table = "pipeline_stage"
    }
    int to_stage_id {
      description = "Stage the deal moved into"
      table = "pipeline_stage"
    }
    decimal amount_snapshot?=0 { description = "Deal amount captured at the moment of the stage change" }
    int probability_snapshot?=0 { description = "Deal win probability captured at the moment of the stage change" }
    int changed_by {
      description = "User who performed the stage change"
      table = "user"
    }
    int days_in_previous_stage?=0 { description = "How many days the deal spent in the prior stage before this move" }
    timestamp changed_at?=now { description = "When the stage change occurred" }
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "changed_at", op: "desc"}]}
  ]
  guid = "hvjdp5FeYeqVPyktig2FDCPMqRc"
}
