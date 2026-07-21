// Register a sales rep or manager and return a 24h auth token.
query "signup" verb=POST {
  api_group = "Auth"
  description = "Create a user (rep or manager) and return an auth token."
  input {
    text name filters=trim
    email email filters=trim|lower
    text password filters=min:6
    text role? filters=trim|lower
  }
  stack {
    db.has "user" {
      field_name = "email"
      field_value = $input.email
    } as $exists
    precondition ($exists == false) {
      error_type = "inputerror"
      error = "Email already registered"
    }
    db.add "user" {
      data = {
        name: $input.name,
        email: $input.email,
        password: $input.password,
        role: ($input.role == null ? "rep" : $input.role)
      }
    } as $user
    security.create_auth_token {
      table = "user"
      id = $user.id
      extras = { role: $user.role }
      expiration = 86400
    } as $token
  }
  response = {
    authToken: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "cnk3zaD_IRCDkXNw6Y3wMryEfWY"
}
