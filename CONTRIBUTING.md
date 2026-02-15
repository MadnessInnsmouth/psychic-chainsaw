# Contributing to Touchline

Thank you for your interest in making Football Manager more accessible! We welcome contributions from everyone.

## How to Contribute

### Reporting Issues
- Use the GitHub issue tracker to report bugs
- Describe the issue clearly with steps to reproduce
- Include your operating system, .NET SDK version, and FM26 version
- Mention if you're using a screen reader (NVDA, JAWS, etc.)
- Include relevant logs from `BepInEx/LogOutput.log`

### Suggesting Features
- Check existing issues to avoid duplicates
- Describe the accessibility problem the feature would solve
- Explain how it would help blind/visually impaired users

### Code Contributions
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (especially with screen readers if possible)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Setup

### Prerequisites
- .NET 6.0 SDK or later
- Football Manager 26 (for full builds)
- Visual Studio 2022, VS Code, or Rider (optional)
- BepInEx 6.x IL2CPP

### Building from Source
See [BUILDING.md](BUILDING.md) for complete build instructions. Quick start:

```bash
# Build without game installed (uses stubs)
dotnet build TouchlineMod.sln -c Release

# Build with game installed (full assemblies)
export FM26_PATH="/path/to/Football Manager 26"
dotnet build TouchlineMod.sln -c Release
```

## Development Guidelines

### Code Style
- Follow standard C# coding conventions
- Use clear, descriptive variable names
- Add XML documentation comments to public APIs
- Keep methods focused and single-purpose
- Use dependency injection where appropriate

### Project Structure
- `Core/` — Core functionality (speech, accessibility manager, text cleaning)
- `Navigation/` — Focus tracking and accessible element models
- `UI/` — UI scanning and text extraction from Unity components
- `Patches/` — Harmony patches for FM26 event hooks
- `Config/` — BepInEx configuration definitions

### Accessibility First
- All features must work with keyboard navigation
- Provide clear, descriptive announcements for screen readers
- Test with NVDA or JAWS when possible
- Consider users with different accessibility needs
- Avoid overwhelming users with too much information

### Testing
- Test all new features manually with the game
- Verify keyboard navigation works correctly
- Check that narration is clear and helpful
- Test with screen readers (NVDA or JAWS)
- Ensure no regressions in existing features
- Check BepInEx logs for errors or warnings

### BepInEx Best Practices
- Use `Logger.LogInfo/LogWarning/LogError` for logging
- Respect BepInEx configuration system
- Use Harmony patches sparingly and carefully
- Handle Unity IL2CPP types correctly (use Il2Cpp prefix)
- Test both with and without game installed

## Priority Areas for Contribution

### High Priority
- Testing with real screen readers (NVDA, JAWS)
- User experience feedback from blind gamers
- Bug fixes and stability improvements
- Documentation improvements
- Game version compatibility updates

### Medium Priority
- Enhanced navigation for specific screens (tactics, transfers, training)
- Performance optimizations
- Additional keyboard shortcuts
- Better error handling and recovery
- Configuration UI improvements

### Future/Experimental
- Audio cues and sound effects
- Braille display output via Tolk
- Custom voice profiles
- Multi-language support

## Getting Help

- Check existing documentation: [README.md](README.md), [BUILDING.md](BUILDING.md), [INSTALL.md](INSTALL.md)
- Review [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for architecture overview
- Look at existing code in `src/TouchlineMod/` for examples
- Ask questions in GitHub Discussions
- Check BepInEx documentation for plugin development

## Community Guidelines

- Be respectful and inclusive
- Focus on accessibility and usability
- Help others learn and contribute
- Share knowledge and experience
- Celebrate diverse perspectives

## Testing with Screen Readers

If you have access to NVDA or JAWS:
1. Build and install the mod following [BUILDING.md](BUILDING.md)
2. Launch FM26 with your screen reader running
3. Test navigation and features
4. Report any issues with screen reader compatibility
5. Suggest improvements for better screen reader support

## Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Include testing steps
- Update documentation if needed
- Ensure the build succeeds
- Keep changes focused and minimal

## Recognition

Contributors will be acknowledged in:
- Project README.md
- Release notes
- Special thanks in major releases

Thank you for helping make gaming more accessible! 🎮
