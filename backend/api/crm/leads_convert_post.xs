// Convert a lead into an Account + Contact and (optionally) an Opportunity, then
// mark the lead converted (thin wrapper over the convert_lead function). Mirrors
// Salesforce convertLead: a converted lead produces/links an account, a contact,
// and optionally an opportunity, and is flagged IsConverted with the created ids.
query "leads/{lead_id}/convert" verb=POST {
  api_group = "Crm"
  description = "Convert a lead into an account, contact, and optional opportunity (Salesforce convertLead)."
  auth = "user"
  input {
    int lead_id { table = "lead" }
    bool create_opportunity?
    text opportunity_name?
    decimal amount?=0
    int stage_id?
  }
  stack {
    function.run "convert_lead" {
      input = {
        lead_id: $input.lead_id,
        actor_id: $auth.id,
        create_opportunity: $input.create_opportunity,
        opportunity_name: $input.opportunity_name,
        amount: $input.amount,
        stage_id: $input.stage_id
      }
    } as $result
  }
  response = $result
  guid = "iBhhH3krPS6ALThmoEZ29_GOOeA"
}
