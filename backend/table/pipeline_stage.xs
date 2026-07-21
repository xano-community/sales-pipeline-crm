table "pipeline_stage" {
  auth = false
  schema {
    int id
    text name filters=trim
    int sort_order
    int default_probability?=0
    enum forecast_category?="Pipeline" {
      values = ["Pipeline", "BestCase", "Commit", "Omitted", "Closed"]
    }
    bool is_closed?=false
    bool is_won?=false
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "sort_order"}]}
    {type: "btree", field: [{name: "name"}]}
  ]
  guid = "1tALuWWTmSPHkIbcLxZsCgpxRUw"
}
