// Core lead-conversion logic (shared by the endpoint and the tests). Creates or
// links an account + contact and optionally an opportunity, then flags the lead
// converted with the created record ids — Salesforce convertLead.
function "deals/convert_lead" {
  description = "Convert a lead into an account, contact, and optional opportunity (Salesforce convertLead)."
  input {
    int lead_id
    int actor_id
    bool create_opportunity?
    text opportunity_name?
    decimal amount?=0
    int stage_id?
  }
  stack {
    db.get "lead" {
      description = "Load the lead being converted"
      field_name = "id"
      field_value = $input.lead_id
    } as $lead
    group {
      description = "Validate the lead is convertible"
      stack {
        // Lead must exist
        precondition ($lead != null) {
          error_type = "notfound"
          error = "Lead not found"
        }
        // Conversion is one-way; don't re-convert
        precondition ($lead.is_converted == false) {
          error_type = "inputerror"
          error = "Lead is already converted"
        }
      }
    }
    group {
      description = "Create or link the account and contact"
      stack {
        db.get "account" {
          description = "Look for an existing account matching the lead's company"
          field_name = "name"
          field_value = $lead.company
        } as $account
        // Create the account only if the company isn't already on file
        conditional {
          if ($account == null) {
            db.add "account" {
              description = "Create a new account from the lead's company"
              data = { name: $lead.company, owner_id: $input.actor_id }
            } as $account
          }
        }
        db.add "contact" {
          description = "Create the contact from the lead's person details"
          data = {
            account_id: $account.id,
            first_name: $lead.first_name,
            last_name: $lead.last_name,
            email: $lead.email
          }
        } as $contact
      }
    }
    var $opp_id {
      description = "Converted opportunity id, populated only if an opportunity is created"
      value = null
    }
    // Optionally spin up an opportunity as part of the conversion
    conditional {
      if ($input.create_opportunity == true) {
        group {
          description = "Create the converted opportunity"
          stack {
            db.query "pipeline_stage" {
              description = "Resolve the requested opening stage, or the earliest stage by sort order"
              where = $db.pipeline_stage.id ==? $input.stage_id
              sort = { sort_order: "asc" }
              return = { type: "single" }
            } as $stage
            var $prob {
              description = "Snapshot the stage's default probability onto the new deal"
              value = $stage.default_probability
            }
            function.run "calc/calc_expected_revenue" {
              description = "Compute weighted expected revenue for the new deal"
              input = { amount: $input.amount, probability: $prob }
            } as $er
            db.add "deal" {
              description = "Create the opportunity for the converted lead"
              data = {
                name: ($input.opportunity_name == null ? ($lead.company ~ " - New Opportunity") : $input.opportunity_name),
                account_id: $account.id,
                owner_id: $input.actor_id,
                amount: $input.amount,
                probability: $prob,
                expected_revenue: $er,
                stage_id: $stage.id,
                forecast_category: $stage.forecast_category,
                status: "open",
                is_closed: $stage.is_closed,
                is_won: $stage.is_won,
                lead_source: $lead.lead_source,
                updated_at: now
              }
            } as $deal
            db.add "deal_stage_history" {
              description = "Write the opening stage-history row for the new opportunity"
              data = {
                deal_id: $deal.id,
                from_stage_id: null,
                to_stage_id: $stage.id,
                amount_snapshot: $input.amount,
                probability_snapshot: $prob,
                changed_by: $input.actor_id,
                days_in_previous_stage: 0,
                changed_at: now
              }
            }
            db.add "opportunity_contact_role" {
              description = "Link the converted contact to the deal as primary decision maker"
              data = { deal_id: $deal.id, contact_id: $contact.id, role: "decision_maker", is_primary: true }
            }
            var.update $opp_id {
              description = "Record the created opportunity id for the response and lead link"
              value = $deal.id
            }
          }
        }
      }
    }
    db.patch "lead" {
      description = "Flag the lead converted and link the created account, contact, and opportunity"
      field_name = "id"
      field_value = $input.lead_id
      data = {
        status: "converted",
        is_converted: true,
        converted_account_id: $account.id,
        converted_contact_id: $contact.id,
        converted_opportunity_id: $opp_id,
        converted_at: now
      }
    } as $updated_lead
  }
  response = {
    lead: $updated_lead,
    account: $account,
    contact: $contact,
    opportunity_id: $opp_id
  }
  guid = "NbfmhqZJ0zvvkjqmIKTjxCWbGD8"
}
