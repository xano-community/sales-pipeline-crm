// Full deal detail: the deal, its account/owner/stage, contact roles (with the
// contact), the activity timeline, and the stage-change history.
query "deals/{deal_id}" verb=GET {
  api_group = "Crm"
  description = "Deal detail with account, owner, contact roles, activities, and stage history."
  auth = "user"
  input {
    int deal_id { table = "deal" }
  }
  stack {
    db.get "deal" {
      field_name = "id"
      field_value = $input.deal_id
    } as $deal
    precondition ($deal != null) {
      error_type = "notfound"
      error = "Deal not found"
    }
    db.get "account" {
      field_name = "id"
      field_value = $deal.account_id
    } as $account
    db.get "pipeline_stage" {
      field_name = "id"
      field_value = $deal.stage_id
    } as $stage
    db.get "user" {
      field_name = "id"
      field_value = $deal.owner_id
    } as $owner
    db.query "opportunity_contact_role" {
      where = $db.opportunity_contact_role.deal_id == $input.deal_id
      join = {
        contact: { table: "contact", where: $db.opportunity_contact_role.contact_id == $db.contact.id }
      }
      eval = {
        contact_first: $db.contact.first_name,
        contact_last: $db.contact.last_name,
        contact_title: $db.contact.title
      }
    } as $roles
    db.query "activity" {
      where = $db.activity.deal_id == $input.deal_id
      sort = { created_at: "desc" }
    } as $activities
    db.query "deal_stage_history" {
      where = $db.deal_stage_history.deal_id == $input.deal_id
      sort = { changed_at: "asc" }
    } as $history
  }
  response = {
    deal: $deal,
    account: $account,
    stage: $stage,
    owner: { id: $owner.id, name: $owner.name, email: $owner.email },
    contact_roles: $roles,
    activities: $activities,
    stage_history: $history
  }
  guid = "d_81fA8EcQQZZZMa-uDH07IgCps"
}
