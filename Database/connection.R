# Required library for SQLite database connection
library(RSQLite)

# Database configuration
DB_PATH <- "inventory_system.db"

# Function to get a database connection
get_connection <- function() {
  conn <- dbConnect(RSQLite::SQLite(), DB_PATH)
  return(conn)
}