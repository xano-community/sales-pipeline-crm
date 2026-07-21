table "deal" {
  auth = false
  schema {
    int id
    text name filters=trim
    int account_id {
      table = "account"
    }
    int owner_id {
      table = "user"
    }
    decimal amount?=0
    int probability?=0
    decimal expected_revenue?=0
    int stage_id {
      table = "pipeline_stage"
    }
    enum forecast_category?="Pipeline" {
      values = ["Pipeline", "BestCase", "Commit", "Omitted", "Closed"]
    }
    timestamp close_date?
    timestamp actual_close_date?
    enum status?="open" {
      values = ["open", "won", "lost"]
    }
    bool is_closed?=false
    bool is_won?=false
    text lost_reason?
    text next_step?
    enum type?="new_business" {
      values = ["new_business", "existing_business"]
    }
    text lead_source?
    timestamp last_activity_at?
    timestamp created_at?=now
    timestamp updated_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "account_id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
    {type: "btree", field: [{name: "stage_id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
  guid = "cJQX-rebEWs0LMYI0CwRFSpUULE"
}
