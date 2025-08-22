library(DBI)
library(RSQLite)
library(lubridate)

source("Database/connection.R")
source("Database/setup.R")
source("Database/user.R")
source("Database/item.R")
source("Database/invoice.R")
source("Database/item_invoice.R")

# --- Refresh Database First ---
refresh_database()

# --- Fill Users ---
users <- c("01012345678", "01098765432", "01122334455", "01299887766")
for (phone in users) {
  add_user(phone)
}

# --- Fill Items ---
set.seed(2025)
item_names <- c(
  "عيش بلدي", "عيش فينو", "جبنة قريش", "جبنة رومي", "جبنة بيضاء", "لبن كامل الدسم", "لبن خالي الدسم", "زبادي", "بيض بلدي", "بيض أبيض",
  "زيت عباد", "زيت ذرة", "زيت زيتون", "سكر", "ملح", "شاي ليبتون", "شاي العروسة", "قهوة", "نسكافيه", "مكرونة سباجيتي",
  "مكرونة قلم", "أرز مصري", "أرز بسمتي", "عدس أصفر", "فول مدمس", "حمص", "فاصوليا بيضاء", "لوبيا", "فول سوداني", "لوز",
  "كاجو", "جوز هند", "تمر", "بلح سكوتي", "مشمشية", "قراصيا", "زبيب", "تفاح مصري", "تفاح مستورد", "موز",
  "برتقال", "يوسفي", "عنب", "كمثرى", "فراولة", "مانجو", "بطيخ", "شمام", "جوافة", "رمان",
  "طماطم", "خيار", "بطاطس", "بصل", "جزر", "فلفل أخضر", "فلفل ألوان", "خس", "جرجير", "كابوتشا",
  "كوسة", "باذنجان", "فاصوليا خضراء", "ملوخية", "سبانخ", "كرنب", "قرنبيط", "بامية", "بسلة", "جزر مبشور",
  "لحمة بقري", "لحمة ضاني", "فراخ بلدي", "فراخ بيضاء", "سمك بلطي", "سمك بوري", "جمبري", "كابوريا", "سردين", "تونة",
  "عسل نحل", "عسل أسود", "مربى فراولة", "مربى مشمش", "مربى تين", "زبدة", "سمن بلدي", "سمن نباتي", "مياه معدنية", "مياه غازية",
  "بيبسي", "كوكاكولا", "سبرايت", "فانتا", "عصير مانجو", "عصير برتقال", "عصير تفاح", "شيبسي", "مولتو", "بسكويت"
)
# Fixed real prices for the first 100 items
item_prices <- c(
  1.5, 2.5, 35, 120, 50, 25, 23, 4, 5.5, 5,
  90, 95, 180, 35, 5, 234, 200, 350, 200, 25,
  25, 30, 55, 60, 50, 60, 60, 60, 80, 200,
  250, 100, 40, 35, 100, 120, 90, 60, 90, 35,
  12, 15, 30, 35, 35, 50, 13, 25, 30, 30,
  10, 15, 10, 10, 12, 18, 35, 5, 2, 10,
  18, 12, 22, 10, 15, 10, 10, 35, 22, 12,
  330, 400, 135, 100, 65, 90, 180, 130, 55, 18,
  120, 35, 16, 16, 16, 70, 110, 36, 5, 10,
  10, 10, 10, 10, 12, 12, 12, 5, 5, 5
)
n_items <- 100
items <- data.frame(
  item_name = item_names[1:n_items],
  price = item_prices[1:n_items],
  quantity = sample(10:100, n_items, replace = TRUE),
  barcode = as.character(1000:(1000 + n_items - 1))
)
# Add expiry dates for each item
today <- Sys.Date()
expiry_dates <- rep(NA, n_items)
for (i in 1:n_items) {
  name <- item_names[i]
  # Bakery
  if (grepl("عيش", name)) {
    expiry_dates[i] <- as.character(today + 3)
  # Dairy, eggs, yogurt
  } else if (grepl("جبنة|لبن|زبادي|بيض", name)) {
    expiry_dates[i] <- as.character(today + 7)
  # Fresh produce
  } else if (grepl("تفاح|موز|برتقال|يوسفي|عنب|كمثرى|فراولة|مانجو|بطيخ|شمام|جوافة|رمان|طماطم|خيار|بطاطس|بصل|جزر|فلفل|خس|جرجير|كابوتشا|كوسة|باذنجان|فاصوليا خضراء|ملوخية|سبانخ|كرنب|قرنبيط|بامية|بسلة|جزر مبشور", name)) {
    expiry_dates[i] <- as.character(today + sample(7:14, 1))
  # Meat, poultry, fish
  } else if (grepl("لحمة|فراخ|سمك|جمبري|كابوريا|سردين|تونة", name)) {
    expiry_dates[i] <- as.character(today + 5)
  # Dry goods, nuts, grains, pasta
  } else if (grepl("مكرونة|أرز|عدس|فول|حمص|فاصوليا|لوبيا|فول سوداني|لوز|كاجو|جوز هند|تمر|بلح|مشمشية|قراصيا|زبيب|سكر|ملح|شاي|قهوة|نسكافيه|عسل|مربى|زبدة|سمن|شيبسي|مولتو|بسكويت", name)) {
    expiry_dates[i] <- as.character(today + months(sample(6:12, 1)))
  # Oils
  } else if (grepl("زيت", name)) {
    expiry_dates[i] <- as.character(today + years(1))
  # Canned, bottled, beverages
  } else if (grepl("مياه|بيبسي|كوكاكولا|سبرايت|فانتا|عصير", name)) {
    expiry_dates[i] <- as.character(today + years(1))
  } else {
    expiry_dates[i] <- as.character(today + months(6))
  }
}
items$expiry_date <- expiry_dates
for (i in 1:nrow(items)) {
  add_item(
    item_name = items$item_name[i],
    price = items$price[i],
    quantity = items$quantity[i],
    barcode = items$barcode[i],
    expiry_date = items$expiry_date[i]
  )
}

# --- Create Some Invoices ---
set.seed(123)  # for reproducibility

for (i in 1:5) {
  phone <- sample(users, 1)
  invoice_id <- create_invoice(phone)
  
  selected_items <- sample(1:10, 3)  # 3 random items
  for (item_idx in selected_items) {
    item_id_query <- get_item_by_barcode(items$barcode[item_idx])
    item_id <- item_id_query$item_id
    qty <- sample(1:5, 1)
    add_item_to_invoice(invoice_id, item_id, qty)
  }
  
  Finalize_invoice(invoice_id)
}

cat("\nDatabase filled successfully!\n")

