// Create a lead.
query "leads" verb=POST {
  api_group = "Crm"
  description = "Create a lead."
  auth = "user"
  input {
    text first_name filters=trim
    text last_name filters=trim
    text company filters=trim
    email email? filters=trim|lower
    text lead_source?
    text rating? filters=trim|lower
  }
  stack {
    db.add "lead" {
      data = {
        first_name: $input.first_name,
        last_name: $input.last_name,
        company: $input.company,
        email: $input.email,
        lead_source: $input.lead_source,
        rating: ($input.rating == null ? "warm" : $input.rating),
        status: "new",
        is_converted: false
      }
    } as $lead
  }
  response = $lead
  guid = "WFEYibGhON1lRlmr0ukXwOwzxsc"
}
