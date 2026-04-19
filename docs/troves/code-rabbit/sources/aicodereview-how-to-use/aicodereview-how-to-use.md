---
id: aicodereview-how-to-use
url: https://aicodereview.cc/blog/how-to-use-coderabbit/
fetched: 2026-04-19
type: web
---

# How to Use CodeRabbit for Automated Pull Request Reviews

## Key Points
- **AI-Powered Review**: CodeRabbit catches logic errors, design issues, and contextual problems that rule-based tools miss.
- **Deterministic Tools**: Static analysis tools like SonarQube and Semgrep provide deterministic bug detection, security scanning, and quality gate enforcement that AI review cannot replace.
- **Complementary Use**: CodeRabbit works well alongside static analysis tools. CodeRabbit provides AI-powered semantic review, while static analysis tools provide deterministic rule-based scanning.
- **Setup**: CodeRabbit integrates directly with GitHub, GitLab, and other platforms. Setup involves:
  1. Authenticating with your platform.
  2. Authorizing CodeRabbit.
  3. Selecting repositories to enable.
  4. Configuring `.coderabbit.yaml`.
- **Workflow**: CodeRabbit reviews are triggered by pull requests and assess the impact of changes on the entire codebase.

## Best Practice
Use CodeRabbit for AI-powered semantic review and static analysis tools (SonarQube, Semgrep, DeepSource) for deterministic rule-based scanning.