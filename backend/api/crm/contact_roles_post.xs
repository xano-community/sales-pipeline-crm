// Add a contact role to a deal (Salesforce OpportunityContactRole: Role +
// IsPrimary). Setting is_primary demotes any existing primary first.
query "deals/{deal_id}/contact-roles" verb=POST {
  api_group = "Crm"
  description = "Attach a contact to a deal with a role; optionally mark it primary."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    int contact_id { table = "contact" }
    text role? filters=trim|lower
    bool is_primary?
  }
  stack {
    var $primary {
      description = "Whether this contact role should become the deal's primary"
      value = ($input.is_primary == null ? false : $input.is_primary)
    }
    // Only demote an existing primary when this role is being made primary
    conditional {
      if ($primary == true) {
        db.query "opportunity_contact_role" {
          description = "Find the deal's current primary contact role(s)"
          where = $db.opportunity_contact_role.deal_id == $input.deal_id && $db.opportunity_contact_role.is_primary == true
        } as $current_primary
        foreach ($current_primary) {
          description = "Demote each existing primary contact role"
          each as $r {
            db.patch "opportunity_contact_role" {
              description = "Clear the primary flag on the previous primary contact role"
              field_name = "id"
              field_value = $r.id
              data = { is_primary: false }
            }
          }
        }
      }
    }
    db.add "opportunity_contact_role" {
      description = "Attach the contact to the deal with its role and primary flag"
      data = {
        deal_id: $input.deal_id,
        contact_id: $input.contact_id,
        role: ($input.role == null ? "influencer" : $input.role),
        is_primary: $primary
      }
    } as $role
  }
  response = $role
  guid = "kH9m9Vxj9AGWo2D1esOKNRnEJlY"
}
