# SETTINGS FUNCTIONS

# Initialize settings table
init_settings <- function() {
  conn <- get_connection()
  
  # Create settings table if it doesn't exist
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS Settings (
      setting_id INTEGER PRIMARY KEY AUTOINCREMENT,
      setting_key TEXT UNIQUE,
      setting_value TEXT,
      setting_type TEXT,
      last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  # Insert default settings if they don't exist
  default_settings <- list(
    list("store_name", "Rufuf - رفوف", "text"),
    list("store_slogan", "", "text"),
    list("logo_path", "www/images/Logo.png", "text"),
    list("theme_name", "flatly", "text"),
    list("primary_color", "#2E86C1", "color"),
    list("secondary_color", "#27AE60", "color"),
    list("success_color", "#27AE60", "color"),
    list("info_color", "#3498DB", "color"),
    list("warning_color", "#F39C12", "color"),
    list("danger_color", "#E74C3C", "color")
  )
  
  for (setting in default_settings) {
    dbExecute(conn, "
      INSERT OR IGNORE INTO Settings (setting_key, setting_value, setting_type)
      VALUES (?, ?, ?)
    ", params = setting)
  }
  
  dbDisconnect(conn)
}

# Get all settings
get_all_settings <- function() {
  conn <- get_connection()
  query <- "SELECT * FROM Settings"
  result <- dbGetQuery(conn, query)
  dbDisconnect(conn)
  return(result)
}

# Get a specific setting
get_setting <- function(key) {
  conn <- get_connection()
  query <- "SELECT setting_value FROM Settings WHERE setting_key = ?"
  result <- dbGetQuery(conn, query, params = list(key))
  dbDisconnect(conn)
  if (nrow(result) > 0) {
    return(result$setting_value[1])
  }
  return(NULL)
}

# Update a setting
update_setting <- function(key, value) {
  conn <- get_connection()
  query <- "
    UPDATE Settings 
    SET setting_value = ?, last_updated = CURRENT_TIMESTAMP 
    WHERE setting_key = ?
  "
  result <- dbExecute(conn, query, params = list(value, key))
  dbDisconnect(conn)
  return(result)
}

# Get theme settings
get_theme_settings <- function() {
  settings <- get_all_settings()
  theme_settings <- settings[settings$setting_type == "color" | settings$setting_key == "theme_name", ]
  return(theme_settings)
}

# Get store information
get_store_info <- function() {
  settings <- get_all_settings()
  store_info <- settings[settings$setting_key %in% c("store_name", "store_slogan", "logo_path"), ]
  return(store_info)
} 