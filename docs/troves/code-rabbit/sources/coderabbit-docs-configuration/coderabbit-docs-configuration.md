---
id: coderabbit-docs-configuration
url: https://docs.coderabbit.ai/reference/configuration
fetched: 2026-04-19
type: web
---

# CodeRabbit Documentation - Configuration

## Key Features
- **Instructions**: Define deterministic pass/fail criteria (max 10,000 characters).
- **Custom Pre-merge Checks**: Define up to 5 custom checks that must pass before merging. Each check requires:
  - Unique name (≤50 chars)
  - Deterministic instructions (≤10,000 chars)
- **OpenGrep**: High-performance static code analysis engine, compatible with Semgrep configurations. Enabled by default for finding security vulnerabilities and bugs across 17+ languages.

## Configuration Fields
| Field               | Description                                                                                     | Default |
|--------------------|-------------------------------------------------------------------------------------------------|---------|
| Instructions       | Deterministic pass/fail criteria for code reviews.                                             | ""     |
| Custom Pre-merge Checks | Up to 5 custom checks with unique names and deterministic instructions.                        | []      |
| Enable OpenGrep    | Toggle for OpenGrep, a static code analysis engine for security vulnerabilities and bugs.       | {}      |

## Use Cases
- **Deterministic Checks**: Ensure code meets specific criteria before merging (e.g., no `print` statements, all functions documented).
- **Security Scanning**: Use OpenGrep to enforce security rules and catch vulnerabilities.
- **Custom Workflows**: Tailor CodeRabbit to your team's specific requirements and conventions.