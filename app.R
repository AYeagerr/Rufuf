library(shiny)
library(shinyjs)


# Source database and backend files
source("Database/connection.R")
source("Database/setup.R")
source("Database/user.R")
source("Database/item.R")
source("Database/invoice.R")
source("Database/item_invoice.R")
source("Database/utility.R")


source("ui.R")
source("server.R")


shinyApp(ui = ui, server = server)