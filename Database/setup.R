# Function to drop all tables from the database
drop_all_tables <- function() {
  conn <- get_connection()
  
  # Drop tables in reverse order of their dependencies to avoid foreign key constraint errors
  tables <- c("Item_Invoices", "Invoice", "Item", "User")
  
  for (table in tables) {
    query <- paste("DROP TABLE IF EXISTS", table)
    result <- dbExecute(conn, query)
    print(paste("Dropped table:", table))
  }
  
  dbDisconnect(conn)
  return(length(tables))  # Return the number of tables dropped
}

# Function to initialize the database schema
create_database <- function() {
  conn <- get_connection()
  
  # Create tables
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS User (
      user_id INTEGER PRIMARY KEY AUTOINCREMENT,
      phone_number TEXT
    )
  ")
  
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS Invoice (
      invoice_id INTEGER PRIMARY KEY AUTOINCREMENT,
      phone_number TEXT,
      tax REAL,
      min_value REAL,
      max_value REAL,
      total REAL,
      user_id INTEGER,
      date TEXT DEFAULT CURRENT_DATE,
      FOREIGN KEY (user_id) REFERENCES User(user_id)
    )
  ")
  
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS Item (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_name TEXT,
    price REAL,
    quantity INTEGER,
    quantity_sold INTEGER,
    expiry_date TEXT,
    restock_needed INTEGER DEFAULT 0,
    barcode TEXT UNIQUE
    )
  ")
  
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS Item_Invoices (
      ii_id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER,
      item_id INTEGER,
      quantity INTEGER,
      FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
      FOREIGN KEY (item_id) REFERENCES Item(item_id)
    )
  ")
  
  dbDisconnect(conn)
  
  # Initialize settings
  source("Database/settings.R")
  init_settings()
  
  return("Database schema created successfully.")
}

refresh_database<-function(){
  drop_all_tables()
  create_database()
}



# Function to get list of all tables in the database
get_tables <- function() {
  conn <- get_connection()  # Get the connection to the database
  
  # Query to get the list of tables
  query <- "SELECT name FROM sqlite_master WHERE type = 'table';"
  
  # Execute the query
  tables <- dbGetQuery(conn, query)
  
  # Close the connection
  dbDisconnect(conn)
  
  # Return the list of tables
  return(tables)
}

# Call the function to print the tables
print(get_tables())
