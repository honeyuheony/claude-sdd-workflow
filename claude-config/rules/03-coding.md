# Coding Conventions (Python)

## Core
- Formatter: Black/Ruff | Linter: Ruff/Flake8
- Type hints: required
- Naming: `snake_case` (functions/vars), `PascalCase` (classes), `UPPER_SNAKE_CASE` (constants)

## Documentation
- Comments: explain WHY (not WHAT)
- Docstrings: complex functions only

## Error Handling
- Use specific exceptions (UserNotFoundError, ValidationError, etc.)
- Convert to HTTP exceptions at API layer

## Testing
- Pattern: `test_<what>_<condition>_<expected_result>`
- Structure: Arrange -> Act -> Assert

## Code Quality
- One function = one responsibility
- Minimize side effects, prefer pure functions
- YAGNI -- simplest solution; add complexity only when needed
