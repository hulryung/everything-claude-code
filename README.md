# Everything Claude Code (Multi-Language Fork)

> **Fork of [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)**
>
> Original by [@affaanmustafa](https://x.com/affaanmustafa) - Anthropic hackathon winner

**The complete collection of Claude Code configs, now with multi-language support!**

This fork extends the original repository with:
- **Language-agnostic core patterns** - Universal coding standards that work with any language
- **10 language-specific skills** - TypeScript, Python, Go, Rust, Java/Kotlin, C#, Ruby, PHP, Swift, C/C++
- **Multi-language hooks** - Auto-formatting and linting for all supported languages
- **Interactive install script** - Easy installation with language selection

---

## Read the Full Guide First

**Before diving into these configs, read the complete guide on X:**


<img width="592" height="445" alt="image" src="https://github.com/user-attachments/assets/1a471488-59cc-425b-8345-5245c7efbcef" />


**[The Shorthand Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2012378465664745795)**



The guide explains:
- What each config type does and when to use it
- How to structure your Claude Code setup
- Context window management (critical for performance)
- Parallel workflows and advanced techniques
- The philosophy behind these configs

**This repo is configs only! Tips, tricks and more examples are in my X articles and videos (links will be appended to this readme as it evolves).**

---

## Quick Start

### Option 1: Install Script (Recommended)

```bash
# Clone this fork
git clone https://github.com/hulryung/everything-claude-code.git
cd everything-claude-code

# Run interactive installer
./install.sh
```

**Install Script Options:**

| Command | Description |
|---------|-------------|
| `./install.sh` | Interactive installer with language selection |
| `./install.sh --full` | Full installation + language selection |
| `./install.sh --core` | Core only (language-agnostic patterns) |
| `./install.sh -l python go rust` | Install with specific languages |
| `./install.sh --uninstall` | Remove installed configurations |
| `./install.sh --help` | Show all options |

### Option 2: Manual Installation

```bash
# Clone this fork
git clone https://github.com/hulryung/everything-claude-code.git

# Copy agents to your Claude config
cp everything-claude-code/agents/*.md ~/.claude/agents/

# Copy rules
cp everything-claude-code/rules/*.md ~/.claude/rules/

# Copy commands
cp everything-claude-code/commands/*.md ~/.claude/commands/

# Copy skills (universal patterns)
cp everything-claude-code/skills/*.md ~/.claude/skills/

# Copy language-specific skills (choose what you need)
mkdir -p ~/.claude/skills/languages
cp everything-claude-code/skills/languages/python.md ~/.claude/skills/languages/
cp everything-claude-code/skills/languages/typescript.md ~/.claude/skills/languages/
```

### Configure Hooks

Copy the hooks from `hooks/hooks.json` to your `~/.claude/settings.json`.

### Configure MCPs

Copy desired MCP servers from `mcp-configs/mcp-servers.json` to your `~/.claude.json`.

**Important:** Replace `YOUR_*_HERE` placeholders with your actual API keys.

---

## Supported Languages

### Language-Specific Skills

| Language | File | Frameworks/Tools |
|----------|------|------------------|
| TypeScript/JavaScript | `typescript.md` | React, Next.js, Node.js, Zod |
| Python | `python.md` | FastAPI, Django, Pydantic |
| Go | `go.md` | Standard library, Goroutines |
| Rust | `rust.md` | Axum, Tokio, async/await |
| Java/Kotlin | `java.md` | Spring Boot, JPA, Coroutines |
| C#/.NET | `csharp.md` | ASP.NET Core, EF Core, LINQ |
| Ruby | `ruby.md` | Rails, RSpec, Service Objects |
| PHP | `php.md` | Laravel, Symfony, Pest |
| Swift | `swift.md` | SwiftUI, iOS/macOS, Actors |
| C/C++ | `cpp.md` | Modern C++20/23, STL, RAII |

### Hooks Support

Auto-formatting and linting hooks support all languages above, detecting:
- Debug statements (console.log, print, fmt.Print, etc.)
- Code formatting (Prettier, Black, gofmt, rustfmt, etc.)
- Type checking (TypeScript, mypy, go vet, cargo check)

---

## What's Inside

```
everything-claude-code/
├── install.sh           # Interactive installer script
│
├── agents/              # Specialized subagents for delegation
│   ├── planner.md              # Feature implementation planning
│   ├── architect.md            # System design decisions
│   ├── tdd-guide.md            # Test-driven development
│   ├── code-reviewer.md        # Quality and security review
│   ├── security-reviewer.md    # Vulnerability analysis
│   ├── build-error-resolver.md
│   ├── e2e-runner.md           # Playwright E2E testing
│   ├── refactor-cleaner.md     # Dead code cleanup
│   └── doc-updater.md          # Documentation sync
│
├── skills/              # Workflow definitions and domain knowledge
│   ├── coding-standards.md     # Universal coding principles
│   ├── backend-patterns.md     # Language-agnostic API patterns
│   ├── frontend-patterns.md    # Language-agnostic UI patterns
│   ├── languages/              # Language-specific patterns
│   │   ├── typescript.md
│   │   ├── python.md
│   │   ├── go.md
│   │   ├── rust.md
│   │   ├── java.md
│   │   ├── csharp.md
│   │   ├── ruby.md
│   │   ├── php.md
│   │   ├── swift.md
│   │   └── cpp.md
│   ├── tdd-workflow/           # TDD methodology
│   └── security-review/        # Security checklist
│
├── commands/            # Slash commands for quick execution
│   ├── tdd.md                  # /tdd - Test-driven development
│   ├── plan.md                 # /plan - Implementation planning
│   ├── e2e.md                  # /e2e - E2E test generation
│   ├── code-review.md          # /code-review - Quality review
│   ├── build-fix.md            # /build-fix - Fix build errors
│   ├── refactor-clean.md       # /refactor-clean - Dead code removal
│   ├── test-coverage.md        # /test-coverage - Coverage analysis
│   ├── update-codemaps.md      # /update-codemaps - Refresh docs
│   └── update-docs.md          # /update-docs - Sync documentation
│
├── rules/               # Always-follow guidelines (language-agnostic)
│   ├── security.md             # Mandatory security checks
│   ├── coding-style.md         # Immutability, file organization
│   ├── testing.md              # TDD, 80% coverage requirement
│   ├── git-workflow.md         # Commit format, PR process
│   ├── agents.md               # When to delegate to subagents
│   ├── performance.md          # Model selection, context management
│   ├── patterns.md             # API response formats, hooks
│   └── hooks.md                # Hook documentation
│
├── hooks/               # Trigger-based automations (multi-language)
│   └── hooks.json              # PreToolUse, PostToolUse, Stop hooks
│
├── mcp-configs/         # MCP server configurations
│   └── mcp-servers.json        # GitHub, Supabase, Vercel, Railway, etc.
│
├── plugins/             # Plugin ecosystem documentation
│   └── README.md               # Plugins, marketplaces, skills guide
│
└── examples/            # Example configurations
    ├── CLAUDE.md               # Example project-level config
    ├── user-CLAUDE.md          # Example user-level config
    └── statusline.json         # Custom status line config
```

---

## Key Concepts

### Agents

Subagents handle delegated tasks with limited scope. Example:

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability
tools: Read, Grep, Glob, Bash
model: opus
---

You are a senior code reviewer...
```

### Skills

Skills are workflow definitions invoked by commands or agents:

```markdown
# TDD Workflow

1. Define interfaces first
2. Write failing tests (RED)
3. Implement minimal code (GREEN)
4. Refactor (IMPROVE)
5. Verify 80%+ coverage
```

Language-specific skills provide patterns for each language:

```markdown
# Python Patterns

## Async/Await
async def fetch_all_data():
    users, products = await asyncio.gather(
        fetch_users(),
        fetch_products()
    )
    return users, products
```

### Hooks

Hooks fire on tool events. Multi-language support for formatting and linting:

```json
{
  "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(py)$\"",
  "hooks": [{
    "type": "command",
    "command": "black -q \"$file_path\" && mypy \"$file_path\""
  }]
}
```

### Rules

Rules are always-follow guidelines. Keep them modular:

```
~/.claude/rules/
  security.md      # No hardcoded secrets
  coding-style.md  # Immutability, file limits
  testing.md       # TDD, coverage requirements
```

---

## Installation Directory Structure

After installation, your `~/.claude/` directory will look like:

```
~/.claude/
├── agents/              # Specialized subagents
├── commands/            # Slash commands
├── skills/              # Universal patterns
│   └── languages/       # Language-specific patterns (selected)
├── rules/               # Mandatory guidelines
├── CLAUDE.md            # User-level config
├── settings.json        # Hooks configuration
└── mcp-servers.example.json  # MCP reference file
```

---

## Contributing

**Contributions are welcome and encouraged.**

This repo is meant to be a community resource. If you have:
- Useful agents or skills
- Clever hooks
- Better MCP configurations
- Improved rules
- **Language-specific patterns** (new languages welcome!)

Please contribute! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ideas for Contributions

- Additional language skills (Scala, Elixir, Haskell, etc.)
- Framework-specific configs (Django, Rails, Laravel)
- DevOps agents (Kubernetes, Terraform, AWS)
- Testing strategies (different frameworks)
- Domain-specific knowledge (ML, data engineering, mobile)

---

## Background

### Original Repository

The original configs were created by [@affaanmustafa](https://x.com/affaanmustafa), who won the Anthropic x Forum Ventures hackathon in Sep 2025 building [zenith.chat](https://zenith.chat) with [@DRodriguezFX](https://x.com/DRodriguezFX) - entirely using Claude Code.

### This Fork

This fork extends the original with multi-language support, making the configs usable across different technology stacks. Key modifications:

| Change | Description |
|--------|-------------|
| Language-agnostic patterns | Core skills rewritten to be universal |
| Language-specific skills | Added patterns for 10 languages |
| Multi-language hooks | Auto-format/lint hooks for all languages |
| Install script | Interactive installer with language selection |

---

## Important Notes

### Context Window Management

**Critical:** Don't enable all MCPs at once. Your 200k context window can shrink to 70k with too many tools enabled.

Rule of thumb:
- Have 20-30 MCPs configured
- Keep under 10 enabled per project
- Under 80 tools active

Use `disabledMcpServers` in project config to disable unused ones.

### Customization

These configs work for my workflow. You should:
1. Start with what resonates
2. Modify for your stack
3. Remove what you don't use
4. Add your own patterns

### Language Selection

Not all developers need all languages. Use the install script to select only what you need:

```bash
# Install only Python and Go
./install.sh -l python go

# Install core patterns without language-specific skills
./install.sh --core
```

---

## Links

### Original Author
- **Full Guide:** [The Shorthand Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2012378465664745795)
- **Original Repo:** [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- **Follow:** [@affaanmustafa](https://x.com/affaanmustafa)
- **zenith.chat:** [zenith.chat](https://zenith.chat)

### This Fork
- **Fork Repo:** [hulryung/everything-claude-code](https://github.com/hulryung/everything-claude-code)

---

## License

MIT - Use freely, modify as needed, contribute back if you can.

---

**Star this repo if it helps. Read the guide. Build something great.**
