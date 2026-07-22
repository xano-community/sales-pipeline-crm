// The pipeline stage definitions (Salesforce OpportunityStage), in order.
query "stages" verb=GET {
  api_group = "Crm"
  description = "List pipeline stages ordered by sort_order."
  auth = "user"
  input {}
  stack {
    db.query "pipeline_stage" {
      description = "List all pipeline stages in display order"
      sort = { sort_order: "asc" }
    } as $stages
  }
  response = $stages
  guid = "lV1sSTQXZuXiRffSl9dHc6IGZ6o"
}
