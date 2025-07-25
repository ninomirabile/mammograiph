# Contributing to AI Medical Imaging - Starter Kit

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
- Use the GitHub issue tracker
- Provide a clear and descriptive title
- Include steps to reproduce the issue
- Specify your environment (OS, browser, etc.)
- Include error messages if applicable

### Suggesting Features
- Use the GitHub issue tracker with the "enhancement" label
- Describe the feature and its benefits
- Provide use cases and examples
- Consider implementation complexity

### Code Contributions
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📋 Development Guidelines

### Code Style
- Follow existing code style and conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Testing
- Add tests for new features
- Ensure all tests pass before submitting
- Include both unit and integration tests

### Documentation
- Update README.md if adding new features
- Add inline documentation for complex functions
- Update API documentation if changing endpoints

## 🏗️ Project Structure

```
├── backend/                 # FastAPI backend
│   ├── api/                # API endpoints
│   ├── ai/                 # AI models and logic
│   ├── storage/            # Database models and operations
│   └── main.py             # Application entry point
├── frontend/               # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── services/       # API services
│   │   └── types/          # TypeScript types
│   └── package.json
├── docker/                 # Docker configurations
├── scripts/                # Utility scripts
└── docs/                   # Documentation
```

## 🚀 Getting Started

1. Clone the repository
2. Install dependencies (see README.md)
3. Set up the development environment
4. Run the application locally
5. Make your changes
6. Test thoroughly
7. Submit your contribution

## 📝 Commit Message Guidelines

Use conventional commit messages:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests
- `chore:` for maintenance tasks

Example: `feat: add image preview functionality`

## 🔒 Security

- Do not commit sensitive information (API keys, passwords, etc.)
- Report security vulnerabilities privately
- Follow security best practices
- Validate all user inputs

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project (CC BY-NC 4.0).

## 🆘 Need Help?

- Check existing issues and discussions
- Ask questions in the issue tracker
- Review the documentation
- Contact the maintainers

Thank you for contributing! 🎉 