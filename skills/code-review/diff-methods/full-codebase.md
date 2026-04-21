# Full Codebase Review Method

## Purpose

Review the entire codebase (or a subset) without requiring a git diff. Agents receive complete file contents instead of change hunks. Use this when the user asks for a general review, health check, or audit of the codebase rather than reviewing specific changes.

## When to Use This Method

The orchestrator should select `full-codebase` as the `diff_method` when:

- The user says "review the codebase" or "review this project" (no refs mentioned).
- The user provides a directory path or glob pattern instead of git refs.
- The `--full` flag is passed.
- There are no git refs to diff (e.g., fresh repo with no commits).

## Argument Resolution

| User Input | Resolution |
|------------|------------|
| `--full` | Review all tracked source files. |
| `--full src/` | Review files under `src/` only. |
| `--full "**/*.py"` | Review files matching the glob. |
| `--full --agents security` | Full review with only security agent. |
| (no refs, no staged changes) | Fall back to full-codebase automatically. |

## File Discovery

### All tracked source files

```bash
git ls-files
```

### Files under a specific path

```bash
git ls-files -- <path>
```

### Files matching a glob

```bash
git ls-files -- <glob-pattern>
```

### Exclude non-source files

Filter out binary, generated, and dependency files. Apply these exclusion rules:

1. Skip directories: `node_modules/`, `vendor/`, `.venv/`, `__pycache__/`, `dist/`, `build/`, `target/`, `.git/`.
2. Skip generated files: `*.lock`, `*.min.js`, `*.min.css`, `*.bundle.js`, `package-lock.json`, `yarn.lock`, `go.sum`, `Cargo.lock`.
3. Skip binary files: `*.png`, `*.jpg`, `*.gif`, `*.ico`, `*.woff`, `*.ttf`, `*.eot`, `*.pdf`, `*.zip`, `*.tar.gz`.
4. Skip large data files: `*.csv`, `*.json` (unless clearly source), `*.sql`, `*.db`.

### Build the file list

```bash
git ls-files | grep -v -E '(node_modules/|vendor/|\.venv/|__pycache__/|dist/|build/|target/|\.lock$|\.min\.|package-lock|yarn\.lock|go\.sum|Cargo\.lock|\.png$|\.jpg$|\.gif$|\.ico$|\.woff|\.ttf|\.eot|\.pdf$|\.zip$|\.tar\.gz$|\.csv$|\.db$)' > /tmp/codereview_file_list.txt
wc -l /tmp/codereview_file_list.txt
```

## Size Check

Full codebase reviews can be very large. Apply limits:

```bash
FILE_COUNT=$(wc -l < /tmp/codereview_file_list.txt)
TOTAL_LINES=$(xargs wc -l < /tmp/codereview_file_list.txt | tail -1 | awk '{print $1}')
```

Decision rules:

- **< 3000 total lines**: Send all files to each agent as a single batch.
- **3000–10000 total lines**: Chunk files into batches of ~2500 lines. Each agent reviews every chunk (process chunks sequentially per agent). Every line of code must be reviewed by every specialization.
- **> 10000 total lines**: Sample-based review. Select the most important files:
  1. Entry points (`main.*`, `index.*`, `app.*`, `mod.*`).
  2. Files with the most recent changes (`git log --format="" --name-only -20 | sort | uniq -c | sort -rn | head -20`).
  3. Configuration and security-adjacent files.
  Every agent reviews the same sampled files. Warn the user that the codebase exceeds review capacity and only a sample will be reviewed.

**Critical: every line of code must be reviewed by every active specialization.** Never divide files by agent type. Chunking is a batching strategy only — each agent processes all chunks.

## File Content Acquisition

For each file in the list, read via the Read tool (not Bash) so content enters context directly:

```
Read each file from /tmp/codereview_file_list.txt
```

### Batch files into chunks

If total lines exceed 3000, group files into chunks of ~2500 lines each:

```bash
# Split file list into chunks of ~2500 total lines
awk 'BEGIN{c=0; f=0} {print > sprintf("/tmp/codereview_chunk_%03d.txt", f); c+=1; if(c>=50){c=0; f+=1}}' /tmp/codereview_file_list.txt
```

Each chunk file contains a list of file paths. The orchestrator reads each listed file via the Read tool and sends the combined content to agents. **Each agent reviews every chunk** — do not assign chunks to specific agents.

## Adapted Agent Instructions

When using `full-codebase`, the orchestrator must prefix each agent dispatch with this note:

> You are reviewing complete source files, not a diff. Report issues found anywhere in the provided files. Focus on the most impactful problems — do not exhaustively list minor style issues across the entire codebase. Prioritize correctness and security over style in a full-review context.

## Output

File contents are read via the Read tool (not Bash) to enter agent context. The file list is stored at `/tmp/codereview_file_list.txt`.