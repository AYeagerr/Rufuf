# UTILITY FUNCTIONS

# Get inventory report
get_inventory_report <- function() {
  conn <- get_connection()
  query <- "
    SELECT 
      item_id,
      item_name,
      price,
      quantity as total_quantity,
      quantity_sold,
      (price * quantity_sold) as revenue
    FROM Item
    ORDER BY item_name
  "
  result <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(result)
}