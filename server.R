library(shiny)
library(shinyjs)
library(DT)
library(httr)  # Add httr package for API calls
library(mailR)  # Add mailR for email functionality
library(base64enc)  # Add base64enc for image encoding
library(colourpicker)  # Add colourpicker for color inputs

library(caret)
library(dplyr)
library(randomForest)
library(webshot2)
library(ggplot2)

source("scan_barcode_module.R")
source("initial_data.R")

source("Database/connection.R")
source("Database/setup.R")
source("Database/user.R")
source("Database/item.R")
source("Database/invoice.R")
source("Database/item_invoice.R")
source("Database/utility.R")

# Initialize database if it doesn't exist
conn <- get_connection()
if (!"Invoice" %in% get_tables()$name) {
  create_database()
  # Load initial data if needed
  source("initial_data.R")
}
dbDisconnect(conn)

# --- WhatsApp Configuration ---
# Your WhatsApp Business API token (get it from https://www.callmebot.com/blog/free-api-whatsapp-messages/)
WHATSAPP_API_KEY <- "5701260"  # Your CallMeBot API key
WHATSAPP_PHONE <- "201023232234"    # Your WhatsApp number with country code

# Function to test WhatsApp connection
test_whatsapp_connection <- function() {
  tryCatch({
    # Send a test message
    test_message <- "Test message from Rufuf - رفوف"
    encoded_message <- URLencode(test_message, reserved = TRUE)
    
    # Construct the URL
    url <- paste0("https://api.callmebot.com/whatsapp.php?phone=", WHATSAPP_PHONE, "&text=", encoded_message, "&apikey=", WHATSAPP_API_KEY)
    
    # Make the request
    response <- httr::GET(url)
    
    # Check if the message was sent successfully (including 203 status code)
    if (httr::status_code(response) %in% c(200, 201, 203)) {
      return(list(success = TRUE, message = "WhatsApp connection successful!"))
    } else {
      return(list(success = FALSE, message = paste("Failed to send WhatsApp message. Status code:", httr::status_code(response))))
    }
  }, error = function(e) {
    return(list(success = FALSE, message = paste("Error:", e$message)))
  })
}

# Function to send WhatsApp message
send_whatsapp <- function(to_number, message) {
  tryCatch({
    # Format phone number
    if (!grepl("^\\+?[0-9]{10,15}$", to_number)) {
      return(list(success = FALSE, message = "Invalid phone number format"))
    }
    
    # Add country code if missing
    if (!grepl("^\\+", to_number)) {
      to_number <- paste0("20", gsub("^0", "", to_number))
    }
    
    # Encode the message properly
    encoded_message <- URLencode(message, reserved = TRUE)
    
    # Construct the URL
    url <- paste0("https://api.callmebot.com/whatsapp.php?phone=", to_number, "&text=", encoded_message, "&apikey=", WHATSAPP_API_KEY)
    
    # Send message
    response <- httr::GET(url)
    
    # Check if the message was sent successfully (including 203 status code)
    if (httr::status_code(response) %in% c(200, 201, 203)) {
      return(list(success = TRUE, message = "Message sent successfully!"))
    } else {
      return(list(success = FALSE, message = paste("Failed to send message. Status code:", httr::status_code(response))))
    }
  }, error = function(e) {
    return(list(success = FALSE, message = paste("Error sending message:", e$message)))
  })
}

# Function to send email receipt
send_email_receipt <- function(to_email, invoice_id, phone, current_date, items, subtotal, tax, final_total) {
  tryCatch({
    # Create items table rows
    items_rows <- if (nrow(items) > 0) {
      paste(apply(items, 1, function(row) {
        sprintf(
          "<tr>\n            <td style='padding:8px;border:1px solid #ddd;'>%s</td>\n            <td style='padding:8px;border:1px solid #ddd;'>%s</td>\n            <td style='padding:8px;border:1px solid #ddd;'>%s</td>\n            <td style='padding:8px;border:1px solid #ddd;'>%s</td>\n          </tr>",
          row["name"], row["quantity"], row["price"], row["total"]
        )
      }), collapse = "")
    } else {
      "<tr><td colspan='4' style='padding:8px;border:1px solid #ddd;'>لا توجد منتجات</td></tr>"
    }

    # Logo URL
    logo_path <- normalizePath("www/images/Logo.png", winslash = "/")
    logo_base64 <- base64enc::base64encode(logo_path)
    logo_url <- sprintf("data:image/png;base64,%s", logo_base64)

    # HTML body
    email_body <- sprintf('
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Tahoma, Arial, sans-serif; direction: rtl; background: #f9f9f9; color: #222; }
          .invoice-box { background: #fff; max-width: 600px; margin: auto; padding: 30px; border-radius: 10px; box-shadow: 0 2px 8px #eee; }
          .logo { text-align: center; margin-bottom: 20px; }
          .logo img { max-width: 180px; }
          table { width: 100%%; border-collapse: collapse; margin: 20px 0; }
          th { background: #2E86C1; color: #fff; padding: 10px; border: 1px solid #ddd; }
          td { padding: 8px; border: 1px solid #ddd; }
          .summary { margin-top: 20px; }
          .summary p { margin: 4px 0; font-size: 1.1em; }
        </style>
      </head>
      <body>
        <div class="invoice-box">
          <div class="logo">
            <img src="%s" alt="Logo">
          </div>
          <h2 style="text-align:center; color:#2E86C1;">فاتورة رقم: %s</h2>
          <p><b>تليفون العميل:</b> %s</p>
          <p><b>التاريخ:</b> %s</p>
          <table>
            <tr>
              <th>المنتج</th>
              <th>الكمية</th>
              <th>السعر</th>
              <th>الإجمالي</th>
            </tr>
            %s
          </table>
          <div class="summary">
            <p><b>الإجمالي الفرعي:</b> %.2f جنيه</p>
            <p><b>الضريبة (15%%):</b> %.2f جنيه</p>
            <p style="font-size:1.2em;"><b>الإجمالي النهائي:</b> %.2f جنيه</p>
          </div>
        </div>
      </body>
      </html>
    ', logo_url, invoice_id, phone, current_date, items_rows, subtotal, tax, final_total)

    send.mail(
      from = "shortstory906@gmail.com",
      to = to_email,
      subject = sprintf("فاتورة Rufuf - رفوف - %s", invoice_id),
      body = email_body,
      smtp = list(
        host.name = "smtp.gmail.com",
        port = 587,
        user.name = "shortstory906@gmail.com",
        passwd = "spnv zfqm qwti oyom",
        ssl = TRUE
      ),
      authenticate = TRUE,
      send = TRUE,
      html = TRUE,
      encoding = "utf-8"
    )

    return(list(success = TRUE, message = "Email sent successfully!"))
  }, error = function(e) {
    return(list(success = FALSE, message = paste("Error sending email:", e$message)))
  })
}

shinyServer(function(input, output, session) {
  # --- GLOBAL REACTIVE VALUES ---
  rv <- reactiveValues(
    cart = data.frame(barcode=character(), name=character(), price=numeric(), quantity=numeric(), stock=numeric(), total=numeric(), stringsAsFactors=FALSE),
    admin_logged_in = FALSE,
    admin_user = NULL,
    selected_invoice = NULL
  )

  # --- CONFIGURATION ---

  phone_pattern <- "^01[0-9]{9}$"  # Egyptian mobile numbers


  # --- Add audio elements for sounds ---
  output$sound_elements <- renderUI({
    tagList(
      tags$audio(id = "checkout_success_sound", src = "www/beep_success.mp3", preload = "auto")
    )
  })
  
  # Insert the sound elements into the UI
  insertUI(selector = "body", where = "afterBegin", ui = uiOutput("sound_elements"))
  
  # --- Function to play sound ---
  play_sound <- function(sound_id) {
    shinyjs::runjs(sprintf('
      var sound = document.getElementById("%s");
      if (sound) {
        sound.currentTime = 0;
        var playPromise = sound.play();
        if (playPromise !== undefined) {
          playPromise.catch(function(error) {
            console.error("Error playing sound:", error);
          });
        }
      }
    ', sound_id))
  }

  # --- UTILS ---
  clear_cart <- function() {
    rv$cart <- rv$cart[0,]
  }
  get_stock <- function(barcode) {
    item <- get_item_by_barcode(barcode)
    if (nrow(item) == 0) return(NA) 
    item$quantity
  }

  # Validate phone number against the configured pattern
  validate_phone <- function(phone) {
    return(grepl(phone_pattern, phone))
  }

  # --- CASHIER TAB ---
  
  # Barcode scan logic
  barcodeScannerServer("barcode_scanner", function(barcode) {
    if (!is.null(barcode) && barcode != "") {
      updateTextInput(session, "barcode_input", value = barcode)
      shinyjs::runjs('new Audio("https://cdn.pixabay.com/audio/2022/03/15/audio_115b9e7b7e.mp3").play();')
    }
  })
  observeEvent(input$scan_btn, {
    session$sendCustomMessage("startScanning", list())
  })
  observeEvent(input$`barcode_scanner-stop_scan_btn`, {
    session$sendCustomMessage("stopScanning", list())
  })

  # Add item to cart (manual or scan)
  observeEvent(input$barcode_input, {
   
    on.exit({ updateTextInput(session, "barcode_input", value = "") }, add = TRUE)

    req(input$barcode_input)
    barcode <- trimws(input$barcode_input)
    print(paste("[DEBUG] Barcode input observer triggered with:", barcode))
    item <- get_item_by_barcode(barcode)
    print(paste("[DEBUG] get_item_by_barcode nrow:", nrow(item)))
    if (nrow(item) == 0) {
      output$barcode_validation <- renderUI({ div("Invalid barcode!", style="color:red;") })
      return()
    } else {
      output$barcode_validation <- renderUI({ NULL })
    }
    idx <- which(rv$cart$barcode == barcode)
    stock <- item$quantity
    print(paste("[DEBUG] Cart idx:", paste(idx, collapse=","), "stock:", stock))
    if (length(idx) == 0) {
      rv$cart <- rbind(rv$cart, data.frame(
        barcode = barcode,
        name = item$item_name,
        price = item$price,
        quantity = 1,
        stock = stock,
        total = item$price,
        stringsAsFactors = FALSE
      ))
      print("[DEBUG] Added new item to cart")
      
      shinyjs::runjs('new Audio("www/beep_success.mp3").play();')
     

    } else {
      
      if (length(rv$cart$quantity) >= idx && rv$cart$quantity[idx] < stock) {
        rv$cart$quantity[idx] <- rv$cart$quantity[idx] + 1
        rv$cart$total[idx] <- rv$cart$quantity[idx] * rv$cart$price[idx]
        print("[DEBUG] Increased quantity in cart")
        
        shinyjs::runjs('new Audio("www/beep_success.mp3").play();')
      

      } else {
        showNotification("Cannot exceed stock!", type = "error")
        print("[DEBUG] Cannot exceed stock!")
      }
    }
   
    updateTextInput(session, "barcode_input", value = "")
    print("[DEBUG] Cart after barcode input:")
    print(rv$cart)
  })

  # Cart table (with quantity edit and remove)
  output$cart_table <- DT::renderDataTable({
    dat <- rv$cart
    if (nrow(dat) == 0) return(dat)
    dat$Edit = paste0('<input type="number" min="1" max="', dat$stock, '" value="', dat$quantity, '" class="cart-qty" data-barcode="', dat$barcode, '">')
    dat$Remove = paste0('<input type="checkbox" class="cart-remove" data-barcode="', dat$barcode, '">')
    dat[, c("barcode", "name", "price", "quantity", "stock", "total", "Edit", "Remove")]
  }, escape = FALSE, selection = "none", server = FALSE, options = list(dom = 't', paging = FALSE, ordering=FALSE, preDrawCallback = JS('function() { Shiny.unbindAll(this.api().table().node()); }'), drawCallback = JS('function() { Shiny.bindAll(this.api().table().node()); }')))

  # Mobile card view for cart
  output$cart_mobile_cards <- renderUI({
    dat <- rv$cart
    if (nrow(dat) == 0) {
      return(div(class = "cart-mobile-card", "No items in cart."))
    }
    lapply(seq_len(nrow(dat)), function(i) {
      div(class = "cart-mobile-card",
        tags$b(dat$name[i]), br(),
        span("Barcode: ", tags$span(dat$barcode[i], style="font-weight:500;")), br(),
        span("Price: ", tags$span(dat$price[i], style="font-weight:500;")), br(),
        span("Quantity: ", tags$span(dat$quantity[i], style="font-weight:500;")), br(),
        span("Stock: ", tags$span(dat$stock[i], style="font-weight:500;")), br(),
        span("Total: ", tags$span(dat$total[i], style="font-weight:500; color:#27AE60;")), br(),
        tags$input(type = "checkbox", class = "cart-mobile-remove", `data-barcode` = dat$barcode[i], style = "margin-top:8px;")
      )
    })
  })

  # JS to collect checked barcodes and send to Shiny
  shinyjs::runjs('
    $(document).off("click", "#remove_selected_mobile").on("click", "#remove_selected_mobile", function() {
      var checked = [];
      $(".cart-mobile-remove:checked").each(function() {
        checked.push($(this).data("barcode"));
      });
      Shiny.setInputValue("cart_mobile_remove_items", checked, {priority: "event"});
    });
  ')

  observeEvent(input$cart_mobile_remove_items, {
    dat <- rv$cart
    to_remove <- input$cart_mobile_remove_items
    if (!is.null(to_remove) && length(to_remove) > 0) {
      rv$cart <- dat[!dat$barcode %in% to_remove, ]
    }
  })

  # JS for quantity edit
  observe({
    session$sendCustomMessage("bindCartQty", list())
  })
  shinyjs::runjs('
    Shiny.addCustomMessageHandler("bindCartQty", function(message) {
      $(document).off("change", ".cart-qty").on("change", ".cart-qty", function() {
        var barcode = $(this).data("barcode");
        var qty = parseInt($(this).val());
        Shiny.setInputValue("cart_qty_edit", {barcode: barcode, qty: qty}, {priority: "event"});
      });
      $(document).off("change", ".cart-remove").on("change", ".cart-remove", function() {
        var barcode = $(this).data("barcode");
        Shiny.setInputValue("cart_remove_item", barcode, {priority: "event"});
      });
    });
  ')

  observeEvent(input$cart_qty_edit, {
    idx <- which(rv$cart$barcode == input$cart_qty_edit$barcode)
    if (length(idx) == 1) {
      # Always get the latest stock from the database
      stock <- get_stock(rv$cart$barcode[idx])
      qty <- as.numeric(input$cart_qty_edit$qty)
      if (qty > 0 && qty <= stock) {
        rv$cart$quantity[idx] <- qty
        rv$cart$total[idx] <- qty * rv$cart$price[idx]
      } else {
        showNotification(paste0("Invalid quantity! Only ", stock, " left in stock."), type = "error")
        # Optionally, reset to max allowed
        rv$cart$quantity[idx] <- stock
        rv$cart$total[idx] <- stock * rv$cart$price[idx]
      }
    }
  })

  observeEvent(input$cart_remove_item, {
    dat <- rv$cart
    idx <- which(dat$barcode == input$cart_remove_item)
    if (length(idx) == 1) {
      rv$cart <- dat[-idx,]
    }
  })

  output$cart_total <- renderText({
    sum(rv$cart$total)
  })

  # --- PHONE VALIDATION ---
  output$phone_validation <- renderUI({
    req(input$customer_phone)
    phone <- trimws(input$customer_phone)
    if (!validate_phone(phone)) {
      div("Invalid phone number!", style="color:red;")
    } else {
      NULL
    }
  })

  # --- CHECKOUT ---
  observeEvent(input$checkout_btn, {
    if (is.null(rv$cart) || !is.data.frame(rv$cart) || nrow(rv$cart) == 0 || is.null(rv$cart$barcode)) {
      output$checkout_status <- renderUI({ div("Cart is empty!", style="color:red;") })
      return()
    }
    phone <- trimws(input$customer_phone)
    if (!validate_phone(phone)) {
      output$checkout_status <- renderUI({ div("Please enter a valid phone number!", style="color:red;") })
      return()
    }
    if (nrow(rv$cart) == 0) {
      output$checkout_status <- renderUI({ div("Cart is empty!", style="color:red;") })
      return()
    }
    
    # Validate stock for all items and collect errors
    overstock_items <- c()
    for (i in seq_len(nrow(rv$cart))) {
      if (is.null(rv$cart$barcode[i]) || is.na(rv$cart$barcode[i]) || rv$cart$barcode[i] == "") next
      stock <- get_stock(rv$cart$barcode[i])
      if (is.na(stock)) {
        output$checkout_status <- renderUI({ div(paste0("Item not found or deleted: ", rv$cart$name[i]), style="color:red;") })
        return()
      }
      if (stock == 0) {
        output$checkout_status <- renderUI({ div(paste0("Out of stock: ", rv$cart$name[i]), style="color:red;") })
        return()
      }
      if (rv$cart$quantity[i] > stock) {
        overstock_items <- c(overstock_items, paste0(rv$cart$name[i], " (max: ", stock, ")"))
        # Optionally, reset to max allowed:
        rv$cart$quantity[i] <- stock
        rv$cart$total[i] <- stock * rv$cart$price[i]
      }
    }

    if (length(overstock_items) > 0) {
      output$checkout_status <- renderUI({
        div(
          "Cannot checkout. The following items exceed available stock:",
          tags$ul(lapply(overstock_items, tags$li)),
          style = "color:red;"
        )
      })
      return()
    }
    
    # Add user if not exists
    user_id <- get_user_by_phone(phone)
    if (is.null(user_id)) add_user(phone)
    
    # Create invoice
    current_date <- as.character(Sys.Date())
    invoice_id <- create_invoice(phone, date = current_date)
    
    subtotal <- sum(rv$cart$total)
    tax <- subtotal * 0.15
    final_total <- subtotal + tax
    
    for (i in seq_len(nrow(rv$cart))) {
      if (is.null(rv$cart$barcode[i]) || is.na(rv$cart$barcode[i]) || rv$cart$barcode[i] == "") next
      item <- get_item_by_barcode(rv$cart$barcode[i])
      if (nrow(item) == 0) next
      add_item_to_invoice(invoice_id, item$item_id, rv$cart$quantity[i])
      update_item_quantity(item$item_id, item$quantity - rv$cart$quantity[i])
    }
    
    Finalize_invoice(invoice_id)
    
    # Store invoice data for later PDF generation
    rv$selected_invoice <- list(
      id = invoice_id,
      phone = phone,
      date = current_date,
      subtotal = subtotal,
      tax = tax,
      final_total = final_total
    )
    
    # Send WhatsApp message to customer
    items <- rv$cart
    items_lines <- if (nrow(items) > 0) {
      paste(apply(items, 1, function(row) {
        sprintf("- %s × %s بسعر %s = %s جنيه", row["name"], row["quantity"], row["price"], row["total"])
      }), collapse = "\n")
    } else {
      "لا توجد منتجات"
    }
    sms_message <- sprintf(
      "شكراً لتعاملكم مع Rufuf - رفوف\nفاتورة رقم: %s\nالتاريخ: %s\n\nالمنتجات:\n%s\n\nالإجمالي الفرعي: %.2f جنيه\nالضريبة (15%%): %.2f جنيه\nالإجمالي النهائي: %.2f جنيه",
      invoice_id,
      current_date,
      items_lines,
      subtotal,
      tax,
      final_total
    )
    
    sms_sent <- send_whatsapp(phone, sms_message)
    
    # After successful checkout and WhatsApp message
    if (!is.null(input$customer_email) && input$customer_email != "") {
      email_result <- send_email_receipt(
        input$customer_email,
        invoice_id,
        phone,
        current_date,
        rv$cart,
        subtotal,
        tax,
        final_total
      )
      
      if (email_result$success) {
        output$checkout_status <- renderUI({ 
          div(
            div("Checkout successful!", style="color:green;"),
            if(sms_sent$success) {
              div("WhatsApp message sent to customer!", style="color:green;")
            } else {
              div(sms_sent$message, style="color:orange;")
            },
            div("Email receipt sent!", style="color:green;"),
            actionButton("generate_invoice_pdf", "Download Invoice", class = "btn btn-primary", style = "margin-top: 10px;")
          )
        })
      } else {
        output$checkout_status <- renderUI({ 
          div(
            div("Checkout successful!", style="color:green;"),
            if(sms_sent$success) {
              div("WhatsApp message sent to customer!", style="color:green;")
            } else {
              div(sms_sent$message, style="color:orange;")
            },
            div(paste("Email sending failed:", email_result$message), style="color:orange;"),
            actionButton("generate_invoice_pdf", "Download Invoice", class = "btn btn-primary", style = "margin-top: 10px;")
          )
        })
      }
    } else {
      output$checkout_status <- renderUI({ 
        div(
          div("Checkout successful!", style="color:green;"),
          if(sms_sent$success) {
            div("WhatsApp message sent to customer!", style="color:green;")
          } else {
            div(sms_sent$message, style="color:orange;")
          },
          actionButton("generate_invoice_pdf", "Download Invoice", class = "btn btn-primary", style = "margin-top: 10px;")
        )
      })
    }
    clear_cart()
  })
  
  observeEvent(input$generate_invoice_pdf, {
    req(rv$selected_invoice)
    invoice_id <- rv$selected_invoice$id
    phone <- rv$selected_invoice$phone
    current_date <- rv$selected_invoice$date
    subtotal <- rv$selected_invoice$subtotal
    tax <- rv$selected_invoice$tax
    final_total <- rv$selected_invoice$final_total
    
    # Generate invoice PDF
    items <- get_invoice_items(invoice_id)
    html_file <- tempfile(fileext = ".html")

    logo_path <- normalizePath("www/images/Logo.png", winslash = "/")
    logo_base64 <- base64enc::base64encode(logo_path)
    logo_url <- sprintf("data:image/png;base64,%s", logo_base64)
    
    html_content <- paste0(
      "<html><head><meta charset='UTF-8'><title>فاتورة رقم: ", invoice_id, "</title>",
      "<style>body { font-family: Arial, sans-serif; direction: rtl; } table { width: 100%; border-collapse: collapse; margin: 20px 0; } th, td { border: 1px solid black; padding: 8px; text-align: center; }</style>",
      "</head><body>",
      "<h2 style='text-align: center;'>فاتورة رقم: ", invoice_id, "</h2>",
      "<p><b>تليفون العميل:</b> ", phone, "</p>",
      "<p><b>التاريخ:</b> ", current_date, "</p>",
      "<table><tr><th>المنتج</th><th>السعر</th><th>الكمية</th><th>الإجمالي</th></tr>",
      if (nrow(items) > 0 && all(c('item_name','price','quantity') %in% colnames(items))) {
        paste(apply(items[,c('item_name','price','quantity')], 1, function(row) {
          total <- as.numeric(row[2]) * as.numeric(row[3])
          paste0("<tr><td>", row[1], "</td><td>", row[2], "</td><td>", row[3], "</td><td>", total, "</td></tr>")
        }), collapse="")
      } else {
        "<tr><td colspan='4'>لا توجد منتجات</td></tr>"
      },
      "</table>",
      "<div style='text-align: left; margin-top: 20px;'>",
      "<p><b>الإجمالي الفرعي:</b> ", subtotal, "</p>",
      "<p><b>الضريبة (15%):</b> ", tax, "</p>",
      "<p style='font-size: 1.2em;'><b>الإجمالي النهائي:</b> ", final_total, "</p>",
      "</div>",
      "<div style='text-align:center; margin-top:30px;'><img src='", logo_url, "' alt='Logo' style='max-width:180px;'></div>",
      "</body></html>"
    )
    
    writeLines(html_content, html_file)
    pdf_file <- paste0("www/invoice_", invoice_id, ".pdf")
    webshot2::webshot(html_file, file = pdf_file, vwidth = 900, vheight = 1200)
    
    # Open the invoice in a new tab automatically
    shinyjs::runjs(sprintf('window.open("invoice_%s.pdf", "_blank");', invoice_id))
    
    # Update the status message
    output$checkout_status <- renderUI({ 
      div(
        div("Invoice ready!", style="color:green;"),
        tags$a(href=paste0("invoice_", invoice_id, ".pdf"), "Download Invoice", 
               target="_blank", class="btn btn-primary", style="margin-top: 10px;")
      )
    })
  })
  

  # --- ADMIN TAB ---
  # Reactive output to track admin login status - used by UI to show/hide admin content
  output$admin_logged_in <- reactive({ rv$admin_logged_in })
  outputOptions(output, "admin_logged_in", suspendWhenHidden = FALSE)
  #means the output will continue to update even when the admin panel is not visible

  # --- ADMIN AUTH ---
  # Render the admin authentication UI - shows login form when not logged in
  output$admin_auth_ui <- renderUI({
    if (!rv$admin_logged_in) {
      tagList(
        passwordInput("admin_password", "Admin Password", placeholder = "Enter password"),
        actionButton("admin_login_btn", "Login", class = "btn-primary")
      )
    } else {
      NULL
    }
  })

  # Handle admin login button click
  observeEvent(input$admin_login_btn, {
    # Simple password check - in production, this should be more secure
    if (input$admin_password == "admin123") {
      rv$admin_logged_in <- TRUE
    } else {
      showNotification("Incorrect password!", type = "error")
    }
  })

  # Handle admin logout button click
  observeEvent(input$admin_logout_btn, {
    rv$admin_logged_in <- FALSE
    rv$admin_user <- NULL
  })

  # Auto logout when switching to cashier tab for security
  observeEvent(input$main_tabs, {
    if (input$main_tabs == "Cashier" && rv$admin_logged_in) {
      rv$admin_logged_in <- FALSE
      rv$admin_user <- NULL
    }
  })

  # --- INVENTORY TAB ---
  # Function to refresh inventory data from database
  refresh_inventory <- function() {
    items <- get_all_items()
    items
  }

  # Update item selection dropdown when inventory changes
  observe({
    req(rv$admin_logged_in)
    items <- refresh_inventory()
    updateSelectInput(session, "adjust_stock_item", choices = setNames(items$item_id, items$item_name))
  })

  # Handle stock adjustment button click
  observeEvent(input$adjust_stock_btn, {
    req(rv$admin_logged_in)
    # Validate input
    if (is.null(input$adjust_stock_item) || input$adjust_stock_value < 0) {
      output$inventory_action_status <- renderUI({ div("Select item and valid stock value!", style="color:red;") })
      return()
    }
    # Update stock in database
    update_item(as.numeric(input$adjust_stock_item), quantity = as.numeric(input$adjust_stock_value))
    output$inventory_action_status <- renderUI({ div("Stock adjusted!", style="color:green;") })
    # Refresh tables and dropdowns
    output$inventory_table <- DT::renderDataTable({ refresh_inventory() }, selection = "single")
    updateSelectInput(session, "adjust_stock_item", choices = setNames(refresh_inventory()$item_id, refresh_inventory()$item_name))
  })

  # Render inventory table with data formatting
  output$inventory_table <- DT::renderDataTable({
    req(rv$admin_logged_in)
    items <- refresh_inventory()
    # Format expiry dates if they exist
    if ("expiry_date" %in% names(items)) {
      items$expiry_date <- suppressWarnings(
        ifelse(is.na(items$expiry_date) | items$expiry_date == "" | grepl("[^0-9-]", items$expiry_date),
               items$expiry_date,
               as.character(as.Date(items$expiry_date))
        )
      )
    }
    datatable(items, selection = "single") %>%
      DT::formatStyle(
        'restock_needed',
        target = 'row',
        backgroundColor = DT::styleEqual(1, '#ffeaea'),
        color = DT::styleEqual(1, '#c0392b')
      )
  }, selection = "single")

  # Handle adding new item
  observeEvent(input$add_item_btn, {
    req(rv$admin_logged_in)
    # Validate input
    if (input$item_name == "") {
      output$inventory_action_status <- renderUI({ div("Name is required!", style="color:red;") })
      return()
    }
    # Generate next barcode number
    items <- refresh_inventory()
    if (nrow(items) == 0) {
      next_barcode <- "1000"
    } else {
      barcodes <- suppressWarnings(as.numeric(items$barcode))
      barcodes <- barcodes[!is.na(barcodes)]
      # Generate next barcode by:
      # 1. Taking the maximum of existing barcodes and 999
      # 2. Adding 1 to that number
      # 3. Converting back to character
      next_barcode <- as.character(max(c(barcodes, 999)) + 1)
    }
    # Add item to database
    add_item(input$item_name, input$item_price, input$item_quantity, barcode = next_barcode)
    output$inventory_action_status <- renderUI({ div(paste0("Item added! Barcode: ", next_barcode), style="color:green;") })
    # Refresh tables and dropdowns
    output$inventory_table <- DT::renderDataTable({ refresh_inventory() }, selection = "single")
    updateSelectInput(session, "adjust_stock_item", choices = setNames(items$item_id, items$item_name))
  })

  # Handle updating existing item
  observeEvent(input$update_item_btn, {
    req(rv$admin_logged_in)
    sel <- input$inventory_table_rows_selected
    if (is.null(sel)) return()
    items <- refresh_inventory()
    item <- items[sel,]
    # Update item in database
    update_item(item$item_id, input$item_name, input$item_price, input$item_quantity)
    output$inventory_action_status <- renderUI({ div("Item updated!", style="color:green;") })
    # Refresh tables and dropdowns
    output$inventory_table <- DT::renderDataTable({ refresh_inventory() }, selection = "single")
    updateSelectInput(session, "adjust_stock_item", choices = setNames(items$item_id, items$item_name))
  })

  # Handle deleting item
  observeEvent(input$delete_item_btn, {
    req(rv$admin_logged_in)
    sel <- input$inventory_table_rows_selected
    if (is.null(sel)) return()
    items <- refresh_inventory()
    item <- items[sel,]
    # Delete item from database
    delete_item(item$item_id)
    output$inventory_action_status <- renderUI({ div("Item deleted!", style="color:green;") })
    # Refresh tables and dropdowns
    output$inventory_table <- DT::renderDataTable({ refresh_inventory() }, selection = "single")
    updateSelectInput(session, "adjust_stock_item", choices = setNames(items$item_id, items$item_name))
  })

  # Mobile card view for inventory
  output$inventory_mobile_cards <- renderUI({
    req(rv$admin_logged_in)
    items <- refresh_inventory()
    if (nrow(items) == 0) {
      return(div(class = "inventory-mobile-card", "No items in inventory."))
    }
    tagList(
      div(class = "mb-3 text-center", 
          strong("Showing ", nrow(items), " inventory items"),
          style = "color: #666; font-size: 0.9rem;"
      ),
      lapply(seq_len(nrow(items)), function(i) {
        div(class = "inventory-mobile-card",
          div(class = "item-header",
            span(class = "item-name", tags$b(items$item_name[i])),
            span(class = "item-id", paste0("ID: ", items$item_id[i]))
          ),
          div(class = "item-content",
            div(class = "item-detail", 
                icon("barcode"), " ", tags$span(items$barcode[i])
            ),
            div(class = "item-detail", 
                icon("tag"), " Price: ", 
                tags$span(items$price[i], class = "price-value")
            ),
            div(class = "item-detail", 
                icon("boxes"), " Quantity: ", 
                tags$span(items$quantity[i], class = "quantity-value")
            )
          )
        )
      })
    )
  })

  # Responsive inventory view: show table or cards based on screen width
  output$inventory_responsive_view <- renderUI({
    width <- input$screen_width
    if (is.null(width) || width > 768) {
      DT::dataTableOutput("inventory_table")
    } else {
      div(class = "inventory-mobile-cards-container", uiOutput("inventory_mobile_cards"))
    }
  })

  # --- INVOICES TAB ---
  # Function to refresh invoice data, optionally filtered by phone number
  refresh_invoices <- function(phone = NULL) {
    if (!is.null(phone) && phone != "") {
      inv <- get_invoices_by_phone(phone)
    } else {
      inv <- get_all_invoices()
    }
    inv
  }

  # Add a reactive value to store the current invoice search phone
  invoice_search_phone <- reactiveVal("")

  # Handle invoice search button click
  observeEvent(input$search_invoice_btn, {
    invoice_search_phone(input$search_invoice_phone)
  })

  # Update the responsive view and table when the search value or screen width changes
  observe({
    phone <- invoice_search_phone()
    width <- input$screen_width
    invs <- refresh_invoices(phone)
    output$invoices_table <- DT::renderDataTable({ refresh_invoices(phone) }, selection = "single")
    output$invoices_responsive_view <- renderUI({
      if (is.null(width) || width > 768) {
        DT::dataTableOutput("invoices_table")
      } else {
        if (nrow(invs) == 0) {
          return(div(class = "invoice-mobile-card", "No invoices found."))
        }
        tagList(
          lapply(seq_len(nrow(invs)), function(i) {
            total <- if (all(c('price','quantity') %in% colnames(get_invoice_items(invs$invoice_id[i])))) {
              sum(get_invoice_items(invs$invoice_id[i])$price * get_invoice_items(invs$invoice_id[i])$quantity)
            } else {
              NA
            }
            div(class = "invoice-mobile-card",
              div(class = "invoice-id", paste("Invoice #", invs$invoice_id[i])),
              div(class = "invoice-detail", icon("phone"), invs$phone_number[i]),
              div(class = "invoice-detail", icon("calendar"), invs$date[i]),
              div(class = "invoice-detail invoice-total", icon("money-bill"), "Total: ", total),
              div(class = "invoice-actions",
                actionButton(paste0("view_invoice_btn_mobile_", invs$invoice_id[i]), "View", icon = icon("eye"), class = "btn btn-primary"),
                actionButton(paste0("print_invoice_btn_mobile_", invs$invoice_id[i]), "Print", icon = icon("print"), class = "btn btn-success")
              )
            )
          })
        )
      }
    })
  })

  # Handle viewing invoice details
  observeEvent(input$view_invoice_btn, {
    sel <- input$invoices_table_rows_selected
    if (is.null(sel)) return()
    invs <- refresh_invoices(input$search_invoice_phone)
    inv <- invs[sel,]
    items <- get_invoice_items(inv$invoice_id)
    # Show modal with invoice details
    output$invoice_details_modal <- renderUI({
      showModal(modalDialog(
        title = paste("Invoice #", inv$invoice_id),
        h5("Customer Phone: ", inv$phone_number),
        h5("Date: ", inv$date),
        div(class = "table-responsive",
          DT::renderDataTable(items, 
            options = list(
              dom = 't', 
              paging = FALSE,
              scrollX = TRUE,
              columnDefs = list(
                list(className = 'dt-center', targets = '_all')
              )
            ),
            selection = "none"
          )
        ),
        h4("Total: ", sum(items$price * items$quantity)),
        size = "l",
        easyClose = TRUE
      ))
      NULL
    })
  })

  # Handle printing invoice
  observeEvent(input$print_invoice_btn, {
    sel <- input$invoices_table_rows_selected
    if (is.null(sel)) return()
    invs <- refresh_invoices(input$search_invoice_phone)
    inv <- invs[sel,]
    items <- get_invoice_items(inv$invoice_id)
    
    # Calculate invoice totals
    subtotal <- sum(items$price * items$quantity)
    tax <- subtotal * 0.15
    final_total <- subtotal + tax
    
    # Generate invoice PDF
    html_file <- tempfile(fileext = ".html")
    
    logo_path <- normalizePath("www/images/Logo.png", winslash = "/")
    logo_base64 <- base64enc::base64encode(logo_path)
    logo_url <- sprintf("data:image/png;base64,%s", logo_base64)

    # Create HTML content for PDF
    html_content <- paste0(
      "<html><head><meta charset='UTF-8'><title>فاتورة رقم: ", inv$invoice_id, "</title>",
      "<style>body { font-family: Arial, sans-serif; direction: rtl; } table { width: 100%; border-collapse: collapse; margin: 20px 0; } th, td { border: 1px solid black; padding: 8px; text-align: center; }</style>",
      "</head><body>",
      "<h2 style='text-align: center;'>فاتورة رقم: ", inv$invoice_id, "</h2>",
      "<p><b>تليفون العميل:</b> ", inv$phone_number, "</p>",
      "<p><b>التاريخ:</b> ", inv$date, "</p>",
      "<table><tr><th>المنتج</th><th>السعر</th><th>الكمية</th><th>الإجمالي</th></tr>",
      if (nrow(items) > 0 && all(c('item_name','price','quantity') %in% colnames(items))) {
        paste(apply(items[,c('item_name','price','quantity')], 1, function(row) {
          total <- as.numeric(row[2]) * as.numeric(row[3])
          paste0("<tr><td>", row[1], "</td><td>", row[2], "</td><td>", row[3], "</td><td>", total, "</td></tr>")
        }), collapse="")
      } else {
        "<tr><td colspan='4'>لا توجد منتجات</td></tr>"
      },
      "</table>",
      "<div style='text-align: left; margin-top: 20px;'>",
      "<p><b>الإجمالي الفرعي:</b> ", subtotal, "</p>",
      "<p><b>الضريبة (15%):</b> ", tax, "</p>",
      "<p style='font-size: 1.2em;'><b>الإجمالي النهائي:</b> ", final_total, "</p>",
      "</div>",
      "<div style='text-align:center; margin-top:30px;'><img src='", logo_url, "' alt='Logo' style='max-width:180px;'></div>",
      "</body></html>"
    )
    
    # Generate PDF and show download link
    writeLines(html_content, html_file)
    pdf_file <- paste0("www/invoice_", inv$invoice_id, ".pdf")
    webshot2::webshot(html_file, file = pdf_file, vwidth = 900, vheight = 1200)
    
    showModal(modalDialog(
      title = paste("Print Invoice #", inv$invoice_id),
      div(
        p("Invoice has been generated successfully!"),
        tags$a(href=paste0("invoice_", inv$invoice_id, ".pdf"), 
               "Download Invoice", 
               target="_blank", 
               class="btn btn-primary",
               style="margin-top: 10px;")
      ),
      size = "l",
      easyClose = TRUE
    ))
  })

  # --- REPORTS TAB ---
  # Get inventory data
  report_data <- get_inventory_report()
  
  # Calculate summary statistics
  output$total_sales <- renderText({
    sum(report_data$quantity_sold * report_data$price)
  })
  
  output$total_customers <- renderText({
    nrow(get_all_invoices() %>% distinct(phone_number))
  })
  
  output$total_products <- renderText({
    nrow(report_data)
  })
  
  # Generate top-selling items report
  top_selling_items <- report_data %>%
    arrange(desc(quantity_sold)) %>%
    head(10)
  
  # Plot top-selling items with improved styling
  output$top_selling_plot <- renderPlot({
    par(mar = c(8, 4, 4, 2))  # Adjust margins for better label display
    barplot(top_selling_items$quantity_sold,
            names.arg = top_selling_items$item_name,
            las = 2, 
            col = "darkgreen",
            main = "Top 10 Best-Selling Items",
            ylab = "Quantity Sold",
            border = NA,  # Remove bar borders
            cex.names = 0.8)  # Adjust label size
    grid(nx = NA, ny = NULL, col = "gray", lty = "dotted")  # Add horizontal grid
  })
  
  # Generate restock warning report
  restock_warning_items <- report_data %>%
    filter(total_quantity < 20 & quantity_sold > 10)
  
  # Plot items needing restock with improved styling (ggplot2 horizontal bar)
  output$restock_warning_plot <- renderPlot({
    if (nrow(restock_warning_items) == 0) {
      plot.new()
      title("✅ No restocking needed.", col.main = "darkgreen")
    } else {
      ggplot(restock_warning_items, aes(x = reorder(item_name, total_quantity), y = total_quantity, fill = total_quantity < 10)) +
        geom_bar(stat = "identity", width = 0.7) +
        coord_flip() +
        scale_fill_manual(values = c("FALSE" = "orange", "TRUE" = "red")) +
        labs(
          title = "⚠️ Items Likely to Need Restocking",
          x = "Item",
          y = "Quantity Remaining"
        ) +
        theme_minimal(base_family = "Arial") +
        theme(
          legend.position = "none",
          plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
          axis.text.y = element_text(size = 12, face = "bold", color = "#2E86C1")
        )
    }
  })
  
  # Generate top revenue items report
  top_revenue_items <- report_data %>%
    arrange(desc(revenue)) %>%
    head(10)
  
  # Plot top revenue items with improved styling
  output$top_revenue_plot <- renderPlot({
    par(mar = c(8, 4, 4, 2))
    barplot(top_revenue_items$revenue,
            names.arg = top_revenue_items$item_name,
            las = 2, 
            col = "steelblue",
            main = "💰 Top 10 Revenue-Generating Items",
            ylab = "Total Revenue",
            border = NA,
            cex.names = 0.8)
    grid(nx = NA, ny = NULL, col = "gray", lty = "dotted")
  })
  
  # Generate least sold items report
  least_sold_items <- report_data %>%
    arrange(quantity_sold) %>%
    head(10)
  
  # Plot least sold items with improved styling (ggplot2 horizontal bar)
  output$least_sold_plot <- renderPlot({
    if (nrow(least_sold_items) == 0) {
      plot.new()
      title("No data.")
    } else {
      ggplot(least_sold_items, aes(x = reorder(item_name, quantity_sold), y = quantity_sold)) +
        geom_bar(stat = "identity", fill = "gray", width = 0.7) +
        coord_flip() +
        labs(
          title = "📉 Least Sold Items",
          x = "Item",
          y = "Quantity Sold"
        ) +
        theme_minimal(base_family = "Arial") +
        theme(
          plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
          axis.text.y = element_text(size = 12, face = "bold", color = "#2E86C1")
        )
    }
  })
  
  # Generate top customers report with improved styling
  top_customers <- get_all_invoices() %>%
    group_by(phone_number) %>%
    summarise(
      total_invoices = n()
    ) %>%
    arrange(desc(total_invoices)) %>%
    head(10)
  
  # Display top customers table with improved styling
  output$top_customers_table <- DT::renderDataTable({
    datatable(top_customers,
              options = list(
                pageLength = 5,
                dom = 'ftip',
                scrollX = TRUE
              ),
              rownames = FALSE) %>%
      formatStyle(
        'total_invoices',
        background = styleColorBar(c(0, max(top_customers$total_invoices)), 'steelblue'),
        backgroundSize = '98% 88%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      )
  })

  # Handle action buttons from mobile card view
  observeEvent(input[[paste0("edit_item_", input$edit_item_mobile_id)]], {
    req(rv$admin_logged_in)
    item_id <- as.numeric(gsub("edit_item_", "", input$edit_item_mobile_id))
    items <- refresh_inventory()
    item <- items[items$item_id == item_id, ]
    if (nrow(item) > 0) {
      updateTextInput(session, "item_name", value = item$item_name)
      updateNumericInput(session, "item_price", value = item$price)
      updateNumericInput(session, "item_quantity", value = item$quantity)
      # Show message about item being edited
      output$inventory_action_status <- renderUI({ 
        div(paste0("Editing item: ", item$item_name), style="color:blue;") 
      })
    }
  })
  
  # Observe all edit_item_X buttons
  observe({
    lapply(refresh_inventory()$item_id, function(id) {
      btn_id <- paste0("edit_item_", id)
      observeEvent(input[[btn_id]], {
        updateTextInput(session, "edit_item_mobile_id", value = id)
        # Trigger the main observer
        session$sendCustomMessage(type = "triggerEditItem", list(id = id))
      }, ignoreNULL = TRUE, ignoreInit = TRUE)
    })
  })
  
  # Similarly for adjust stock buttons
  observeEvent(input[[paste0("adjust_stock_", input$adjust_stock_mobile_id)]], {
    req(rv$admin_logged_in)
    item_id <- as.numeric(gsub("adjust_stock_", "", input$adjust_stock_mobile_id))
    items <- refresh_inventory()
    item <- items[items$item_id == item_id, ]
    if (nrow(item) > 0) {
      # Select this item in the dropdown and scroll to the form
      updateSelectInput(session, "adjust_stock_item", selected = item$item_id)
      updateNumericInput(session, "adjust_stock_value", value = item$quantity)
      output$inventory_action_status <- renderUI({ 
        div(paste0("Adjusting stock for: ", item$item_name), style="color:blue;") 
      })
      # Scroll to the form
      shinyjs::runjs('document.getElementById("adjust_stock_item").scrollIntoView({behavior: "smooth"});')
    }
  })
  
  # Observe all adjust_stock_X buttons
  observe({
    lapply(refresh_inventory()$item_id, function(id) {
      btn_id <- paste0("adjust_stock_", id)
      observeEvent(input[[btn_id]], {
        updateTextInput(session, "adjust_stock_mobile_id", value = id)
        # Trigger the main observer
        session$sendCustomMessage(type = "triggerAdjustStock", list(id = id))
      }, ignoreNULL = TRUE, ignoreInit = TRUE)
    })
  })
  
  # Similarly for delete buttons
  observeEvent(input[[paste0("delete_item_", input$delete_item_mobile_id)]], {
    req(rv$admin_logged_in)
    item_id <- as.numeric(gsub("delete_item_", "", input$delete_item_mobile_id))
    items <- refresh_inventory()
    item <- items[items$item_id == item_id, ]
    if (nrow(item) > 0) {
      # Delete the item
      delete_item(item_id)
      output$inventory_action_status <- renderUI({ 
        div(paste0("Item deleted: ", item$item_name), style="color:green;") 
      })
      # Refresh inventory table
      output$inventory_table <- DT::renderDataTable({ refresh_inventory() }, selection = "single")
    }
  })
  
  # Observe all delete_item_X buttons
  observe({
    lapply(refresh_inventory()$item_id, function(id) {
      btn_id <- paste0("delete_item_", id)
      observeEvent(input[[btn_id]], {
        updateTextInput(session, "delete_item_mobile_id", value = id)
        # Trigger the main observer
        session$sendCustomMessage(type = "triggerDeleteItem", list(id = id))
      }, ignoreNULL = TRUE, ignoreInit = TRUE)
    })
  })
  
  # Add hidden input fields to store the selected item IDs
  output$mobile_action_inputs <- renderUI({
    tagList(
      textInput("edit_item_mobile_id", "", value = "", width = "0px"),
      textInput("adjust_stock_mobile_id", "", value = "", width = "0px"),
      textInput("delete_item_mobile_id", "", value = "", width = "0px")
    )
  })
  
  # JavaScript to handle custom message types
  shinyjs::runjs('
    Shiny.addCustomMessageHandler("triggerEditItem", function(message) {
      var id = message.id;
      $("#edit_item_" + id).click();
    });
    
    Shiny.addCustomMessageHandler("triggerAdjustStock", function(message) {
      var id = message.id;
      $("#adjust_stock_" + id).click();
    });
    
    Shiny.addCustomMessageHandler("triggerDeleteItem", function(message) {
      var id = message.id;
      $("#delete_item_" + id).click();
    });
  ')

  # Make inventory and invoice cards smaller by reducing padding, font size, and max-width
  shinyjs::runjs('$("<style>div.inventory-mobile-card, div.invoice-mobile-card {padding:0.7rem 0.6rem 0.7rem 0.6rem !important; font-size:1rem !important; max-width:370px !important;} div.inventory-mobile-card .item-name, div.invoice-mobile-card .invoice-id {font-size:1.05rem !important;} </style>").appendTo("head");')

  # Wire up mobile invoice card buttons to desktop logic
  observe({
    invs <- refresh_invoices()
    lapply(seq_len(nrow(invs)), function(i) {
      invoice_id <- invs$invoice_id[i]
      # View button
      observeEvent(input[[paste0("view_invoice_btn_mobile_", invoice_id)]], {
        # Simulate selecting the invoice in the table
        invs2 <- refresh_invoices(input$search_invoice_phone)
        idx <- which(invs2$invoice_id == invoice_id)
        if (length(idx) == 1) {
          # Call the same logic as the desktop button
          items <- get_invoice_items(invoice_id)
          inv <- invs2[idx,]
          output$invoice_details_modal <- renderUI({
            showModal(modalDialog(
              title = paste("Invoice #", inv$invoice_id),
              h5("Customer Phone: ", inv$phone_number),
              h5("Date: ", inv$date),
              div(class = "table-responsive",
                DT::renderDataTable(items, 
                  options = list(
                    dom = 't', 
                    paging = FALSE,
                    scrollX = TRUE,
                    columnDefs = list(
                      list(className = 'dt-center', targets = '_all')
                    )
                  ),
                  selection = "none"
                )
              ),
              h4("Total: ", sum(items$price * items$quantity)),
              size = "l",
              easyClose = TRUE
            ))
            NULL
          })
        }
      }, ignoreInit = TRUE, ignoreNULL = TRUE)
      # Print button
      observeEvent(input[[paste0("print_invoice_btn_mobile_", invoice_id)]], {
        invs2 <- refresh_invoices(input$search_invoice_phone)
        idx <- which(invs2$invoice_id == invoice_id)
        if (length(idx) == 1) {
          inv <- invs2[idx,]
          items <- get_invoice_items(invoice_id)
          subtotal <- sum(items$price * items$quantity)
          tax <- subtotal * 0.15
          final_total <- subtotal + tax
          html_file <- tempfile(fileext = ".html")
          logo_path <- normalizePath("www/images/Logo.png", winslash = "/")
          logo_base64 <- base64enc::base64encode(logo_path)
          logo_url <- sprintf("data:image/png;base64,%s", logo_base64)
          html_content <- paste0(
            "<html><head><meta charset='UTF-8'><title>فاتورة رقم: ", inv$invoice_id, "</title>",
            "<style>body { font-family: Arial, sans-serif; direction: rtl; } table { width: 100%; border-collapse: collapse; margin: 20px 0; } th, td { border: 1px solid black; padding: 8px; text-align: center; }</style>",
            "</head><body>",
            "<h2 style='text-align: center;'>فاتورة رقم: ", inv$invoice_id, "</h2>",
            "<p><b>تليفون العميل:</b> ", inv$phone_number, "</p>",
            "<p><b>التاريخ:</b> ", inv$date, "</p>",
            "<table><tr><th>المنتج</th><th>السعر</th><th>الكمية</th><th>الإجمالي</th></tr>",
            if (nrow(items) > 0 && all(c('item_name','price','quantity') %in% colnames(items))) {
              paste(apply(items[,c('item_name','price','quantity')], 1, function(row) {
                total <- as.numeric(row[2]) * as.numeric(row[3])
                paste0("<tr><td>", row[1], "</td><td>", row[2], "</td><td>", row[3], "</td><td>", total, "</td></tr>")
              }), collapse="")
            } else {
              "<tr><td colspan='4'>لا توجد منتجات</td></tr>"
            },
            "</table>",
            "<div style='text-align: left; margin-top: 20px;'>",
            "<p><b>الإجمالي الفرعي:</b> ", subtotal, "</p>",
            "<p><b>الضريبة (15%):</b> ", tax, "</p>",
            "<p style='font-size: 1.2em;'><b>الإجمالي النهائي:</b> ", final_total, "</p>",
            "</div>",
            "<div style='text-align:center; margin-top:30px;'><img src='", logo_url, "' alt='Logo' style='max-width:180px;'></div>",
            "</body></html>"
          )
          writeLines(html_content, html_file)
          pdf_file <- paste0("www/invoice_", inv$invoice_id, ".pdf")
          webshot2::webshot(html_file, file = pdf_file, vwidth = 900, vheight = 1200)
          showModal(modalDialog(
            title = paste("Print Invoice #", inv$invoice_id),
            div(
              p("Invoice has been generated successfully!"),
              tags$a(href=paste0("invoice_", inv$invoice_id, ".pdf"), 
                     "Download Invoice", 
                     target="_blank", 
                     class="btn btn-primary",
                     style="margin-top: 10px;")
            ),
            size = "l",
            easyClose = TRUE
          ))
        }
      }, ignoreInit = TRUE, ignoreNULL = TRUE)
    })
  })

  # Handle SMS test button
  observeEvent(input$test_whatsapp_btn, {
    # Test WhatsApp connection
    test_result <- test_whatsapp_connection()
    
    # Send test message if connection is successful
    if (test_result$success) {
      test_message <- "This is a test message from Rufuf - رفوف. WhatsApp service is working correctly!"
      sms_result <- send_whatsapp(WHATSAPP_PHONE, test_message)
      
      output$whatsapp_test_status <- renderUI({
        if (sms_result$success) {
          div(
            div(icon("check-circle"), " WhatsApp Service Test Successful!", 
                style = "color: green; font-weight: bold; margin-bottom: 10px;"),
            div("A test message has been sent to your WhatsApp number.", 
                style = "color: #666;")
          )
        } else {
          div(
            div(icon("exclamation-circle"), " WhatsApp Service Test Failed", 
                style = "color: red; font-weight: bold; margin-bottom: 10px;"),
            div(sms_result$message, style = "color: #666;")
          )
        }
      })
    } else {
      output$whatsapp_test_status <- renderUI({
        div(
          div(icon("exclamation-circle"), " WhatsApp Service Test Failed", 
              style = "color: red; font-weight: bold; margin-bottom: 10px;"),
          div(test_result$message, style = "color: #666;")
        )
      })
    }
  })
})
