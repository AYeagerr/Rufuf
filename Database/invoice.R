# INVOICE FUNCTIONS



# Modified add_invoice function to create empty invoices with only phone number and user_id
create_invoice <- function(phone_number, date = as.character(Sys.Date())) {
  user_id<-get_user_by_phone(phone_number)
  if(is.null(user_id)){
    add_user(phone_number)
    user_id<-get_user_by_phone(phone_number)
  }
  conn <- get_connection()
  
  # Insert a new invoice with phone_number, user_id, and date
  # Other values are set to NULL or default values
  query <- "INSERT INTO Invoice (phone_number, user_id, tax, min_value, max_value, total, date) 
            VALUES (?, ?, 0, 0, 0, 0, ?)"
  
  result <- dbExecute(conn, query, params = list(phone_number, user_id, date))
  
  # Get the ID of the newly created invoice
  invoice_id <- dbGetQuery(conn, "SELECT last_insert_rowid() as id")[1, "id"]
  
  dbDisconnect(conn)
  return(invoice_id)
}



Finalize_invoice <- function(invoice_id) {
  conn <- get_connection()
  on.exit(dbDisconnect(conn), add = TRUE)
  
  # 1) Compute subtotal
  subtotal_q <- "
    SELECT 
      SUM(i.price * ii.quantity)    AS subtotal
    FROM Item_Invoices ii
    JOIN Item i ON ii.item_id = i.item_id
    WHERE ii.invoice_id = ?
  "
  sub_res <- dbGetQuery(conn, subtotal_q, params = list(invoice_id))
  subtotal <- ifelse(is.na(sub_res$subtotal), 0, sub_res$subtotal)
  
  # 2) Find min & max item price on this invoice
  minmax_q <- "
    SELECT
      MIN(i.price) AS min_price,
      MAX(i.price) AS max_price
    FROM Item_Invoices ii
    JOIN Item i ON ii.item_id = i.item_id
    WHERE ii.invoice_id = ?
  "
  mm_res <- dbGetQuery(conn, minmax_q, params = list(invoice_id))
  # if no items, these come back as NA
  min_val <- ifelse(is.na(mm_res$min_price), 0, mm_res$min_price)
  max_val <- ifelse(is.na(mm_res$max_price), 0, mm_res$max_price)
  
  
  # 3) Compute tax & total
  tax_rate <- 0.15
  taxes    <- subtotal * tax_rate
  total    <- subtotal + taxes
  
  # 4) Update the Invoice row
  update_q <- "
    UPDATE Invoice
       SET tax       = ?,
           total     = ?,
           min_value = ?,
           max_value = ?
     WHERE invoice_id = ?
  "
  dbExecute(conn, update_q,
            params = list(taxes, total, min_val, max_val, invoice_id))
  
  # 5) Return the grand total
  return(total)
}


# Get invoice by ID
get_invoice <- function(invoice_id) {
  conn <- get_connection()
  query <- "SELECT * FROM Invoice WHERE invoice_id = ?"
  result <- dbGetQuery(conn, query, params = list(invoice_id))
  dbDisconnect(conn)
  return(result)
}


# Get all invoices
get_all_invoices <- function() {
  conn <- get_connection()
  query <- "SELECT * FROM Invoice"
  result <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(result)
}

# Get invoices by phone number (exact match)
get_invoices_by_phone <- function(phone) {
  conn <- get_connection()
  query <- "SELECT * FROM Invoice WHERE phone_number = ?"
  result <- dbGetQuery(conn, query, params = list(phone))
  dbDisconnect(conn)
  return(result)
}

# Get invoices by user
get_user_invoices <- function(user_id) {
  conn <- get_connection()
  query <- "SELECT * FROM Invoice WHERE user_id = ?"
  result <- dbGetQuery(conn, query, params = list(user_id))
  dbDisconnect(conn)
  return(result)
}


# Update invoice
update_invoice <- function(invoice_id, phone_number = NULL,
                           min_value = NULL, max_value = NULL, total = NULL) {
  conn <- get_connection()
  
  # Build dynamic query based on provided parameters
  updates <- c()
  params <- list()
  
  if (!is.null(phone_number)) {
    updates <- c(updates, "phone_number = ?")
    params <- c(params, phone_number)
    
    # Look up user ID based on phone number
    id <- get_user_by_phone(phone_number)
    
    # Only update user_id if we found a matching user else create a new one
    if (is.null(id)) {
      add_user(phone_number)
      id<-get_user_by_phone(phone_number)
    }
    updates <- c(updates, "user_id = ?")
    params <- c(params, id)
  }
  if (!is.null(min_value)) {
    updates <- c(updates, "min_value = ?")
    params <- c(params, min_value)
  }
  if (!is.null(max_value)) {
    updates <- c(updates, "max_value = ?")
    params <- c(params, max_value)
  }
  if (!is.null(total)) {
    updates <- c(updates, "total = ?")
    params <- c(params, total)
  }
  
  if (length(updates) == 0) {
    dbDisconnect(conn)
    return(0)  # No updates to make
  }
  
  query <- paste("UPDATE Invoice SET", paste(updates, collapse = ", "), "WHERE invoice_id = ?")
  params <- c(params, invoice_id)
  
  result <- dbExecute(conn, query, params = params)
  dbDisconnect(conn)
  Finalize_invoice(invoice_id)
  return(result)
}


# Delete invoice
delete_invoice <- function(invoice_id) {
  conn <- get_connection()
  
  # First delete related records in Item_Invoices
  delete_query <- "DELETE FROM Item_Invoices WHERE invoice_id = ?"
  dbExecute(conn, delete_query, params = list(invoice_id))
  
  # Then delete the invoice
  query <- "DELETE FROM Invoice WHERE invoice_id = ?"
  result <- dbExecute(conn, query, params = list(invoice_id))
  
  dbDisconnect(conn)
  return(result)
}