# Rufuf Supermarket Management System - Dependency Installer
# This script installs all required R packages for the system

cat("🚀 Installing dependencies for Rufuf Supermarket Management System...\n\n")

# List of required packages
required_packages <- c(
  # Core Shiny packages
  "shiny",           # Web application framework
  "shinyjs",         # Enhanced UI interactions
  "bslib",           # Bootstrap 5 integration
  
  # Data manipulation and display
  "DT",              # Interactive data tables
  "dplyr",           # Data manipulation
  "ggplot2",         # Data visualization
  
  # Machine learning and analytics
  "caret",           # Machine learning utilities
  "randomForest",    # Predictive analytics
  
  # Additional utilities
  "webshot2",        # PDF generation
  "httr",            # HTTP requests for API calls
  "mailR",           # Email functionality
  "base64enc",       # Image encoding
  "colourpicker"     # Color input widgets
)

# Function to install packages
install_if_missing <- function(package_name) {
  if (!require(package_name, character.only = TRUE, quietly = TRUE)) {
    cat("📦 Installing", package_name, "...\n")
    tryCatch({
      install.packages(package_name, dependencies = TRUE)
      cat("✅", package_name, "installed successfully\n")
    }, error = function(e) {
      cat("❌ Failed to install", package_name, ":", e$message, "\n")
    })
  } else {
    cat("✅", package_name, "already installed\n")
  }
}

# Install packages
cat("📋 Checking and installing required packages:\n")
cat("=" %R% 50, "\n")

for (package in required_packages) {
  install_if_missing(package)
}

cat("\n" %R% "=" %R% 50, "\n")

# Check if all packages are available
cat("\n🔍 Verifying package installation...\n")
missing_packages <- c()

for (package in required_packages) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    missing_packages <- c(missing_packages, package)
  }
}

if (length(missing_packages) == 0) {
  cat("🎉 All packages installed successfully!\n")
  cat("🚀 You can now run the application with: source('app.R')\n")
} else {
  cat("⚠️  Some packages could not be installed:\n")
  for (package in missing_packages) {
    cat("   -", package, "\n")
  }
  cat("\n💡 Try installing them manually or check your internet connection.\n")
}

# Additional setup instructions
cat("\n📚 Additional Setup Information:\n")
cat("1. Make sure you have R version 4.0.0 or higher\n")
cat("2. Ensure you have write permissions in your R library directory\n")
cat("3. If you encounter issues, try updating R and RStudio\n")
cat("4. For webshot2, you may need to install PhantomJS:\n")
cat("   - Windows: Download from https://phantomjs.org/\n")
cat("   - macOS: brew install phantomjs\n")
cat("   - Linux: sudo apt-get install phantomjs\n")

cat("\n🎯 System ready for Rufuf Supermarket Management System!\n")
