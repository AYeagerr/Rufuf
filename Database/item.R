# ITEM FUNCTIONS
# Add a new item
add_item <- function(item_name, price, quantity, quantity_sold = 0, expiry_date = Sys.Date() + 30, barcode) {
  # Input validation
  if (is.null(item_name) || nchar(trimws(item_name)) == 0) {
    stop("Item name is required")
  }
  
  if (is.null(price) || !is.numeric(price) || price < 0) {
    stop("Price must be a non-negative number")
  }
  
  if (is.null(quantity) || !is.numeric(quantity) || quantity < 0) {
    stop("Quantity must be a non-negative number")
  }
  
  if (is.null(barcode) || nchar(trimws(barcode)) == 0) {
    stop("Barcode is required")
  }
  
  # Database connection with error handling
  tryCatch({
    conn <- get_connection()
    on.exit(dbDisconnect(conn), add = TRUE)
    
    # Check for existing barcode
    existing <- get_item_by_barcode(barcode)
    if (nrow(existing) > 0) {
      stop("Barcode already exists: ", barcode)
    }
    
    query <- "
      INSERT INTO Item (item_name, price, quantity, quantity_sold, expiry_date, restock_needed, barcode)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      RETURNING item_id
    "
    restock_flag <- ifelse(quantity == 0 || quantity < 5, 1, 0)
    new_id <- dbGetQuery(conn, query,
                        params = list(item_name, price, quantity, quantity_sold, expiry_date, restock_flag, barcode)
    )$item_id
    
    return(new_id)
  }, error = function(e) {
    message("Error adding item: ", e$message)
    return(NULL)
  })
}


# Get item by ID
get_item <- function(item_id) {
  conn <- get_connection()
  query <- "SELECT * FROM Item WHERE item_id = ?"
  result <- dbGetQuery(conn, query, params = list(item_id))
  dbDisconnect(conn)
  return(result)
}

# Get item by barcode
get_item_by_barcode <- function(barcode) {
  conn <- get_connection()
  query <- "SELECT * FROM Item WHERE barcode = ?"
  result <- dbGetQuery(conn, query, params = list(barcode))
  dbDisconnect(conn)
  return(result)
}

# Get items by name
search_items_by_name <- function(name) {
  conn <- get_connection()
  on.exit(dbDisconnect(conn), add = TRUE)
  query <- "SELECT * FROM Item WHERE item_name LIKE ?"
  result <- dbGetQuery(conn, query, params = list(paste0("%", name, "%")))
  return(result)
}

# Get all items
get_all_items <- function() {
  conn <- get_connection()
  query <- "SELECT * FROM Item"
  result <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(result)
}


# Update item
update_item <- function(item_id, item_name = NULL, price = NULL, quantity = NULL,
                        quantity_sold = NULL, expiry_date = NULL, restock_needed = NULL) {
  conn <- get_connection()
  
  # Build dynamic update query
  updates <- c()
  params <- list()
  
  if (!is.null(item_name)) {
    updates <- c(updates, "item_name = ?")
    params <- c(params, item_name)
  }
  if (!is.null(price)) {
    updates <- c(updates, "price = ?")
    params <- c(params, price)
  }
  if (!is.null(quantity)) {
    updates <- c(updates, "quantity = ?")
    params <- c(params, quantity)
  }
  if (!is.null(quantity_sold)) {
    updates <- c(updates, "quantity_sold = ?")
    params <- c(params, quantity_sold)
  }
  if (!is.null(expiry_date)) {
    updates <- c(updates, "expiry_date = ?")
    params <- c(params, expiry_date)
  }
  if (!is.null(restock_needed)) {
    updates <- c(updates, "restock_needed = ?")
    params <- c(params, restock_needed)
  }
  
  if (length(updates) == 0) {
    dbDisconnect(conn)
    return(0)
  }
  
  query <- paste("UPDATE Item SET", paste(updates, collapse = ", "), "WHERE item_id = ?")
  params <- c(params, item_id)
  
  result <- dbExecute(conn, query, params = params)
  dbDisconnect(conn)
  return(result)
}



# Delete item
delete_item <- function(item_id) {
  conn <- get_connection()
  query <- "DELETE FROM Item WHERE item_id = ?"
  result <- dbExecute(conn, query, params = list(item_id))
  dbDisconnect(conn)
  return(result)
}


# Handle Expiry Date
get_expired_items <- function() {
  conn <- get_connection()
  query <- "SELECT * FROM Item WHERE expiry_date < DATE('now')"
  result <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(result)
}

check_restock_needed <- function(item_id) {
  conn <- get_connection()
  query <- "SELECT restock_needed FROM Item WHERE item_id = ?"
  result <- dbGetQuery(conn, query, params = list(item_id))
  dbDisconnect(conn)
  return(result$restock_needed[1])
}

# Update item quantity with improved error handling
update_item_quantity <- function(item_id, new_quantity) {
  if (is.null(item_id) || !is.numeric(item_id)) {
    message("Invalid item ID")
    return(0)
  }
  
  if (is.null(new_quantity) || !is.numeric(new_quantity) || new_quantity < 0) {
    message("Quantity must be a non-negative number")
    return(0)
  }
  
  tryCatch({
    conn <- get_connection()
    on.exit(dbDisconnect(conn), add = TRUE)
    
    # Check if item exists
    item <- get_item(item_id)
    if (nrow(item) == 0) {
      message("Item not found with ID: ", item_id)
      return(0)
    }
    
    # Update the quantity
    query_update <- "UPDATE Item SET quantity = ? WHERE item_id = ?"
    result <- dbExecute(conn, query_update, params = list(new_quantity, item_id))
    
    # Check the new quantity
    query_select <- "SELECT quantity FROM Item WHERE item_id = ?"
    res <- dbGetQuery(conn, query_select, params = list(item_id))
    
    # Update restock_needed based on the new quantity
    if (nrow(res) > 0) {
      restock_needed <- as.integer(res$quantity[1] == 0 || res$quantity[1] < 5)
      dbExecute(conn, "UPDATE Item SET restock_needed = ? WHERE item_id = ?", 
                params = list(restock_needed, item_id))
    }
    
    return(result)
  }, error = function(e) {
    message("Error updating item quantity: ", e$message)
    return(0)
  })
}