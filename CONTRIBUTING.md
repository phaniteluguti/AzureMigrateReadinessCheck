# Contributing to Azure Migrate Readiness Check

Thank you for your interest in contributing to this project! 🎉

## How to Contribute

### Reporting Issues

If you encounter a bug or have a feature request:

1. Check if the issue already exists in the [Issues](../../issues) section
2. If not, create a new issue with:
   - Clear description of the problem or feature
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - PowerShell version and OS information
   - Relevant log snippets or error messages

### Submitting Changes

1. **Fork the Repository**
   ```bash
   gh repo fork phaniteluguti/AzureMigrateReadinessCheck
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow existing code style and conventions
   - Add comments for complex logic
   - Update documentation if needed
   - Test your changes thoroughly

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add: Brief description of your changes"
   ```
   
   Use commit prefixes:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for improvements
   - `Docs:` for documentation changes

5. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a PR on GitHub with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots/logs if applicable

### Code Guidelines

- **PowerShell Best Practices**
  - Use approved verbs for function names
  - Include comment-based help for functions
  - Handle errors gracefully with try-catch
  - Write descriptive variable names
  - Add parameter validation

- **Documentation**
  - Update README.md for new features
  - Add examples to EXAMPLES.md
  - Update QUICKSTART.md if user workflow changes
  - Keep hyperlinks working

- **Testing**
  - Test in both interactive and parameter modes
  - Verify all migration approaches (VMware, Hyper-V, Physical)
  - Test both authentication methods
  - Check HTML report generation
  - Validate on different Windows Server versions

### Areas for Contribution

We welcome contributions in these areas:

1. **New Features**
   - Additional prerequisite checks
   - Support for more Azure clouds (Government, China)
   - Enhanced networking tests
   - More authentication methods
   - Appliance configuration automation

2. **Improvements**
   - Better error messages
   - Performance optimizations
   - Enhanced reporting
   - Additional examples
   - Localization/internationalization

3. **Documentation**
   - More detailed troubleshooting guides
   - Video tutorials
   - Architecture diagrams
   - Translation to other languages

4. **Bug Fixes**
   - Fix reported issues
   - Improve error handling
   - Edge case handling

### Questions?

- Check existing [Issues](../../issues) and [Discussions](../../discussions)
- Review the [README.md](README.md) and other documentation
- Create a new discussion for questions

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the best outcome for the project
- Help others learn and grow

Thank you for contributing! 🚀
