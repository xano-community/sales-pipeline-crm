// Create an account owned by the authenticated user.
query "accounts" verb=POST {
  api_group = "Crm"
  description = "Create an account."
  auth = "user"
  input {
    text name filters=trim
    text industry?
    text website?
    decimal annual_revenue?=0
  }
  stack {
    db.add "account" {
      data = {
        name: $input.name,
        industry: $input.industry,
        website: $input.website,
        annual_revenue: $input.annual_revenue,
        owner_id: $auth.id
      }
    } as $account
  }
  response = $account
  guid = "UuRjYGQ15r_ComRl7pbWHiuq-AI"
}
