// Mark one contact role as the deal's primary contact, demoting the others.
query "deals/{deal_id}/contact-roles/{role_id}/primary" verb=POST {
  api_group = "Crm"
  description = "Set a contact role as the deal's primary contact."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    int role_id { table = "opportunity_contact_role" }
  }
  stack {
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
    db.patch "opportunity_contact_role" {
      description = "Promote the chosen contact role to the deal's primary"
      field_name = "id"
      field_value = $input.role_id
      data = { is_primary: true }
    } as $role
  }
  response = $role
  guid = "OLUp4vLaWG3Y_ZMLwAxJ6xheGG4"
}
