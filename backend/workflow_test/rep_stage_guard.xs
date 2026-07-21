// Proves the guarded stage transition: a rep cannot skip stages. Everything the
// throwing call needs is built inside the to_throw stack (its scope is isolated):
// a rep-owned deal in the first stage, then a jump two stages forward as that rep
// must be rejected with the guardrail error.
workflow_test "sales_pipeline_crm_rep_stage_guard" {
  tags = ["crm", "guardrail"]
  stack {
    api.call "seed" verb=POST { api_group = "Seed" } as $seed
    expect.to_be_true ($seed.seeded)

    expect.to_throw {
      stack {
        db.get "user" {
          field_name = "email"
          field_value = "alex.chen@northwind.example"
        } as $rep
        db.query "pipeline_stage" { sort = { sort_order: "asc" } } as $stages
        var $s1 { value = $stages[0] }
        var $s3 { value = $stages[2] }
        db.add "account" {
          data = { name: "Guardrail Test Co", owner_id: $rep.id }
        } as $acct
        function.call "create_deal" {
          input = { name: "Guardrail Deal", account_id: $acct.id, owner_id: $rep.id, stage_id: $s1.id, amount: 50000 }
        } as $deal
        function.call "advance_deal" {
          input = { deal_id: $deal.id, target_stage_id: $s3.id, actor_id: $rep.id, actor_role: "rep" }
        } as $bad
      }
      exception = "Reps can't skip stages; advance one at a time"
    }
  }
  guid = "nGWMvKpUKpdC0EuZx5hpuMGk_Lc"
}
