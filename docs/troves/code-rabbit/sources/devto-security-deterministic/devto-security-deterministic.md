---
id: devto-security-deterministic
url: https://dev.to/rahulxsingh/coderabbit-security-how-ai-detects-vulnerabilities-1k8j
fetched: 2026-04-19
type: web
---

# CodeRabbit Security: How AI Detects Vulnerabilities

## Key Points
- **Workflow Control**: Setting `request_changes_workflow: true` makes CodeRabbit request changes on the PR (rather than just informational comments) when security issues are detected, preventing accidental merges.
- **Semgrep Integration**: Enabling Semgrep (available on the Pro plan) adds deterministic rule-based scanning alongside the AI analysis.
- **Complementary Tools**: CodeRabbit and Semgrep complement each other:
  - **Semgrep**: Performs full-repository static analysis with thousands of security rules, custom rule authoring, and deterministic enforcement.
  - **CodeRabbit**: Reviews only the PR diff with AI-powered contextual analysis, catching issues that SAST tools miss by understanding intent.
- **Trade-offs**: 
  - **Semgrep**: Deterministic, always fires on matching patterns (e.g., `shell=True`).
  - **CodeRabbit**: Probabilistic, may miss edge cases or flag safe code.
- **Best Practice**: Run both Semgrep and CodeRabbit for comprehensive coverage. Semgrep provides the deterministic safety net, while CodeRabbit catches contextual issues.

## Integration
- **Semgrep**: Can be enabled as an integrated tool in CodeRabbit's Pro plan, or run independently in CI pipelines.
- **Lower Overhead**: CodeRabbit works out of the box without writing or maintaining rules.