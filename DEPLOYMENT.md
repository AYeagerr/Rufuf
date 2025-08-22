# 🚀 Deployment Guide - Rufuf Supermarket Management System

This guide covers deploying the Rufuf Supermarket Management System in various environments.

## 🏠 Local Development

### **Prerequisites**
- R (version 4.0.0 or higher)
- RStudio (recommended)
- Required R packages (see `install_dependencies.R`)

### **Quick Start**
```r
# Install dependencies
source("install_dependencies.R")

# Run the application
source("app.R")
```

### **Access**
- **URL**: `http://localhost:3838` (or port shown in console)
- **Environment**: Development mode with auto-reload

## 🏢 Production Deployment

### **Option 1: RStudio Connect (Recommended)**

#### **Prerequisites**
- RStudio Connect server
- Access to RStudio Connect dashboard

#### **Deployment Steps**
1. **Prepare Application**
   ```r
   # Ensure all dependencies are in install_dependencies.R
   # Test locally before deployment
   ```

2. **Upload to RStudio Connect**
   - Log into RStudio Connect
   - Click "New Content" → "Shiny App"
   - Upload your project folder
   - Configure environment variables if needed

3. **Configuration**
   - Set application title and description
   - Configure access permissions
   - Set resource limits (memory, CPU)

#### **Environment Variables**
```r
# Set in RStudio Connect dashboard
WHATSAPP_API_KEY=your_api_key
WHATSAPP_PHONE=your_phone_number
DATABASE_PATH=/path/to/database
```

### **Option 2: Shiny Server**

#### **Prerequisites**
- Linux server (Ubuntu 20.04+ recommended)
- R installed
- Shiny Server installed

#### **Installation**
```bash
# Install R
sudo apt update
sudo apt install r-base r-base-dev

# Install Shiny Server
sudo apt install gdebi-core
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.17.973-amd64.deb
sudo gdebi shiny-server-1.5.17.973-amd64.deb

# Install required R packages
sudo R -e "install.packages(c('shiny', 'shinyjs', 'DT', 'caret', 'dplyr', 'randomForest', 'bslib', 'ggplot2', 'webshot2', 'httr', 'mailR', 'base64enc', 'colourpicker'), repos='https://cran.rstudio.com/')"
```

#### **Configuration**
```bash
# Edit Shiny Server configuration
sudo nano /etc/shiny-server/shiny-server.conf

# Add your application
server {
  listen 3838;
  
  location /supermarket {
    app_dir /srv/shiny-server/supermarket;
    app_index_enabled off;
  }
}
```

#### **Deploy Application**
```bash
# Copy application to Shiny Server directory
sudo cp -r /path/to/your/app /srv/shiny-server/supermarket

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/supermarket
sudo chmod -R 755 /srv/shiny-server/supermarket

# Restart Shiny Server
sudo systemctl restart shiny-server
```

### **Option 3: Docker Deployment**

#### **Dockerfile**
```dockerfile
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    phantomjs \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinyjs', 'DT', 'caret', 'dplyr', 'randomForest', 'bslib', 'ggplot2', 'webshot2', 'httr', 'mailR', 'base64enc', 'colourpicker'), repos='https://cran.rstudio.com/')"

# Copy application
COPY . /srv/shiny-server/supermarket/

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/supermarket

# Expose port
EXPOSE 3838

# Run application
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/supermarket', host = '0.0.0.0', port = 3838)"]
```

#### **Docker Compose**
```yaml
version: '3.8'
services:
  supermarket:
    build: .
    ports:
      - "3838:3838"
    volumes:
      - ./data:/srv/shiny-server/supermarket/data
    environment:
      - WHATSAPP_API_KEY=${WHATSAPP_API_KEY}
      - WHATSAPP_PHONE=${WHATSAPP_PHONE}
    restart: unless-stopped
```

#### **Deploy with Docker**
```bash
# Build and run
docker-compose up -d

# Or build manually
docker build -t supermarket-app .
docker run -d -p 3838:3838 --name supermarket supermarket-app
```

## ☁️ Cloud Deployment

### **AWS EC2**
1. **Launch EC2 Instance**
   - Use Ubuntu 20.04 LTS
   - Minimum t3.medium (2 vCPU, 4GB RAM)
   - Configure security groups for port 3838

2. **Install Dependencies**
   ```bash
   # Follow Shiny Server installation steps above
   ```

3. **Configure Domain**
   - Use Route 53 or external DNS
   - Set up SSL certificate with Let's Encrypt

### **Google Cloud Platform**
1. **Create Compute Engine Instance**
   - Use Ubuntu 20.04 LTS
   - Minimum e2-medium (2 vCPU, 4GB RAM)

2. **Deploy Application**
   - Follow Shiny Server steps
   - Use Cloud Load Balancer for SSL termination

### **Azure**
1. **Create Virtual Machine**
   - Use Ubuntu 20.04 LTS
   - Minimum Standard_B2s (2 vCPU, 4GB RAM)

2. **Deploy Application**
   - Follow Shiny Server steps
   - Use Application Gateway for SSL

## 🔒 Security Considerations

### **Production Security**
- **HTTPS**: Always use SSL/TLS in production
- **Firewall**: Restrict access to necessary ports only
- **Authentication**: Implement proper user authentication
- **Database**: Use secure database connections
- **Updates**: Keep system and packages updated

### **SSL Configuration**
```bash
# Install Certbot
sudo apt install certbot

# Get SSL certificate
sudo certbot certonly --standalone -d yourdomain.com

# Configure Nginx (if using as reverse proxy)
sudo nano /etc/nginx/sites-available/supermarket

# Restart Nginx
sudo systemctl restart nginx
```

## 📊 Monitoring & Maintenance

### **System Monitoring**
```bash
# Check application status
sudo systemctl status shiny-server

# View logs
sudo tail -f /var/log/shiny-server/supermarket-*.log

# Monitor resources
htop
df -h
free -h
```

### **Backup Strategy**
```bash
# Database backup
cp /path/to/inventory_system.db /backup/inventory_system_$(date +%Y%m%d).db

# Application backup
tar -czf /backup/supermarket_$(date +%Y%m%d).tar.gz /srv/shiny-server/supermarket/

# Automated backup script
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup database
cp /srv/shiny-server/supermarket/inventory_system.db $BACKUP_DIR/db_$DATE.db

# Backup application
tar -czf $BACKUP_DIR/app_$DATE.tar.gz /srv/shiny-server/supermarket/

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

### **Performance Optimization**
- **Database**: Regular VACUUM and ANALYZE
- **Memory**: Monitor and adjust R memory limits
- **Caching**: Implement caching for frequently accessed data
- **CDN**: Use CDN for static assets

## 🚨 Troubleshooting

### **Common Issues**

1. **Application Won't Start**
   ```bash
   # Check logs
   sudo tail -f /var/log/shiny-server/supermarket-*.log
   
   # Check permissions
   sudo chown -R shiny:shiny /srv/shiny-server/supermarket
   ```

2. **Package Installation Issues**
   ```r
   # Update R packages
   update.packages()
   
   # Install from specific repository
   install.packages("package_name", repos="https://cran.rstudio.com/")
   ```

3. **Database Connection Issues**
   ```r
   # Test database connection
   source("Database/connection.R")
   conn <- get_connection()
   dbListTables(conn)
   dbDisconnect(conn)
   ```

### **Support Resources**
- **R Shiny Documentation**: https://shiny.rstudio.com/
- **Shiny Server Documentation**: https://docs.rstudio.com/shiny-server/
- **RStudio Connect Documentation**: https://docs.rstudio.com/connect/
- **GitHub Issues**: Report bugs and request features

## 📈 Scaling Considerations

### **Horizontal Scaling**
- **Load Balancer**: Distribute traffic across multiple instances
- **Database**: Use external database service (RDS, Cloud SQL)
- **Session Management**: Implement shared session storage

### **Vertical Scaling**
- **Memory**: Increase RAM for large datasets
- **CPU**: Use more powerful instances for complex calculations
- **Storage**: Use SSD storage for better I/O performance

---

**For additional deployment support, please open an issue on GitHub or contact the development team.**
