# Contributing to Home Panel App

Thank you for your interest in contributing to the Home Panel App! This document provides guidelines and standards for contributing to the project.

## 🚀 Getting Started

### Prerequisites

- **Xcode**: 26.0.1 or later
- **iOS**: 18.7.1 or later
- **Swift**: 6.0
- **Git**: Latest version

### Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/home_panel.git
   cd home_panel
   ```

2. **Open in Xcode**
   ```bash
   open HomePanelApp/HomePanelApp.xcodeproj
   ```

3. **Verify build**
   ```bash
   ./scripts/compile_check.sh
   ```

## 📋 Development Guidelines

### Code Style

#### Swift Conventions
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Prefer `let` over `var` when possible
- Use `guard` statements for early returns
- Implement proper error handling with `Result` types

#### Architecture Patterns
- **MVVM**: Use ViewModels for state management with `@Published` properties
- **Dependency Injection**: Use protocols for service dependencies
- **@MainActor**: All ViewModels and UI-related classes must be `@MainActor`
- **Async/Await**: Use modern Swift concurrency for network operations
- **Combine**: Use `@Published` properties for reactive programming

#### Graceful Degradation Pattern

Services that depend on external systems should implement graceful degradation to maintain app functionality during temporary failures:

**Principles**:
- **Prefer Availability**: Show cached/fallback data when external system is unavailable
- **Prioritize Something Over Nothing**: Display last-known state rather than blocking UI
- **Natural Failure Points**: Let specific operations fail with clear errors
- **Clear Documentation**: Document the behavior in code comments and architecture docs

**Example**: `BaseHubAdapter.isReachable` returns `true` on connection errors to enable fallback device display with cached states. This allows users to view their home automation status even during temporary hub outages.

**Implementation Guideline**: When implementing services that interact with external systems:
1. Consider what cached/fallback data is available
2. Decide if strict accuracy or availability is more important
3. Return permissive results that allow UI to continue
4. Document the design choice clearly
5. Ensure actual operations provide appropriate error messages

See `ADR-003-hub-graceful-degradation.md` for detailed rationale.

#### File Organization
```
HomePanelApp/
├── App/                    # App entry point
├── Models/                 # Data models
├── Services/               # Business logic services
├── ViewModels/             # MVVM view models
├── Views/                  # SwiftUI views
│   ├── Components/         # Reusable UI components
│   ├── Alarm/             # Alarm-specific views
│   ├── Camera/            # Camera-specific views
│   └── Settings/          # Settings views
├── Utilities/             # Helper functions and utilities
└── Resources/             # Assets and configuration
```

### Code Quality Standards

#### Documentation
- Add comprehensive documentation comments for public APIs
- Use `///` for documentation comments
- Include parameter descriptions and return values
- Document complex business logic

#### Error Handling
- Use `Result<Success, Error>` for operations that can fail
- Provide user-friendly error messages
- Implement retry mechanisms for network operations
- Log errors for debugging but don't expose technical details to users

#### Logging
- ❌ Never use `print()` directly in application code
- ✅ Always use `DebugLogger.log()`, `.success()`, `.error()`, `.warning()`
- Include appropriate feature flag: `.camera`, `.hubService`, `.alarm`, `.settings`, `.automation`, `.common`
- Choose appropriate log level:
  - `log()` for general information
  - `success()` for successful operations
  - `error()` for failures
  - `warning()` for potential issues

**Example:**
```swift
// ❌ Wrong
print("Camera loaded")

// ✅ Correct
DebugLogger.log("Camera loaded", feature: .camera)
```

#### Configuration Values

- ❌ Never use hardcoded timeout values
- ✅ Always use `TimeoutConfiguration` for network timeouts
- ✅ Add new timeout types to `TimeoutConfiguration` if needed

**Example**:
```swift
// Bad
try await withTimeout(seconds: 30) { }

// Good
try await withTimeout(seconds: TimeoutConfiguration.standardRequest) { }
```

#### Testing
- Write unit tests for business logic
- Test error scenarios and edge cases
- Use dependency injection for testable code
- Mock external dependencies in tests

### UI/UX Guidelines

#### SwiftUI Best Practices
- Use proper SwiftUI lifecycle methods (`onAppear`, `onDisappear`)
- Implement accessibility labels for VoiceOver support
- Support both light and dark modes
- Use SF Symbols for icons
- Follow existing DesignSystem patterns

#### Performance
- Use `LazyVGrid` for efficient scrolling
- Implement visibility-based loading for camera streams
- Pause streams when cells are off-screen
- Use proper memory management for image streams

## 🔄 Development Workflow

### Branch Strategy
- **main**: Production-ready code
- **feature/**: New features and enhancements
- **bugfix/**: Bug fixes
- **hotfix/**: Critical production fixes

### Commit Messages
Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

Examples:
```
feat(alarm): add PIN validation for mode changes
fix(camera): resolve memory leak in stream management
docs(api): update Vera Hub integration guide
```

### Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow code style guidelines
   - Add tests if applicable
   - Update documentation if needed

3. **Test your changes**
   ```bash
   # Compile check
   ./scripts/compile_check.sh
   
   # Check for syntax errors
   ./scripts/check_syntax_errors.sh
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat(scope): your commit message"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Use the PR template
   - Provide clear description of changes
   - Link related issues
   - Request review from maintainers

### PR Requirements

- [ ] Code compiles without errors
- [ ] Follows established code style
- [ ] Includes tests for new functionality
- [ ] Updates documentation if needed
- [ ] No breaking changes without discussion
- [ ] Performance impact considered

## 🧪 Testing

### Unit Testing
- Test ViewModels and Services
- Mock external dependencies
- Test error scenarios
- Verify state management

### Integration Testing
- Test Vera Hub API integration
- Test camera streaming functionality
- Test PIN management and lockout system
- Test settings persistence

### Manual Testing
- Test on both iPhone and iPad
- Verify accessibility features
- Test in both light and dark modes
- Test network error scenarios

### Testing Commands
```bash
# Run tests
xcodebuild test -project HomePanelApp.xcodeproj -scheme HomePanelApp

# Check syntax
./scripts/check_syntax_errors.sh

# Full compilation
./scripts/compile_check.sh
```

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment**
   - iOS version
   - Xcode version
   - Device model

2. **Steps to reproduce**
   - Clear, numbered steps
   - Expected vs actual behavior

3. **Additional context**
   - Screenshots if applicable
   - Console logs
   - Network configuration

## 💡 Feature Requests

When suggesting features:

1. **Check existing issues** first
2. **Describe the problem** you're trying to solve
3. **Provide use cases** and examples
4. **Consider implementation** complexity
5. **Discuss with maintainers** before major work

## 📚 Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [iOS App Architecture](https://developer.apple.com/design/human-interface-guidelines/)

### Project-Specific
- [Architecture Overview](docs/architecture/overview.md)
- [API Integration](docs/integration/)
- [Development Tools](docs/development/cursor-tools.md)

## 🤝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow the golden rule

## 📞 Getting Help

- **Documentation**: Check the [docs](docs/) directory
- **Issues**: Search existing issues or create new ones
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: Request reviews from experienced contributors

---

Thank you for contributing to the Home Panel App! 🎉
