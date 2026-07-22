table "pipeline_stage" {
  description = "Ordered stages a deal advances through in the sales pipeline, with default win odds and forecast mapping (Salesforce Stage)."
  auth = false
  schema {
    int id
    text name filters=trim { description = "Display name of the pipeline stage" }
    int sort_order { description = "Position of this stage in the pipeline sequence (lower is earlier)" }
    int default_probability?=0 { description = "Default win probability (0-100) applied to deals entering this stage" }
    enum forecast_category?="Pipeline" {
      description = "Forecast bucket deals in this stage roll into by default"
      values = ["Pipeline", "BestCase", "Commit", "Omitted", "Closed"]
    }
    bool is_closed?=false { description = "Whether reaching this stage closes the deal" }
    bool is_won?=false { description = "Whether this stage represents a won outcome" }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "sort_order"}]}
    {type: "btree", field: [{name: "name"}]}
  ]
  guid = "1tALuWWTmSPHkIbcLxZsCgpxRUw"
}
