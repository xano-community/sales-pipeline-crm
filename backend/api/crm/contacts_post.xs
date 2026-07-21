// Create a contact under an account.
query "contacts" verb=POST {
  api_group = "Crm"
  description = "Create a contact."
  auth = "user"
  input {
    int account_id { table = "account" }
    text first_name filters=trim
    text last_name filters=trim
    email email? filters=trim|lower
    text phone?
    text title?
  }
  stack {
    db.add "contact" {
      data = {
        account_id: $input.account_id,
        first_name: $input.first_name,
        last_name: $input.last_name,
        email: $input.email,
        phone: $input.phone,
        title: $input.title
      }
    } as $contact
  }
  response = $contact
  guid = "Qmd0A6f3S-Ggbg7XvUDEkTjm6mE"
}
