# Contributing to Project Touchline

Thank you for your interest in making Football Manager more accessible! We welcome contributions from everyone.

## How to Contribute

### Reporting Issues
- Use the GitHub issue tracker to report bugs
- Describe the issue clearly with steps to reproduce
- Include your operating system and Python version
- Mention if you're using a screen reader (NVDA, JAWS, etc.)

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

## Development Guidelines

### Code Style
- Follow PEP 8 Python style guidelines
- Use clear, descriptive variable names
- Add docstrings to all functions and classes
- Include type hints where appropriate

### Accessibility First
- All UI elements must be keyboard-accessible
- Provide clear, descriptive text for narration
- Test with screen readers when possible
- Consider users with different accessibility needs

### Testing
- Test all new features manually
- Verify keyboard navigation works correctly
- Check that narration is clear and helpful
- Ensure no regressions in existing features

### Documentation
- Update README.md for significant changes
- Document new hotkeys in hotkeys_config.json
- Add examples to sample_outputs.txt
- Update roadmap.txt for feature status

## Priority Areas for Contribution

### High Priority
- Testing with real screen readers (NVDA, JAWS)
- User experience feedback from blind gamers
- Bug fixes and stability improvements
- Documentation improvements

### Medium Priority
- Phase 2 features (player search, transfers, training)
- Performance optimizations
- Additional keyboard shortcuts
- Better error handling

### Future/Experimental
- Direct screen reader integration
- Audio cues and sound effects
- Voice command support
- Mobile companion app

## Getting Help

- Check existing documentation in README.md
- Look at sample code in screens/ directory
- Ask questions in GitHub Discussions
- Review sample_outputs.txt for expected behavior

## Community Guidelines

- Be respectful and inclusive
- Focus on accessibility and usability
- Help others learn and contribute
- Share knowledge and experience
- Celebrate diverse perspectives

## Testing with Screen Readers

If you have access to NVDA or JAWS:
1. Run the demo: `python main.py --demo`
2. Test individual screens
3. Report any issues with screen reader compatibility
4. Suggest improvements for better screen reader support

## Recognition

Contributors will be acknowledged in:
- Project README.md
- Release notes
- Special thanks in major releases

Thank you for helping make gaming more accessible! 🎮
