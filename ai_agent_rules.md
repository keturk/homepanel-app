# Home Panel App - Cursor AI Assistant Rules

## Project Context
This is a SwiftUI iOS app for home automation and security management, specifically designed for iPad. The app integrates with Vera Hub alarm systems and includes planned camera surveillance features.

## Key Architecture Patterns
- **MVVM Architecture**: Use ViewModels for state management with @Published properties
- **Dependency Injection**: Services are injected through DependencyContainer
- **MainActor**: All ViewModels and UI-related classes are @MainActor
- **Async/Await**: Use modern Swift concurrency for network operations
- **Combine**: Use @Published properties and Combine for reactive programming

## Code Style Guidelines
- Follow existing DesignSystem patterns for spacing, colors, and typography
- Use proper SwiftUI lifecycle methods (onAppear, onDisappear)
- Implement proper error handling with try/catch and Result types
- Use meaningful variable and function names
- Add comprehensive documentation comments
- Follow existing file organization patterns

## Common Patterns to Reuse
- **Grid Layouts**: Use LazyVGrid with 2-column layout for future camera grids
- **Loading States**: Use ProgressView with DesignSystem styling
- **Error Handling**: Show user-friendly error messages with retry options
- **Performance**: Implement visibility-based loading (onAppear/onDisappear)
- **State Management**: Use @StateObject for ViewModels, @ObservedObject for dependencies

## File Organization
- Views go in `Views/` with subdirectories by feature
- ViewModels go in `ViewModels/` with subdirectories by feature
- Models go in `Models/` with subdirectories by domain
- Services go in `Services/` with subdirectories by domain
- Utilities go in `Utilities/` for shared helper functions
- Design system components go in `Views/Components/`

## Testing Approach
- Always compile with `xcodebuild` to check for syntax errors
- Use iPad Pro 13-inch (M4) simulator for testing
- Test both empty states and populated states
- Verify performance with alarm state changes and PIN operations

## Documentation
- Update relevant README.md files in the codebase structure
- Follow the feature-oriented documentation structure with embedded READMEs
- Document new architecture patterns and components in appropriate feature folders
- Include performance optimization notes in comments
- Update file structure documentation when adding new files
- Reference the comprehensive documentation in HomePanelApp/README.md
- For AI tools, reference PROJECT_CONTEXT.md for complete project context

## Common Commands
- Compile: `cd HomePanelApp && xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build`
- Open Xcode: `open HomePanelApp.xcodeproj`

## Development Scripts (./scripts/)
- Check syntax errors: `./scripts/check_syntax_errors.sh`
- Full compilation: `./scripts/compile_check.sh`
- Run all tests: `./scripts/run_tests.sh`
- Open Xcode: `./scripts/open_xcode.sh`
- Apply quick fixes: `./scripts/quick_fixes.sh`

## Error Handling Patterns
- Use Result<Success, Error> for operations that can fail
- Provide user-friendly error messages
- Implement retry mechanisms for network operations
- Log errors for debugging but don't expose technical details to users

## Performance Considerations
- Only load streams for visible camera cells
- Pause streams when cells are off-screen
- Use LazyVGrid for efficient scrolling
- Implement proper memory management for image streams
- Use @MainActor for UI updates only

## Integration Points
- Vera Hub: Use VeraHubService for alarm operations
- Keychain: Use KeychainService for secure credential storage
- UserDefaults: Use for non-sensitive app preferences
- Blue Iris: Use CameraConfigService for camera configuration and CameraWebView for web integration

## Camera Integration Patterns
- **Web View Integration**: Use WKWebView with JavaScript enabled for Blue Iris UI
- **URL Credential Embedding**: Build URLs with embedded credentials (`http://username:password@ip:port/path`)
- **Master PIN Protection**: Require Master PIN verification for all camera settings
- **Secure Storage**: Store camera passwords in Keychain, config in UserDefaults
- **Error Handling**: Provide user-friendly error messages with retry options
- **Auto-refresh**: Force web view reload on configuration changes using UUID keys

## Git Operations and Commit Control
- **NEVER commit or push changes without explicit user approval**
- **ALWAYS ask the user before running `git add`, `git commit`, or `git push`**
- **When changes are complete, ask: "Would you like me to commit and push these changes?"**
- **Only suggest commit messages, don't execute them automatically**
- **Let the user review changes before any Git operations**
- **If user says "commit and push" or similar, then proceed with Git operations**

Remember: Always check for compilation errors before considering a task complete!
