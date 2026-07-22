// Create a deal. Snapshots probability + forecast category from the chosen stage
// (rep may override probability) and computes ExpectedRevenue, mirroring how a
// Salesforce Opportunity derives Probability/ForecastCategory from StageName.
query "deals" verb=POST {
  api_group = "Crm"
  description = "Create a deal; snapshots probability + forecast category from the stage and computes expected revenue."
  auth = "user"
  input {
    text name filters=trim
    int account_id { table = "account" }
    int stage_id { table = "pipeline_stage" }
    decimal amount?=0
    int probability?
    timestamp close_date?
    text next_step?
    text type? filters=trim|lower
    text lead_source?
  }
  stack {
    function.run "deals/create_deal" {
      description = "Create the deal, snapshotting probability/forecast from the stage and computing expected revenue"
      input = {
        name: $input.name,
        account_id: $input.account_id,
        owner_id: $auth.id,
        stage_id: $input.stage_id,
        amount: $input.amount,
        probability: $input.probability,
        close_date: $input.close_date,
        next_step: $input.next_step,
        type: $input.type,
        lead_source: $input.lead_source
      }
    } as $deal
  }
  response = $deal
  guid = "6m8GjGqVlkba-E7xF_MrK_3VDIo"
}
