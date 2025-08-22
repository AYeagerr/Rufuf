# 🛒 Rufuf - رفوف | Supermarket Management System

[![R](https://img.shields.io/badge/R-%3E%3D4.0.0-blue.svg)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-Web%20App-orange.svg)](https://shiny.rstudio.com/)
[![SQLite](https://img.shields.io/badge/SQLite-Database-green.svg)](https://www.sqlite.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A comprehensive, modern supermarket management system built with **R Shiny**, featuring advanced point-of-sale (POS) operations, real-time inventory management, barcode scanning, and intelligent reporting capabilities. Designed for efficiency and user experience in daily supermarket operations.

## ✨ Key Features

### 🏪 **Point of Sale (POS) System**
- **Real-time Barcode Scanning** with audio feedback
- **Smart Shopping Cart** with live updates and stock validation
- **Customer Management** with phone number tracking
- **Automatic Tax Calculation** (15% VAT)
- **Receipt Generation** with PDF export
- **WhatsApp Integration** for digital receipts

### 📊 **Inventory Management**
- **Stock Tracking** with real-time updates
- **Low Stock Alerts** and restock notifications
- **Expiry Date Management** for perishable items
- **Barcode Management** for easy item identification
- **Bulk Import/Export** capabilities

### 👨‍💼 **Admin Dashboard**
- **Comprehensive Analytics** and reporting
- **Sales Performance** metrics
- **Customer Insights** and purchase history
- **Inventory Reports** with visualizations
- **System Settings** and customization

### 🔐 **Security & Data Management**
- **User Authentication** system
- **Database Integrity** with foreign key constraints
- **Input Validation** and sanitization
- **Transaction Logging** for audit trails

## 🏗️ System Architecture

### **Technology Stack**
- **Frontend**: R Shiny with Bootstrap 5 & Custom CSS
- **Backend**: R with modular architecture
- **Database**: SQLite with optimized schema
- **UI Framework**: Bootstrap 5 + Custom Styling
- **Additional Libraries**: 
  - `shinyjs` - Enhanced UI interactions
  - `DT` - Interactive data tables
  - `caret` & `randomForest` - Analytics & predictions
  - `dplyr` - Data manipulation
  - `ggplot2` - Data visualization
  - `webshot2` - PDF generation

### **Project Structure**
```
Supermarket/
├── 📱 app.R                    # Main application entry point
├── 🎨 ui.R                     # User interface definitions
├── ⚙️ server.R                 # Server-side logic & business rules
├── 📷 scan_barcode_module.R    # Barcode scanning functionality
├── 🗃️ initial_data.R           # Initial database setup & sample data
├── 💾 inventory_system.db      # SQLite database
├── 🗄️ Database/                # Database management modules
│   ├── 🔌 connection.R         # Database connection handling
│   ├── 🏗️ setup.R             # Database schema & initialization
│   ├── 👤 user.R               # User management functions
│   ├── 📦 item.R               # Inventory item management
│   ├── 🧾 invoice.R            # Invoice management
│   ├── 🔗 item_invoice.R       # Item-invoice relationships
│   ├── ⚙️ settings.R           # System settings & configuration
│   └── 🛠️ utility.R            # Database utility functions
├── 🌐 www/                      # Static assets & media
│   ├── 🎵 beep_error.mp3       # Error sound effects
│   ├── 🎵 beep_success.mp3     # Success sound effects
│   ├── 🖼️ images/              # Logo & branding assets
│   └── 📄 invoice_*.pdf        # Generated receipts
└── 📋 Supermarket.Rproj        # RStudio project configuration
```

## 🗄️ Database Schema

### **Core Tables**

#### **User Management**
```sql
User (
  user_id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone_number TEXT UNIQUE
)
```

#### **Inventory Items**
```sql
Item (
  item_id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_name TEXT NOT NULL,
  price REAL NOT NULL,
  quantity INTEGER DEFAULT 0,
  quantity_sold INTEGER DEFAULT 0,
  expiry_date TEXT,
  restock_needed INTEGER DEFAULT 0,
  barcode TEXT UNIQUE
)
```

#### **Sales Transactions**
```sql
Invoice (
  invoice_id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone_number TEXT,
  tax REAL DEFAULT 0.15,
  min_value REAL,
  max_value REAL,
  total REAL,
  user_id INTEGER,
  date TEXT DEFAULT CURRENT_DATE,
  FOREIGN KEY (user_id) REFERENCES User(user_id)
)
```

#### **Transaction Details**
```sql
Item_Invoices (
  ii_id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER,
  item_id INTEGER,
  quantity INTEGER,
  FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
  FOREIGN KEY (item_id) REFERENCES Item(item_id)
)
```

## 🚀 Installation & Setup

### **Prerequisites**
- **R** (version 4.0.0 or higher)
- **RStudio** (recommended for development)
- **Required R Packages**:

```r
# Install required packages
install.packages(c(
  "shiny",           # Web application framework
  "shinyjs",         # Enhanced UI interactions
  "DT",              # Interactive data tables
  "caret",           # Machine learning utilities
  "dplyr",           # Data manipulation
  "randomForest",    # Predictive analytics
  "bslib",           # Bootstrap 5 integration
  "ggplot2",         # Data visualization
  "webshot2",        # PDF generation
  "httr",            # HTTP requests
  "mailR",           # Email functionality
  "base64enc",       # Image encoding
  "colourpicker"     # Color input widgets
))
```

### **Quick Start**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/supermarket-management.git
   cd supermarket-management
   ```

2. **Install Dependencies**
   ```r
   # Run in R console
   source("install_dependencies.R")  # If available
   # Or install manually using the packages listed above
   ```

3. **Initialize Database**
   ```r
   # The system will automatically create the database on first run
   # Or manually run:
   source("Database/setup.R")
   create_database()
   ```

4. **Launch Application**
   ```r
   # Method 1: Run directly
   Rscript app.R
   
   # Method 2: Open in RStudio
   # Open Supermarket.Rproj and run app.R
   ```

5. **Access the Application**
   - Open your web browser
   - Navigate to: `http://localhost:3838` (or the port shown in console)

## 📖 Usage Guide

### **For Cashiers**

1. **Start Transaction**
   - Select "Cashier" tab
   - Scan items using barcode scanner or enter manually
   - Items automatically add to cart with audio feedback

2. **Process Sale**
   - Enter customer phone number (Egyptian format supported)
   - Review cart items and quantities
   - System calculates tax and total automatically
   - Complete checkout to generate receipt

3. **Customer Service**
   - View customer purchase history
   - Handle returns and exchanges
   - Generate digital receipts via WhatsApp

### **For Administrators**

1. **Access Admin Panel**
   - Select "Admin" tab
   - Authenticate with admin credentials
   - Access comprehensive management tools

2. **Inventory Management**
   - Add/Edit/Delete inventory items
   - Update stock levels and prices
   - Set restock thresholds
   - Manage barcode assignments

3. **Reports & Analytics**
   - Sales performance metrics
   - Top-selling items analysis
   - Customer behavior insights
   - Inventory turnover reports
   - Revenue analysis with visualizations

4. **System Configuration**
   - Store information and branding
   - Tax rates and business rules
   - User permissions and access control
   - Backup and maintenance tools

## 🔧 Configuration

### **Store Settings**
- **Store Name**: Customize your business name
- **Logo**: Upload your company logo
- **Tax Rate**: Configure VAT percentage
- **Business Rules**: Set minimum/maximum transaction values

### **WhatsApp Integration**
```r
# Configure in server.R
WHATSAPP_API_KEY <- "your_api_key_here"
WHATSAPP_PHONE <- "your_phone_number"
```

### **Email Configuration**
- **SMTP Settings**: Configure email server for receipts
- **Email Templates**: Customize receipt formatting
- **Automated Notifications**: Low stock alerts

## 🧪 Testing & Development

### **Development Mode**
```r
# Enable development features
options(shiny.autoreload = TRUE)
options(shiny.trace = TRUE)
```

### **Database Testing**
```r
# Reset database for testing
source("Database/setup.R")
refresh_database()

# Load sample data
source("initial_data.R")
```

### **Unit Testing**
```r
# Run tests (if test suite is implemented)
# library(testthat)
# test_dir("tests/")
```

## 📊 Performance & Scalability

### **Optimization Features**
- **Database Indexing** on frequently queried fields
- **Connection Pooling** for database operations
- **Lazy Loading** of UI components
- **Efficient Data Structures** for large datasets

### **Recommended System Requirements**
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 10GB available space
- **CPU**: Multi-core processor
- **Network**: Stable internet connection for WhatsApp integration

## 🔒 Security Features

### **Data Protection**
- **Input Validation** and sanitization
- **SQL Injection Prevention** with parameterized queries
- **XSS Protection** through proper output encoding
- **CSRF Protection** for form submissions

### **Access Control**
- **User Authentication** system
- **Role-based Permissions**
- **Session Management**
- **Audit Logging** for all transactions

## 🚨 Troubleshooting

### **Common Issues**

1. **Database Connection Errors**
   ```r
   # Check database file permissions
   # Verify SQLite installation
   # Check file path in connection.R
   ```

2. **Package Installation Issues**
   ```r
   # Update R to latest version
   # Install from CRAN mirrors
   # Check package compatibility
   ```

3. **Barcode Scanner Problems**
   - Verify scanner drivers
   - Check input focus settings
   - Test with manual barcode entry

4. **Performance Issues**
   - Monitor database size
   - Check system resources
   - Optimize database queries

### **Debug Mode**
```r
# Enable detailed error messages
options(shiny.error = browser)
options(shiny.fullstacktrace = TRUE)
```

## 🔮 Future Enhancements

### **Planned Features**
- 📱 **Mobile App** integration
- 🤖 **AI-powered** inventory predictions
- 📈 **Advanced Analytics** dashboard
- 🏪 **Multi-location** support
- 💳 **Payment Gateway** integration
- 📦 **Supplier Management** system
- 👥 **Employee Management** portal
- 🔔 **Real-time Notifications**

### **API Development**
- **RESTful API** for external integrations
- **Webhook Support** for real-time updates
- **Third-party Integrations** (accounting software, e-commerce platforms)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### **Development Setup**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### **Code Style**
- Follow R coding conventions
- Use meaningful variable names
- Add comments for complex logic
- Include error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Lead Developer**: [Your Name]
- **Project Manager**: [Manager Name]
- **UI/UX Designer**: [Designer Name]
- **Database Architect**: [Architect Name]

## 📞 Support & Contact

- **Email**: [your.email@domain.com]
- **WhatsApp**: [+20 10 2323 2234]
- **Project Issues**: [GitHub Issues](https://github.com/yourusername/supermarket-management/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/supermarket-management/wiki)

## 🙏 Acknowledgments

- **R Shiny Community** for the excellent web framework
- **Bootstrap Team** for the responsive UI components
- **SQLite Developers** for the lightweight database
- **Open Source Contributors** who made this project possible

---

<div align="center">

**Made with ❤️ for modern retail management**

[![GitHub stars](https://img.shields.io/github/stars/yourusername/supermarket-management?style=social)](https://github.com/yourusername/supermarket-management)
[![GitHub forks](https://img.shields.io/github/forks/yourusername/supermarket-management?style=social)](https://github.com/yourusername/supermarket-management)
[![GitHub issues](https://img.shields.io/github/issues/yourusername/supermarket-management)](https://github.com/yourusername/supermarket-management/issues)

</div> 
