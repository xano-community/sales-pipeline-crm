// End-to-end deal lifecycle through the shared logic functions (the same code the
// endpoints call): create a deal (probability snapshots from the stage), advance
// it (re-snapshot + stage history), then win it — asserting the Salesforce-
// mirrored state at each step, against the seeded pipeline.
workflow_test "sales_pipeline_crm_deal_lifecycle" {
  tags = ["crm", "e2e"]
  stack {
    api.call "seed" verb=POST { api_group = "Seed" } as $seed
    expect.to_be_true ($seed.seeded)

    db.get "user" {
      field_name = "email"
      field_value = "morgan.lee@northwind.example"
    } as $mgr
    expect.to_not_be_null ($mgr)

    db.query "pipeline_stage" { sort = { sort_order: "asc" } } as $stages
    var $s1 { value = $stages[0] }
    var $s2 { value = $stages[1] }

    db.add "account" {
      data = { name: "Lifecycle Test Co", owner_id: $mgr.id }
    } as $acct

    function.call "deals/create_deal" {
      input = { name: "Lifecycle Deal", account_id: $acct.id, owner_id: $mgr.id, stage_id: $s1.id, amount: 100000 }
    } as $deal
    expect.to_equal ($deal.probability) { value = $s1.default_probability }
    expect.to_be_greater_than ($deal.expected_revenue) { value = -1 }

    function.call "deals/advance_deal" {
      input = { deal_id: $deal.id, target_stage_id: $s2.id, actor_id: $mgr.id, actor_role: "manager" }
    } as $adv
    expect.to_equal ($adv.stage_id) { value = $s2.id }
    expect.to_equal ($adv.probability) { value = $s2.default_probability }

    function.call "deals/win_deal" {
      input = { deal_id: $deal.id, actor_id: $mgr.id, actor_role: "manager" }
    } as $won
    expect.to_be_true ($won.is_won)
    expect.to_be_true ($won.is_closed)
    expect.to_equal ($won.status) { value = "won" }
    expect.to_equal ($won.forecast_category) { value = "Closed" }
    expect.to_equal ($won.probability) { value = 100 }

    // Stage history recorded each transition (open row + advance + win = 3).
    db.query "deal_stage_history" {
      where = $db.deal_stage_history.deal_id == $deal.id
      return = { type: "count" }
    } as $history_count
    expect.to_be_greater_than ($history_count) { value = 2 }
  }
  guid = "0qqoCA-roz9lSTxybRA3J6vHkTs"
}
