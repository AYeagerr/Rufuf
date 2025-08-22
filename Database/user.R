# USER FUNCTIONS
# Add a new user
add_user <- function(phone_number) {
  conn <- get_connection()
  query <- "INSERT INTO User (phone_number) VALUES (?) RETURNING user_id"
  result <- dbGetQuery(conn, query, params = list(phone_number))$user_id
  dbDisconnect(conn)
  return(result)
}

# Get user by ID
get_user <- function(user_id) {
  conn <- get_connection()
  query <- "SELECT * FROM User WHERE user_id = ?"
  result <- dbGetQuery(conn, query, params = list(user_id))
  dbDisconnect(conn)
  return(result)
}
# Function to get a user by phone number and return their ID
get_user_by_phone <- function(phone_number) {
  conn <- get_connection()
  
  query <- "SELECT user_id FROM User WHERE phone_number = ?"
  result <- dbGetQuery(conn, query, params = list(phone_number))
  
  dbDisconnect(conn)
  
  if (nrow(result) > 0) {
    return(result$user_id[1])  # Return the user_id
  } else {
    return(NULL)  # Return NULL if no user found with that phone number
  }
}
# Update user
update_user <- function(user_id, phone_number) {
  conn <- get_connection()
  query <- "UPDATE User SET phone_number = ? WHERE user_id = ?"
  result <- dbExecute(conn, query, params = list(phone_number, user_id))
  dbDisconnect(conn)
  return(result)
}
# Delete user
delete_user <- function(user_id) {
  conn <- get_connection()
  query <- "DELETE FROM User WHERE user_id = ?"
  result <- dbExecute(conn, query, params = list(user_id))
  dbDisconnect(conn)
  return(result)
}