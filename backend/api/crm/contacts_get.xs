// List contacts, optionally filtered to one account.
query "contacts" verb=GET {
  api_group = "Crm"
  description = "List contacts, optionally filtered by account_id."
  auth = "user"
  input {
    int account_id?
  }
  stack {
    db.query "contact" {
      where = $db.contact.account_id ==? $input.account_id
      sort = { last_name: "asc" }
    } as $contacts
  }
  response = $contacts
  guid = "NjKBQSF6OtOaENCxI9378-pf1AM"
}
