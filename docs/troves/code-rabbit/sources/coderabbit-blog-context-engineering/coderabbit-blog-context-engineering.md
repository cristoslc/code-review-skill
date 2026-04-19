---
id: coderabbit-blog-context-engineering
url: https://www.coderabbit.ai/blog/context-engineering-ai-code-reviews
fetched: 2026-04-19
type: web
---

# Context Engineering: Level up your AI Code Reviews

## Key Points
- **Context Engineering**: CodeRabbit's approach to providing the most context-rich code reviews in the industry. While other tools settle for "codebase awareness," CodeRabbit pulls in dozens of data points to deliver accurate and helpful reviews.
- **1:1 Code-to-Context Ratio**: CodeRabbit packs a 1:1 ratio of code-to-context in its LLM prompts, ensuring that the AI has just the right amount of information to catch bugs without being overwhelmed.
- **Path-Based Instructions**: Custom review instructions that only apply to files matching a provided glob pattern. Both path filters and instructions are highly deterministic and activate when the pattern matches.
- **Exclusion/Inclusion**: Provide a file path as a glob pattern to exclude files from review or use an inverse glob pattern to include only specific files.

## How It Works
- **Data Collection**: CodeRabbit gathers extensive context from your codebase, including:
  - Code changes
  - Ticketing systems
  - Wikis
  - Other relevant data sources
- **Deterministic Matching**: Path-based instructions and filters are deterministic, ensuring consistent application of custom rules.

## Benefits
- **Accuracy**: More context leads to more accurate reviews, catching more bugs and providing relevant suggestions.
- **Relevance**: Reviews are tailored to your codebase and team conventions.
- **Trust**: Deterministic matching and high context ratios build trust in the AI's feedback.