# AI4JVM

Single-page website (`index.html`) — HTML + inline CSS, no build step.

## Spec

`SPEC.md` is the source of truth for all site content and structure. When updating the site:

1. Update `SPEC.md` first with the new content, links, and descriptions
2. Then update `index.html` to match the spec

## Style Rules

- Keep descriptions concise (2-3 sentences) and factual
- Cards use badge classes: `badge-framework`, `badge-inference`, `badge-assistant`, `badge-resource`
- Each card has a title, description, and links (Docs, GitHub, Website, etc.)
- The "Java with Code Assistants" section prioritizes tools that bridge AI assistants and the Java ecosystem (MCP servers, skill registries, IDE plugins, context providers) over general-purpose AI tools
