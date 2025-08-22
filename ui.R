library(shiny)
library(bslib)
library(shinyjs)
library(colourpicker)

source("scan_barcode_module.R")

# Function to get store info safely
get_store_info_safe <- function() {
  tryCatch({
    source("Database/settings.R")
    return(list(
      name = get_setting("store_name"),
      slogan = get_setting("store_slogan"),
      logo = get_setting("logo_path")
    ))
  }, error = function(e) {
    return(list(
      name = "Rufuf - رفوف",
      slogan = "",
      logo = "www/images/Logo.png"
    ))
  })
}

css_string <- "
      .main-title { 
        font-size: 2.5rem; 
        font-weight: bold; 
        margin-bottom: 2rem;
        color: #2E86C1;
      }
      .tab-pane { 
        padding-top: 2rem; 
      }
      .cart-table td, .cart-table th { 
        vertical-align: middle !important; 
      }
      .admin-panel { 
        max-width: 1100px; 
        margin: auto; 
      }
      .cashier-panel { 
        max-width: 1200px;
        margin: auto;
        background-color: #f8f9fa;
        padding: 2rem;
        border-radius: 10px;
        box-shadow: 0 0 15px rgba(0,0,0,0.1);
      }
      .logo-container { 
        text-align: center; 
        margin-bottom: 1rem; 
      }
      .logo-img { 
        max-width: 200px; 
        height: auto; 
      }
      .section-title {
        color: #2E86C1;
        font-weight: bold;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }
      .input-group {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
      }
      .input-group .section-title {
        margin-bottom: 0.5rem;
      }
      .input-group input[type='text'] {
        width: 100%;
        max-width: 350px;
      }
      .btn {
        border-radius: 5px;
        padding: 0.5rem 1rem;
        font-weight: 500;
      }
      .btn-success {
        background-color: #27AE60;
        border-color: #27AE60;
      }
      .btn-success:hover {
        background-color: #219A52;
        border-color: #219A52;
      }
      .cart-summary {
        background-color: #fff;
        padding: 1rem;
        border-radius: 5px;
        box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        width: 100%;
        min-width: unset;
        max-width: 100%;
      }
      .cart-summary .dataTable-wrapper, .cart-summary table.dataTable {
        min-width: unset;
        width: 100%;
      }
      #barcode_scanner-video_container {
        border: 1px solid #ccc;
        max-width: 100%;
        overflow: hidden;
        position: relative;
        background-color: #f5f5f5;
        border-radius: 5px;
      }
      #barcode_scanner-video {
        width: 100%;
        height: auto;
        max-height: 300px;
        object-fit: cover;
      }
      .modal-dialog {
        max-width: 800px;
      }
      .modal-body {
        max-height: 70vh;
        overflow-y: auto;
      }
      table.dataTable {
        width: 100% !important;
      }
      @media (max-width: 768px) {
        .cashier-panel {
          padding: 0.5rem;
        }
        .section-title {
          font-size: 1.1rem;
        }
        .cart-summary {
          overflow-x: auto !important;
          width: 100% !important;
          margin-bottom: 1.2rem !important;
        }
        .cart-mobile-card {
          width: 100% !important;
          min-width: 0 !important;
          margin-bottom: 1.2rem !important;
        }
        .main-title {
          font-size: 1.5rem;
        }
        .logo-img {
          max-width: 120px;
        }
        .input-group, .cart-summary, .total-section {
          font-size: 0.95rem;
        }
        .btn, .btn-lg {
          font-size: 1rem;
          padding: 0.4rem 0.8rem;
        }
        .row, .fluidRow {
          flex-direction: column !important;
        }
        .col-md-6, .col-md-4, .col-md-2, .col-md-12, .col-6, .col-12, [class^=\\'col-\\'] { width: 100% !important; max-width: 100% !important; flex: 0 0 100% !important; }
        .cart-summary .dataTable-wrapper, .cart-summary table.dataTable {
          display: none !important;
        }
        #mobile-remove-btn {
          display: block !important;
          margin-bottom: 1rem;
        }
        .cart-mobile-card {
          display: block !important;
          margin-bottom: 1.5rem;
          background: #fff;
          border-radius: 12px;
          box-shadow: 0 2px 12px rgba(0,0,0,0.10);
          padding: 1.2rem 1.2rem 1.2rem 1.2rem;
          font-size: 1.12rem;
          width: 95vw;
          max-width: 500px;
          margin-left: auto;
          margin-right: auto;
        }
        #admin_tabs-inventory .inventory-mobile-card .item-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 0.8rem;
          border-bottom: 1px solid #eee;
          padding-bottom: 0.5rem;
        }
        #admin_tabs-inventory .inventory-mobile-card .item-name {
          font-size: 1.2rem;
          color: #2E86C1;
        }
        #admin_tabs-inventory .inventory-mobile-card .item-id {
          font-size: 0.8rem;
          color: #777;
          background: #f8f8f8;
          padding: 0.2rem 0.5rem;
          border-radius: 4px;
        }
        #admin_tabs-inventory .inventory-mobile-card .item-content {
          margin-bottom: 1rem;
        }
        #admin_tabs-inventory .inventory-mobile-card .item-detail {
          margin-bottom: 0.5rem;
          padding-left: 0.5rem;
          font-size: 1.05rem;
        }
        #admin_tabs-inventory .inventory-mobile-card .item-detail .fa-barcode,
        #admin_tabs-inventory .inventory-mobile-card .item-detail .fa-tag,
        #admin_tabs-inventory .inventory-mobile-card .item-detail .fa-boxes {
          color: #2E86C1;
          margin-right: 0.3rem;
        }
      }
      @media (min-width: 769px) {
        #mobile-remove-btn {
          display: none !important;
        }
        .cart-mobile-card {
          display: none !important;
        }
      }
      #admin_tabs-inventory .inventory-mobile-card {
        display: block;
        margin: 1.2rem auto 2.2rem auto;
        background: linear-gradient(135deg, #f9fbfd 80%, #e3f6ff 100%);
        border: 2.5px solid #2E86C1;
        border-radius: 18px;
        box-shadow: 0 4px 18px rgba(44, 62, 80, 0.13);
        padding: 1.3rem 1.1rem 1.3rem 1.1rem;
        font-size: 1.13rem;
        width: 97vw;
        max-width: 520px;
        transition: box-shadow 0.2s, border 0.2s;
        margin-bottom: 1.5rem;
      }
      #admin_tabs-inventory .inventory-mobile-card:hover {
        box-shadow: 0 8px 24px rgba(44, 62, 80, 0.18);
        border-color: #27AE60;
      }
      #admin_tabs-inventory .inventory-mobile-card .item-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.8rem;
        border-bottom: 1px solid #eee;
        padding-bottom: 0.5rem;
      }
      #admin_tabs-inventory .inventory-mobile-card .item-name {
        font-size: 1.2rem;
        color: #2E86C1;
        font-weight: bold;
        letter-spacing: 0.5px;
      }
      #admin_tabs-inventory .inventory-mobile-card .item-id {
        font-size: 0.85rem;
        color: #fff;
        background: #27AE60;
        padding: 0.2rem 0.7rem;
        border-radius: 8px;
        font-weight: 500;
      }
      #admin_tabs-inventory .inventory-mobile-card .item-detail {
        margin-bottom: 0.5rem;
        padding-left: 0.5rem;
        font-size: 1.08rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }
      #admin_tabs-inventory .inventory-mobile-card .price-value {
        font-weight: 700;
        color: #27AE60;
        background: #eafaf1;
        padding: 0.1rem 0.6rem;
        border-radius: 6px;
        margin-left: 0.5rem;
      }
      #admin_tabs-inventory .inventory-mobile-card .quantity-value {
        font-weight: 700;
        color: #3498DB;
        background: #eaf3fa;
        padding: 0.1rem 0.6rem;
        border-radius: 6px;
        margin-left: 0.5rem;
      }
      #admin_tabs-inventory .inventory-mobile-card .item-detail .fa-barcode,
      #admin_tabs-inventory .inventory-mobile-card .item-detail .fa-tag,
      #admin_tabs-inventory .inventory-mobile-card .item-detail .fa-boxes {
        color: #2E86C1;
        margin-right: 0.3rem;
      }
      #admin_tabs-inventory .inventory-mobile-cards-container {
        background: #f4faff;
        padding-top: 1.5rem;
        padding-bottom: 1.5rem;
        min-height: 100vh;
      }
      /* Admin tab navigation styling for mobile */
      #admin_tabs.nav.nav-tabs {
        display: flex;
        flex-wrap: wrap;
        justify-content: flex-start;
        border-bottom: 1px solid #e0e0e0;
        margin-bottom: 1.5rem;
      }
      #admin_tabs.nav.nav-tabs > li {
        flex: 1 1 33%;
        text-align: center;
        margin-bottom: 0;
      }
      #admin_tabs.nav.nav-tabs > li > a {
        display: block;
        padding: 0.7rem 0.5rem;
        font-size: 1.1rem;
        color: #27AE60;
        border: none;
        border-radius: 0;
        background: none;
        transition: background 0.2s, color 0.2s;
      }
      #admin_tabs.nav.nav-tabs > li.active > a, #admin_tabs.nav.nav-tabs > li > a:focus, #admin_tabs.nav.nav-tabs > li > a:hover {
        color: #2E86C1;
        background: #f5faff;
        border-bottom: 2px solid #2E86C1;
        font-weight: bold;
      }
      div.inventory-mobile-card {
        display: block !important;
        margin: 1.2rem auto 2.2rem auto !important;
        background: linear-gradient(135deg, #f9fbfd 80%, #e3f6ff 100%) !important;
        border: 2.5px solid #2E86C1 !important;
        border-radius: 18px !important;
        box-shadow: 0 4px 18px rgba(44, 62, 80, 0.13) !important;
        padding: 1.3rem 1.1rem 1.3rem 1.1rem !important;
        font-size: 1.13rem !important;
        width: 97vw !important;
        max-width: 520px !important;
        transition: box-shadow 0.2s, border 0.2s !important;
        margin-bottom: 1.5rem !important;
      }
      div.inventory-mobile-card:hover {
        box-shadow: 0 8px 24px rgba(44, 62, 80, 0.18) !important;
        border-color: #27AE60 !important;
      }
      div.inventory-mobile-card .item-header {
        display: flex !important;
        justify-content: space-between !important;
        align-items: center !important;
        margin-bottom: 0.8rem !important;
        border-bottom: 1px solid #eee !important;
        padding-bottom: 0.5rem !important;
      }
      div.inventory-mobile-card .item-name {
        font-size: 1.2rem !important;
        color: #2E86C1 !important;
        font-weight: bold !important;
        letter-spacing: 0.5px !important;
      }
      div.inventory-mobile-card .item-id {
        font-size: 0.85rem !important;
        color: #fff !important;
        background: #27AE60 !important;
        padding: 0.2rem 0.7rem !important;
        border-radius: 8px !important;
        font-weight: 500 !important;
      }
      div.inventory-mobile-card .item-detail {
        margin-bottom: 0.5rem !important;
        padding-left: 0.5rem !important;
        font-size: 1.08rem !important;
        display: flex !important;
        align-items: center !important;
        gap: 0.5rem !important;
      }
      div.inventory-mobile-card .price-value {
        font-weight: 700 !important;
        color: #27AE60 !important;
        background: #eafaf1 !important;
        padding: 0.1rem 0.6rem !important;
        border-radius: 6px !important;
        margin-left: 0.5rem !important;
      }
      div.inventory-mobile-card .quantity-value {
        font-weight: 700 !important;
        color: #3498DB !important;
        background: #eaf3fa !important;
        padding: 0.1rem 0.6rem !important;
        border-radius: 6px !important;
        margin-left: 0.5rem !important;
      }
      div.inventory-mobile-card .item-detail .fa-barcode,
      div.inventory-mobile-card .item-detail .fa-tag,
      div.inventory-mobile-card .item-detail .fa-boxes {
        color: #2E86C1 !important;
        margin-right: 0.3rem !important;
      }
      div.invoice-mobile-card {
        display: block !important;
        margin: 1.2rem auto 2.2rem auto !important;
        background: linear-gradient(135deg, #f8fafd 80%, #e3f6ff 100%) !important;
        border: 2.5px solid #3498DB !important;
        border-radius: 18px !important;
        box-shadow: 0 4px 18px rgba(44, 62, 80, 0.13) !important;
        padding: 1.3rem 1.1rem 1.3rem 1.1rem !important;
        font-size: 1.13rem !important;
        width: 97vw !important;
        max-width: 520px !important;
        transition: box-shadow 0.2s, border 0.2s !important;
        margin-bottom: 1.5rem !important;
      }
      div.invoice-mobile-card:hover {
        box-shadow: 0 8px 24px rgba(44, 62, 80, 0.18) !important;
        border-color: #27AE60 !important;
      }
      div.invoice-mobile-card .invoice-id {
        font-size: 1.3rem !important;
        color: #3498DB !important;
        font-weight: bold !important;
        margin-bottom: 0.5rem !important;
      }
      div.invoice-mobile-card .invoice-detail {
        margin-bottom: 0.5rem !important;
        font-size: 1.08rem !important;
        display: flex !important;
        align-items: center !important;
        gap: 0.5rem !important;
      }
      div.invoice-mobile-card .invoice-total {
        font-weight: 700 !important;
        color: #27AE60 !important;
        background: #eafaf1 !important;
        padding: 0.1rem 0.6rem !important;
        border-radius: 6px !important;
        margin-left: 0.5rem !important;
        font-size: 1.15rem !important;
      }
      div.invoice-mobile-card .invoice-actions {
        margin-top: 1rem !important;
        display: flex !important;
        gap: 1rem !important;
        justify-content: flex-end !important;
      }
      div.invoice-mobile-card .btn {
        font-size: 1rem !important;
        padding: 0.4rem 1rem !important;
        border-radius: 6px !important;
      }
      #admin_tabs-invoices table.dataTable {
        border-radius: 12px !important;
        overflow: hidden !important;
        background: #f8fafd !important;
      }
      #admin_tabs-invoices table.dataTable thead th {
        background: #3498DB !important;
        color: #fff !important;
        font-weight: bold !important;
      }
      #admin_tabs-invoices table.dataTable tbody tr:hover {
        background: #e3f6ff !important;
      }
      .subheading {
        margin-bottom: 2.2rem !important;
        font-size: 1.15rem;
      }
      .settings-panel {
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
      }
      .settings-section {
        background: white;
        border-radius: 10px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      .settings-section h5 {
        color: #2E86C1;
        margin-bottom: 20px;
        display: flex;
        align-items: center;
        gap: 10px;
      }
      .color-settings {
        margin-top: 20px;
      }
      .color-inputs {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 15px;
        margin-top: 10px;
      }
      .current-logo {
        margin-top: 15px;
        padding: 15px;
        background: #f8f9fa;
        border-radius: 5px;
      }
      .settings-actions {
        margin-top: 20px;
        text-align: right;
      }
      @media (max-width: 768px) {
        .settings-panel {
          padding: 10px;
        }
        .settings-section {
          padding: 15px;
        }
        .color-inputs {
          grid-template-columns: 1fr;
        }
      }
"

shinyUI(fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  useShinyjs(),
  tags$head(
    tags$title("Rufuf"),
    tags$link(rel = "icon", type = "image/png", href = "images/Logo-removebg.png"),
    tags$style(HTML(css_string)),
    shinyjs::extendShinyjs(functions = c(), text = 'shinyjs.getScreenWidth = function() { Shiny.setInputValue("screen_width", window.innerWidth); }'),
    singleton(tags$script(HTML('
      $(document).on("shiny:connected", function() { setTimeout(function() { Shiny.setInputValue("screen_width", window.innerWidth); }, 200); });
      $(window).on("resize", function() { Shiny.setInputValue("screen_width", window.innerWidth); });
    ')))
  ),
  
  div(class = "logo-container", 
      img(src = "images/Logo.png", class = "logo-img", alt = "Rufuf - رفوف")
  ),
  #div("أولاد المرج... بياض اللبن وطراوة العيش", class = "subheading text-center"),
  div(style = "height: 18px;"),
  
  tabsetPanel(id = "main_tabs",
    tabPanel("Cashier",
      div(class = "cashier-panel",
        fluidRow(
          column(6,
            div(class = "section-title",
                icon("barcode", class = "fa-2x"),
                "Scan or Enter Barcode"
            ),
            div(class = "input-group",
                textInput("barcode_input", NULL, placeholder = "Enter or scan barcode", width = "100%"),
                actionButton("scan_btn", "Scan", icon = icon("barcode"), class = "btn-primary")
            ),
            uiOutput("barcode_validation"),
            br(),
            barcodeScannerUI("barcode_scanner")
          ),
          column(6,
            div(class = "section-title",
                icon("shopping-cart", class = "fa-2x"),
                "Shopping Cart"
            ),
            div(class = "cart-summary",
                DT::dataTableOutput("cart_table"),
                uiOutput("cart_mobile_cards"),
                br(),
                div(id = "mobile-remove-btn", style = "display:none",
                  actionButton("remove_selected_mobile", "Remove Selected", icon = icon("trash"), class = "btn-danger")
                ),
                br(), br(),
                div(class = "total-section",
                    h5("Total: ", 
                       span(textOutput("cart_total", inline = TRUE), 
                            style = "font-weight:bold; font-size:1.3rem; color: #27AE60;")
                    )
                ),
                br(),
                div(style = "height: 18px;")
            )
          )
        ),
        fluidRow(
          column(6,
            div(class = "input-group",
                div(class = "section-title",
                    icon("phone", class = "fa-2x"),
                    "Customer Information"
                ),
                textInput("customer_phone", NULL, placeholder = "e.g. 01012345678"),
                textInput("customer_email", NULL, placeholder = "e.g. customer@example.com (optional)"),
                uiOutput("phone_validation")
            )
          ),
          column(6,
            div(style = "text-align: right; margin-top: 2rem;",
                actionButton("checkout_btn", "Complete Checkout", 
                           icon = icon("credit-card"), 
                           class = "btn-success btn-lg"),
                uiOutput("checkout_status")
            )
          )
        )
      )
    ),
    tabPanel("Admin",
      div(class = "admin-panel",
        uiOutput("admin_auth_ui"),
        
        conditionalPanel(
          condition = "output.admin_logged_in == true",
          tabsetPanel(id = "admin_tabs",
            tabPanel("Inventory",
              h4("Inventory Management"),
              uiOutput("inventory_responsive_view"),
              div(style = "display: none;", uiOutput("mobile_action_inputs")),
              br(),
              # Form for adding new items
              fluidRow(
                column(4, textInput("item_name", "Item Name")),
                column(2, numericInput("item_price", "Price", value = 1, min = 0)),
                column(2, numericInput("item_quantity", "Quantity", value = 1, min = 0)),
                column(2, br(), actionButton("add_item_btn", "Add", class = "btn-primary"))
              ),
              # Form for adjusting stock levels
              fluidRow(
                column(4, selectInput("adjust_stock_item", "Select Item to Adjust Stock", choices = NULL)),
                column(2, numericInput("adjust_stock_value", "New Stock", value = 0, min = 0)),
                column(2, br(), actionButton("adjust_stock_btn", "Adjust Stock", class = "btn-warning"))
              ),
              # Status messages for inventory actions
              uiOutput("inventory_action_status"),
              br(),
              # Action buttons for selected items
              actionButton("update_item_btn", "Update Selected", icon = icon("edit")),
              actionButton("delete_item_btn", "Delete Selected", icon = icon("trash"))
            ),
            
            tabPanel("Invoices",
              h4("Invoices"),
              # Search functionality for invoices
              textInput("search_invoice_phone", "Search by Phone", placeholder = "Enter phone number"),
              actionButton("search_invoice_btn", "Search"),
              br(), br(),
              # Interactive data table for invoices
              uiOutput("invoices_responsive_view"),
              br(),
              # Action buttons for selected invoice
              actionButton("view_invoice_btn", "View Selected Invoice", icon = icon("eye")),
              actionButton("print_invoice_btn", "Print Invoice", icon = icon("print")),
              # Modal for displaying invoice details
              uiOutput("invoice_details_modal")
            ),
            
            tabPanel("Reports & Statistics",
              # Add custom CSS for the reports section
              tags$head(
                tags$style(HTML('
                  .report-card {
                    background: white;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                    padding: 20px;
                    margin-bottom: 25px;
                    transition: transform 0.2s;
                  }
                  .report-card:hover {
                    transform: translateY(-5px);
                  }
                  .report-title {
                    color: #2c3e50;
                    font-size: 1.2em;
                    font-weight: 600;
                    margin-bottom: 15px;
                    padding-bottom: 10px;
                    border-bottom: 2px solid #3498db;
                  }
                  .report-plot {
                    background: #f8f9fa;
                    border-radius: 8px;
                    padding: 15px;
                    margin-top: 10px;
                  }
                  .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 20px;
                    margin-bottom: 30px;
                  }
                  .stat-card {
                    background: linear-gradient(135deg, #3498db, #2980b9);
                    color: white;
                    padding: 20px;
                    border-radius: 10px;
                    text-align: center;
                  }
                  .stat-value {
                    font-size: 2em;
                    font-weight: bold;
                    margin: 10px 0;
                  }
                  .stat-label {
                    font-size: 1.1em;
                    opacity: 0.9;
                  }
                '))
              ),
              
              # Main title with icon
              div(class = "text-center mb-4",
                h3(icon("chart-line"), " Business Analytics Dashboard", 
                   style = "color: #2c3e50; font-weight: 600;")
              ),
              
              # WhatsApp Test Section
              div(class = "report-card",
                div(class = "report-title",
                    icon("whatsapp"), " WhatsApp Service Status"
                ),
                div(class = "p-3",
                    actionButton("test_whatsapp_btn", "Test WhatsApp Service", 
                               icon = icon("check-circle"),
                               class = "btn btn-primary"),
                    uiOutput("whatsapp_test_status")
                )
              ),
              
              # Quick Stats Row
              div(class = "stats-grid",
                div(class = "stat-card",
                    div(class = "stat-label", icon("shopping-cart"), "Total Sales"),
                    div(class = "stat-value", textOutput("total_sales"))
                ),
                div(class = "stat-card",
                    div(class = "stat-label", icon("users"), "Total Customers"),
                    div(class = "stat-value", textOutput("total_customers"))
                ),
                div(class = "stat-card",
                    div(class = "stat-label", icon("box"), "Total Products"),
                    div(class = "stat-value", textOutput("total_products"))
                )
              ),
              
              # Sales Analysis Section
              div(class = "report-card",
                div(class = "report-title",
                    icon("chart-bar"), " Sales Performance Analysis"
                ),
                div(class = "row",
                    div(class = "col-md-6",
                        div(class = "report-plot",
                            h5("📈 Top-Selling Items"),
                            plotOutput("top_selling_plot", height = "300px")
                        )
                    ),
                    div(class = "col-md-6",
                        div(class = "report-plot",
                            h5("💰 Revenue Analysis"),
                            plotOutput("top_revenue_plot", height = "300px")
                        )
                    )
                )
              ),
              
              # Inventory Analysis Section
              div(class = "report-card",
                div(class = "report-title",
                    icon("warehouse"), " Inventory Management"
                ),
                div(class = "row",
                    div(class = "col-md-6",
                        div(class = "report-plot",
                            h5("⚠️ Stock Level Alerts"),
                            plotOutput("restock_warning_plot", height = "300px")
                        )
                    ),
                    div(class = "col-md-6",
                        div(class = "report-plot",
                            h5("📉 Low Performance Items"),
                            plotOutput("least_sold_plot", height = "300px")
                        )
                    )
                )
              ),
              
              # Customer Analysis Section
              div(class = "report-card",
                div(class = "report-title",
                    icon("users"), " Customer Insights"
                ),
                div(class = "report-plot",
                    h5("👤 Top Customers by Purchase Count"),
                    DT::dataTableOutput("top_customers_table")
                )
              )
            )
          ),
          br(),
          actionButton("admin_logout_btn", "Logout", class = "btn-danger float-end")
        )
      )
    )
  )
))
