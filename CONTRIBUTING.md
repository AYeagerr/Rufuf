# Contributing to Rufuf Supermarket Management System

Thank you for your interest in contributing to our Supermarket Management System! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### **Ways to Contribute**
- 🐛 **Report Bugs**: Help us identify and fix issues
- 💡 **Suggest Features**: Propose new functionality
- 📝 **Improve Documentation**: Enhance README, code comments, or user guides
- 🔧 **Code Contributions**: Submit pull requests with improvements
- 🧪 **Testing**: Help test new features and bug fixes
- 🌐 **Localization**: Help translate the interface to other languages

### **Before You Start**
1. **Check Existing Issues**: Look for open issues or feature requests
2. **Discuss Changes**: For major changes, open an issue first to discuss
3. **Follow Guidelines**: Read and follow the coding standards below

## 🚀 Development Setup

### **Prerequisites**
- R (version 4.0.0 or higher)
- RStudio (recommended)
- Git
- Basic knowledge of R Shiny

### **Local Development**
1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/supermarket-management.git
   cd supermarket-management
   ```

2. **Install Dependencies**
   ```r
   install.packages(c("shiny", "shinyjs", "DT", "caret", "dplyr", 
                     "randomForest", "bslib", "ggplot2", "webshot2"))
   ```

3. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b bugfix/issue-description
   ```

## 📝 Coding Standards

### **R Code Style**
- **Naming Convention**: Use snake_case for variables and functions
- **Indentation**: 2 spaces (no tabs)
- **Line Length**: Keep lines under 80 characters when possible
- **Comments**: Add comments for complex logic or business rules

### **Example Code Style**
```r
# Good
calculate_total_with_tax <- function(subtotal, tax_rate = 0.15) {
  tax_amount <- subtotal * tax_rate
  total <- subtotal + tax_amount
  return(round(total, 2))
}

# Avoid
calculateTotalWithTax=function(subtotal,tax_rate=0.15){
tax_amount=subtotal*tax_rate
total=subtotal+tax_amount
return(round(total,2))
}
```

### **File Organization**
- **Database Functions**: Keep in `Database/` directory
- **UI Components**: Organize in `ui.R` with clear sections
- **Server Logic**: Separate business logic in `server.R`
- **Utility Functions**: Place in appropriate utility files

### **Error Handling**
```r
# Always include error handling
safe_function <- function(data) {
  tryCatch({
    result <- process_data(data)
    return(result)
  }, error = function(e) {
    log_error(e$message)
    return(NULL)
  })
}
```

## 🧪 Testing Guidelines

### **Testing Requirements**
- **New Features**: Must include basic functionality tests
- **Bug Fixes**: Must include regression tests
- **Database Changes**: Must be tested with sample data
- **UI Changes**: Must be tested across different screen sizes

### **Test Structure**
```r
# Example test structure
test_that("calculate_total_with_tax works correctly", {
  expect_equal(calculate_total_with_tax(100), 115)
  expect_equal(calculate_total_with_tax(50, 0.20), 60)
  expect_error(calculate_total_with_tax(-100))
})
```

## 📋 Pull Request Process

### **Before Submitting**
1. **Test Your Changes**: Ensure everything works locally
2. **Update Documentation**: Update README, comments, or user guides
3. **Check Code Style**: Follow the coding standards above
4. **Test Edge Cases**: Consider unusual inputs or scenarios

### **Pull Request Template**
```markdown
## Description
Brief description of changes made

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## Testing
- [ ] Tested locally
- [ ] Added/updated tests
- [ ] All tests pass

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes
```

### **Review Process**
1. **Automated Checks**: CI/CD pipeline will run tests
2. **Code Review**: At least one maintainer must approve
3. **Testing**: Changes will be tested in staging environment
4. **Merge**: Approved changes will be merged to main branch

## 🐛 Bug Reports

### **Bug Report Template**
```markdown
## Bug Description
Clear description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- R Version: [e.g., 4.2.0]
- Operating System: [e.g., Windows 10, macOS 12]
- Browser: [if applicable]

## Additional Information
Screenshots, error messages, or other relevant details
```

## 💡 Feature Requests

### **Feature Request Template**
```markdown
## Feature Description
Clear description of the requested feature

## Use Case
How would this feature be used?

## Benefits
What problems would this solve?

## Implementation Ideas
Any thoughts on how to implement this?

## Priority
- [ ] High (blocking)
- [ ] Medium (important)
- [ ] Low (nice to have)
```

## 📚 Documentation

### **Documentation Standards**
- **README Updates**: Update when adding new features
- **Code Comments**: Explain complex business logic
- **User Guides**: Update when changing user workflows
- **API Documentation**: Document new functions and parameters

### **Comment Examples**
```r
# Function to calculate total with tax
# @param subtotal: The subtotal amount before tax
# @param tax_rate: Tax rate as decimal (default: 0.15 for 15%)
# @return: Total amount including tax, rounded to 2 decimal places
calculate_total_with_tax <- function(subtotal, tax_rate = 0.15) {
  # ... implementation
}
```

## 🔒 Security

### **Security Guidelines**
- **Never commit sensitive data** (API keys, passwords, etc.)
- **Validate all inputs** to prevent injection attacks
- **Use parameterized queries** for database operations
- **Report security issues** privately to maintainers

### **Reporting Security Issues**
If you discover a security vulnerability, please:
1. **DO NOT** create a public issue
2. **Email** security@yourdomain.com
3. **Include** detailed description and reproduction steps
4. **Wait** for maintainer response before public disclosure

## 🏷️ Version Control

### **Commit Message Format**
```
type(scope): description

feat(cart): add quantity validation for cart items
fix(database): resolve connection timeout issues
docs(readme): update installation instructions
style(ui): improve button spacing and alignment
```

### **Branch Naming**
- `feature/feature-name` - New features
- `bugfix/issue-description` - Bug fixes
- `hotfix/critical-issue` - Critical fixes
- `docs/documentation-update` - Documentation changes

## 📞 Getting Help

### **Communication Channels**
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Email**: For security issues or private matters

### **Resources**
- [R Shiny Documentation](https://shiny.rstudio.com/)
- [R Style Guide](https://style.tidyverse.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

## 🙏 Recognition

### **Contributor Recognition**
- **Contributors List**: All contributors will be listed in README
- **Commit History**: Proper attribution in git history
- **Release Notes**: Recognition in release announcements

### **Hall of Fame**
Contributors who make significant contributions will be added to our Hall of Fame with special recognition.

---

**Thank you for contributing to making Rufuf Supermarket Management System better! 🎉**

If you have any questions about contributing, feel free to open an issue or reach out to the maintainers.
