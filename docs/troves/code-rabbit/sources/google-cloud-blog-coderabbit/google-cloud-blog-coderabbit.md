---
id: google-cloud-blog-coderabbit
url: https://cloud.google.com/blog/products/ai-machine-learning/how-coderabbit-built-its-ai-code-review-agent-with-google-cloud-run
fetched: 2026-04-19
type: web
---

# How CodeRabbit built its AI code review agent with Google Cloud Run

## Key Points
- **Architecture**: CodeRabbit uses Google Cloud Run as the foundation for its AI code review agent.
- **Sandboxing**: All Cloud Run instances are sandboxed with two layers of sandboxing and can be configured with minimal IAM permissions via dedicated service identity. Uses Cloud Run's second-generation execution environment (microVM with full Linux cgroup functionality).
- **Workflow**: 
  1. Incoming webhook events (from GitHub, GitLab, etc.) are handled by a lightweight Cloud Run service that performs billing and subscription checks.
  2. The AI agent assesses the impact of code changes on the entire codebase, not just the changed files.
  3. AI-generated scripts (using tools like `cat`, `grep`, and `ast-grep`) navigate the code, search for patterns, and extract relevant information.
- **Integration**: CodeRabbit integrates directly with platforms like GitHub and GitLab, providing automated code reviews triggered by pull requests.

## Technical Details
- **AI-Generated Scripts**: The AI agent creates shell scripts to analyze code and extract information, enabling dynamic, context-aware reviews.
- **Security**: Sandboxing and minimal IAM permissions ensure secure execution of AI-generated scripts.
- **Scalability**: Cloud Run provides a scalable, serverless environment for handling webhook events and running AI reviews.