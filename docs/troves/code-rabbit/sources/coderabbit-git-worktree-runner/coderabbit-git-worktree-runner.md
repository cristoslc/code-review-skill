---
id: coderabbit-git-worktree-runner
url: https://github.com/coderabbitai/git-worktree-runner
fetched: 2026-04-19
type: github-repo
license: Apache-2.0
---

# Git Worktree Runner

## Overview
- **Purpose**: Bash-based Git worktree manager with editor and AI tool integration. Automates per-branch worktree creation, configuration copying, dependency installation, and workspace setup for efficient parallel development.
- **License**: Apache-2.0

## Key Features
- **Automated Worktree Creation**: Creates a new worktree for each branch, allowing parallel development without switching branches.
- **Configuration Copying**: Copies configuration files (e.g., `.env`, `.vscode/`) from the main worktree to the new branch worktree.
- **Dependency Installation**: Automatically installs dependencies (e.g., `npm install`, `bundle install`) in the new worktree.
- **Editor Integration**: Opens the new worktree in the user's preferred editor (e.g., VS Code, Vim).
- **AI Tool Integration**: Supports integration with AI coding tools for automated setup and configuration.

## Use Cases
- **Parallel Development**: Work on multiple branches simultaneously without context switching.
- **Isolated Environments**: Each branch has its own worktree, ensuring isolation and reducing conflicts.
- **Efficient Workflows**: Streamlines the process of setting up new branches for development or review.