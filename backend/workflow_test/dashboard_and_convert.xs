// Proves the analytics + lead-conversion outcomes against the seeded book: the
// cumulative forecast rollup reports closed-won revenue and a weighted pipeline,
// and a qualified lead converts into an account + contact + opportunity and is
// flagged converted.
workflow_test "sales_pipeline_crm_dashboard_and_convert" {
  tags = ["crm", "analytics", "e2e"]
  stack {
    api.call "seed" verb=POST { api_group = "Seed" } as $seed
    expect.to_be_true ($seed.seeded)

    // Forecast rollup over the whole seeded book.
    db.query "deal" {} as $deals
    function.call "analytics/forecast_rollup" {
      input = { deals: $deals }
    } as $forecast
    expect.to_be_greater_than ($forecast.closed_only) { value = 0 }
    expect.to_be_greater_than ($forecast.weighted_expected) { value = 0 }
    expect.to_be_greater_than ($forecast.open_pipeline) { value = 0 }

    // Convert the seeded qualified lead into account + contact + opportunity.
    db.get "user" {
      field_name = "email"
      field_value = "priya.patel@northwind.example"
    } as $rep
    db.query "lead" {
      where = $db.lead.status == "qualified"
      return = { type: "single" }
    } as $lead
    expect.to_not_be_null ($lead)

    function.call "deals/convert_lead" {
      input = { lead_id: $lead.id, actor_id: $rep.id, create_opportunity: true, opportunity_name: "Converted Opp", amount: 40000 }
    } as $converted
    expect.to_not_be_null ($converted.opportunity_id)
    expect.to_be_defined ($converted.account.id)
    expect.to_be_defined ($converted.contact.id)
    expect.to_be_true ($converted.lead.is_converted)
  }
  guid = "UbkLDXDAYWh2YM5m3S5zKYSihWY"
}
