table "deal" {
  description = "Sales opportunities moving through the pipeline toward a close (Salesforce Opportunity)."
  auth = false
  schema {
    int id
    text name filters=trim { description = "Deal name" }
    int account_id {
      description = "Account this deal is being sold to"
      table = "account"
    }
    int owner_id {
      description = "Sales rep who owns and is credited for this deal"
      table = "user"
    }
    decimal amount?=0 { description = "Deal value in the account's currency" }
    int probability?=0 { description = "Percent chance of winning (0-100), typically driven by the stage" }
    decimal expected_revenue?=0 { description = "Weighted expected revenue for a deal: amount * probability / 100 (Salesforce ExpectedRevenue)." }
    int stage_id {
      description = "Current pipeline stage the deal sits in"
      table = "pipeline_stage"
    }
    enum forecast_category?="Pipeline" {
      description = "Forecast bucket the deal rolls into for revenue reporting"
      values = ["Pipeline", "BestCase", "Commit", "Omitted", "Closed"]
    }
    timestamp close_date? { description = "Projected date the deal is expected to close" }
    timestamp actual_close_date? { description = "Date the deal was actually closed (won or lost)" }
    enum status?="open" {
      description = "Whether the deal is still open, won, or lost"
      values = ["open", "won", "lost"]
    }
    bool is_closed?=false { description = "Whether the deal has reached a closed stage/status" }
    bool is_won?=false { description = "Whether the deal was closed as won" }
    text lost_reason? { description = "Why the deal was lost, captured on close-lost" }
    text next_step? { description = "The next action the rep plans to take on this deal" }
    enum type?="new_business" {
      description = "Whether this is net-new business or expansion of an existing customer"
      values = ["new_business", "existing_business"]
    }
    text lead_source? { description = "Marketing/sales channel the deal originated from" }
    timestamp last_activity_at? { description = "Timestamp of the most recent logged activity on the deal" }
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
