// Lightweight reachability check for the seed API group.
query "health" verb=GET {
  api_group = "Seed"
  description = "Health check for the seed group."
  input {}
  stack {
    db.query "deal" {
      description = "Count deal rows to confirm the seed group is reachable and the DB responds"
      return = { type: "count" }
    } as $deals
  }
  response = { ok: true, deals: $deals }
  guid = "5BNDA1sENCbEJyR9xbaO1CW93qg"
}
