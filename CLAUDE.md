# AI4JVM - Project Guidelines

## About

AI4JVM is a curated guide to the Java AI ecosystem — a single-page website (`index.html`) covering agent frameworks, inference engines, code assistants, key people, and learning resources.

## Code Assistants Section Focus

The "Java with Code Assistants" section emphasizes **technologies that enhance Java development when used alongside AI code assistants**, not just the assistants themselves. This includes:

- **MCP servers** that give AI agents access to Java-specific context (e.g., javadocs.dev for live Javadoc browsing)
- **SkillsJars** — reusable skill packages (Maven/Gradle JARs containing `SKILL.md` files) that teach AI agents Java patterns and best practices
- **AI coding assistants** with strong Java support (Claude Code, GitHub Copilot, JetBrains AI, Amazon Q)

When adding new entries to this section, prioritize tools and technologies that bridge the gap between AI assistants and the Java ecosystem — MCP servers, skill registries, IDE plugins, and context providers — over general-purpose AI tools.

## Structure

- `index.html` — the entire site (HTML + CSS, no build step)
- Sections: News, Agent Frameworks, Code Assistants, Inference & Training, People, Resources
- Dark theme with card-based layout

## Style

- Cards use badge classes: `badge-framework`, `badge-inference`, `badge-assistant`, `badge-resource`
- Each card has a title, description, and links (Docs, GitHub, Website, etc.)
- Keep descriptions concise (2-3 sentences) and factual
