# ITEM_INVOICES FUNCTIONS
# Add item to invoice with improved error handling
add_item_to_invoice <- function(invoice_id, item_id, quantity) {
  # Input validation
  if (is.null(invoice_id) || !is.numeric(invoice_id) || invoice_id <= 0) {
    message("Invalid invoice ID")
    return(0)
  }
  
  if (is.null(item_id) || !is.numeric(item_id) || item_id <= 0) {
    message("Invalid item ID")
    return(0)
  }
  
  if (is.null(quantity) || !is.numeric(quantity) || quantity <= 0) {
    message("Quantity must be a positive number")
    return(0)
  }
  
  # Main processing with error handling
  tryCatch({
    item <- get_item(item_id)
    invoice <- get_invoice(invoice_id)
    
    if (nrow(item) == 0) {
      message("Item not found with ID: ", item_id)
      return(0)
    }
    
    if (nrow(invoice) == 0) {
      message("Invoice not found with ID: ", invoice_id)
      return(0)
    }
    
    if (item$quantity[1] < quantity) {
      message("Not enough quantity available. Requested: ", quantity, ", Available: ", item$quantity[1])
      return(0)
    }
    
    conn <- get_connection()
    on.exit(dbDisconnect(conn), add = TRUE)
    
    exists_query <- "
      SELECT quantity
      FROM Item_Invoices
      WHERE invoice_id = ? AND item_id = ?
    "
    existing <- dbGetQuery(conn, exists_query, params = list(invoice_id, item_id))
    
    if (nrow(existing) > 0) {
      update_invoice_q <- "
        UPDATE Item_Invoices
        SET quantity = quantity + ?
        WHERE invoice_id = ? AND item_id = ?
        RETURNING ii_id
      "
      result <- dbGetQuery(conn, update_invoice_q, params = list(quantity, invoice_id, item_id))$ii_id
    } else {
      insert_query <- "
        INSERT INTO Item_Invoices (invoice_id, item_id, quantity)
        VALUES (?, ?, ?) 
        RETURNING ii_id
      "
      result <- dbGetQuery(conn, insert_query, params = list(invoice_id, item_id, quantity))$ii_id
    }
    
    stock_update_q <- "
      UPDATE Item
      SET quantity_sold = quantity_sold + ?, quantity = quantity - ?
      WHERE item_id = ?
    "
    dbExecute(conn, stock_update_q, params = list(quantity, quantity, item_id))
    
    check_restock_needed(item_id)
    return(result)
  }, error = function(e) {
    message("Error adding item to invoice: ", e$message)
    return(0)
  })
}

# Get items in an invoice
get_invoice_items <- function(invoice_id) {
  conn <- get_connection()
  query <- "
    SELECT ii.ii_id, ii.invoice_id, ii.item_id, ii.quantity, 
           i.item_name, i.price, (i.price * ii.quantity) as subtotal
    FROM Item_Invoices ii
    JOIN Item i ON ii.item_id = i.item_id
    WHERE ii.invoice_id = ?
  "
  result <- dbGetQuery(conn, query, params = list(invoice_id))
  dbDisconnect(conn)
  return(result)
}
# Update item quantity in invoice
update_invoice_item_quantity <- function(ii_id, new_quantity) {
  conn <- get_connection()
  
  item_info_query <- "
    SELECT item_id, quantity as current_quantity 
    FROM Item_Invoices 
    WHERE ii_id = ?
  "
  item_info <- dbGetQuery(conn, item_info_query, params = list(ii_id))
  
  if (nrow(item_info) == 0) {
    dbDisconnect(conn)
    return(0)
  }
  
  quantity_diff <- new_quantity - item_info$current_quantity
  if (get_item(item_info$item_id)$quantity[1] < quantity_diff) {
    print("Not enough quantity")
    dbDisconnect(conn)
    return(0)
  }
  
  dbExecute(conn, "UPDATE Item_Invoices SET quantity = ? WHERE ii_id = ?", params = list(new_quantity, ii_id))
  
  dbExecute(conn, "
    UPDATE Item
    SET quantity_sold = quantity_sold + ?, quantity = quantity - ?
    WHERE item_id = ?
  ", params = list(quantity_diff, quantity_diff, item_info$item_id))
  
  dbDisconnect(conn)
  check_restock_needed(item_info$item_id)
  return(1)
}

# Remove item from invoice
remove_item_from_invoice <- function(ii_id) {
  conn <- get_connection()
  on.exit({ if (dbIsValid(conn)) dbDisconnect(conn) }, add = TRUE)
  
  dbBegin(conn)
  
  item_info <- dbGetQuery(conn, "
    SELECT item_id, quantity
    FROM Item_Invoices
    WHERE ii_id = ?
  ", params = list(ii_id))
  
  if (nrow(item_info) == 0) {
    dbRollback(conn)
    return(0)
  }
  
  item_info <- item_info[1, ]
  
  dbExecute(conn, "DELETE FROM Item_Invoices WHERE ii_id = ?", params = list(ii_id))
  
  dbExecute(conn, "
    UPDATE Item
    SET quantity = quantity + ?, quantity_sold = quantity_sold - ?
    WHERE item_id = ?
  ", params = list(item_info$quantity, item_info$quantity, item_info$item_id))
  
  dbCommit(conn)
  check_restock_needed(item_info$item_id)
  return(1)
}