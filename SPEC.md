# AI4JVM Site Specification

AI4JVM is a curated guide to the Java AI ecosystem — a single-page website covering agent frameworks, inference engines, code assistants, key people, and learning resources.

## Site Structure

- Single `index.html` file (HTML + inline CSS, no build step)
- Dark theme with card-based layout
- Sticky nav, hero section, then content sections separated by dividers
- Responsive: cards collapse to single column on mobile

## Visual Design

- Dark background (`#0f1117`), card surfaces (`#1e2230`), accent purple (`#6c63ff`), accent blue (`#38bdf8`), accent pink (`#f472b6`)
- Cards have hover effects (border highlight, slight lift)
- Badge types: `badge-framework` (purple), `badge-inference` (blue), `badge-assistant` (pink), `badge-resource` (green)
- People shown with avatar initials in gradient circles

## Hero

- Title: "Java meets **Artificial Intelligence**" (gradient text on "Artificial Intelligence")
- Subtitle: "Your curated guide to the Java AI ecosystem — agent frameworks, inference engines, code assistants, key people, and the best learning resources."

---

## News

Latest headlines about the Java AI ecosystem. Each item has a link and brief description.

| Headline | URL | Description |
|----------|-----|-------------|
| Spring AI 2.0.0-M1 | https://spring.io/blog/2025/12/11/spring-ai-2-0-0-M1-available-now/ | Built on Spring Boot 4.0 & Spring Framework 7.0 |
| Google ADK for Java | https://developers.googleblog.com/adk-for-java-opening-up-to-third-party-language-models-via-langchain4j-integration/ | Adds LangChain4j integration for third-party model support |
| LangChain4j | https://docs.langchain4j.dev/ | Crosses 11k GitHub stars; agentic modules now first-class |
| GPULlama3.java | https://www.infoq.com/news/2025/06/gpullama3-java-gpu-llm/ | GPU-accelerated LLM inference in pure Java via TornadoVM |
| Inside.java | https://inside.java/2026/02/01/devoxxbelgium-production-langchain4j/ | Production-ready LangChain4j at Devoxx Belgium |

---

## Agent Frameworks

Build AI agents, orchestrate multi-step workflows, and integrate LLMs into production Java applications.

### Spring AI
- **Badge:** Framework
- **Description:** The Spring ecosystem's official AI framework. Portable abstractions across 20+ model providers, tool calling, RAG, chat memory, vector stores, and MCP support. Built by the Spring team at Broadcom.
- **Links:** [Docs](https://spring.io/projects/spring-ai/) · [GitHub](https://github.com/spring-projects/spring-ai) · [Overview](https://spring.io/ai/)

### LangChain4j
- **Badge:** Framework
- **Description:** The most popular Java LLM library. Unified API across 20+ LLM providers and 30+ embedding stores. Three levels of abstraction from low-level prompts to high-level AI Services. Supports RAG, tool calling, MCP, and agents.
- **Links:** [Docs](https://docs.langchain4j.dev/) · [GitHub](https://github.com/langchain4j/langchain4j)

### Google ADK for Java
- **Badge:** Framework
- **Description:** Google's Agent Development Kit — code-first Java toolkit for building, evaluating, and deploying AI agents. Supports Gemini natively plus third-party models via LangChain4j integration. A2A protocol for agent-to-agent communication.
- **Links:** [Docs](https://google.github.io/adk-docs/get-started/java/) · [GitHub](https://github.com/google/adk-java) · [Codelab](https://codelabs.developers.google.com/adk-java-getting-started)

### Quarkus LangChain4j
- **Badge:** Framework
- **Description:** Enterprise-grade Quarkus extension for LangChain4j. Native compilation with GraalVM, built-in observability (metrics, tracing, auditing), and Dev UI tooling. Maintained by Red Hat & IBM.
- **Links:** [Docs](https://docs.quarkiverse.io/quarkus-langchain4j/dev/index.html) · [GitHub](https://github.com/quarkiverse/quarkus-langchain4j)

### LangGraph4j
- **Badge:** Framework
- **Description:** Build stateful, multi-agent applications with cyclical graphs. Inspired by Python's LangGraph, works with both LangChain4j and Spring AI. Persistent checkpoints, deep agent architectures, and a Studio web UI.
- **Links:** [Docs](https://langgraph4j.github.io/langgraph4j/) · [GitHub](https://github.com/langgraph4j/langgraph4j)

### Embabel
- **Badge:** Framework
- **Description:** Created by Rod Johnson (Spring Framework creator). JVM agent framework using Goal-Oriented Action Planning (GOAP) for dynamic replanning. Strongly typed, Spring-integrated, MCP support. Written in Kotlin with full Java interop.
- **Links:** [GitHub](https://github.com/embabel/embabel-agent) · [Blog](https://medium.com/@springrod/embabel-a-new-agent-platform-for-the-jvm-1c83402e0014)

### Koog (JetBrains)
- **Badge:** Framework
- **Description:** Kotlin-native agent framework from JetBrains. Type-safe DSL, multiplatform (JVM, JS, WasmJS, Android, iOS), A2A protocol support, fault tolerance with persistence, and multi-LLM support.
- **Links:** [Website](https://www.jetbrains.com/koog/) · [GitHub](https://github.com/JetBrains/koog) · [Docs](https://docs.koog.ai/)

### Semantic Kernel (Java)
- **Badge:** Framework
- **Description:** Microsoft's AI orchestration SDK with Java support. Merged with AutoGen into a unified Microsoft Agent Framework with deep Azure integration. Supports prompt chaining, planning, and memory.
- **Links:** [GitHub](https://github.com/microsoft/semantic-kernel-java)

### MCP Java SDK
- **Badge:** SDK
- **Description:** The official Java SDK for Model Context Protocol servers and clients. Co-maintained by the Spring AI team and Anthropic. Sync/async, STDIO/SSE/Streamable HTTP transports, OAuth support.
- **Links:** [Docs](https://modelcontextprotocol.io/sdk/java/mcp-overview) · [GitHub](https://github.com/modelcontextprotocol/java-sdk)

### Anthropic Java SDK
- **Badge:** SDK
- **Description:** Official Java SDK for the Claude Messages API. Streaming, retries, structured outputs, extended thinking, code execution, and files API. Build Java apps powered by Claude.
- **Links:** [GitHub](https://github.com/anthropics/anthropic-sdk-java)

---

## Java with Code Assistants

Technologies that supercharge Java development when paired with AI code assistants — from MCP servers that give agents live Javadoc access, to reusable skill packages and IDE integrations.

**Section focus:** Prioritize tools that bridge the gap between AI assistants and the Java ecosystem — MCP servers, skill registries, IDE plugins, and context providers — over general-purpose AI tools.

### Javadocs.dev MCP Server
- **Badge:** MCP Server
- **Description:** Gives AI assistants live access to Java, Kotlin, and Scala library documentation from Maven Central. Six tools including latest-version lookup, Javadoc symbol browsing, and source file retrieval. Connect any MCP client via Streamable HTTP.
- **Links:** [Connect (MCP)](https://www.javadocs.dev/mcp) · [Docker MCP](https://hub.docker.com/mcp/server/javadocs/overview) · [GitHub](https://github.com/jamesward/javadoccentral)

### SkillsJars
- **Badge:** Skills
- **Description:** A packaging format and registry for distributing reusable AI agent skills as Maven/Gradle JARs. Skills are Markdown files (`SKILL.md`) under `META-INF/skills/` that teach AI agents domain-specific patterns. Discover and load skills on demand in Claude Code, Kiro, and Spring AI apps.
- **Links:** [Registry](https://www.skillsjars.com/) · [Agent Utils](https://github.com/spring-ai-community/spring-ai-agent-utils) · [Testing Skills](https://github.com/spring-ai-community/spring-testing-skills)

### Claude Code
- **Badge:** Assistant
- **Description:** Anthropic's agentic coding tool, right in your terminal. Understands entire codebases, makes multi-file changes, runs tests, and iterates. Java's strict type system catches AI mistakes at compile time, making it an ideal pairing. Supports MCP servers and SkillsJars for extended Java context.
- **Links:** [Docs](https://code.claude.com/docs/en/overview)

### GitHub Copilot
- **Badge:** Assistant
- **Description:** Inline code completions and chat powered by LLMs. Excellent Java support in VS Code and JetBrains IDEs. Understands Spring Boot patterns, JPA entities, and Stream API fluently. Agent mode for multi-step tasks with MCP server support.
- **Links:** [Website](https://github.com/features/copilot)

### JetBrains AI Assistant
- **Badge:** Assistant
- **Description:** Deeply integrated into IntelliJ IDEA, the most popular Java IDE. Context-aware completions that understand your project structure, refactoring suggestions, test generation, and commit message writing.
- **Links:** [Website](https://www.jetbrains.com/ai/)

### Amazon Q Developer
- **Badge:** Assistant
- **Description:** AWS's AI coding companion with deep Java and AWS expertise. Excels at generating AWS SDK code, Lambda handlers, CDK constructs, and Spring Boot integrations with AWS services.
- **Links:** [Website](https://aws.amazon.com/q/developer/)

---

## Inference & Training

Run models, train classifiers, and do ML inference directly on the JVM — no Python required.

### Jlama
- **Badge:** Inference
- **Description:** Modern LLM inference engine written in pure Java. Runs Llama, Gemma, Mistral, and more locally on CPU. Uses Java's Vector API (Project Panama) for SIMD-accelerated matrix math. Supports GGUF and SafeTensors formats, quantized models, and distributed inference.
- **Links:** [GitHub](https://github.com/tjake/Jlama) · [Tutorial](https://www.baeldung.com/java-jlama-llm)

### Deep Java Library (DJL)
- **Badge:** Inference
- **Description:** AWS's high-level, engine-agnostic deep learning framework. Supports PyTorch, TensorFlow, and MXNet backends. Used in production at Netflix and Amazon for real-time inference. DJLServing provides high-performance model serving.
- **Links:** [GitHub](https://github.com/deepjavalibrary/djl) · [InfoQ](https://www.infoq.com/articles/java-machine-learning-djl/)

### ONNX Runtime Java
- **Badge:** Inference
- **Description:** Run transformer and classical ML models directly on the JVM. Hardware acceleration via CUDA, ROCm, DirectML, and more. Enables deploying scikit-learn, PyTorch, and HuggingFace models in Java without Python or REST wrappers.
- **Links:** [Docs](https://onnxruntime.ai/docs/get-started/with-java.html) · [InfoQ Guide](https://www.infoq.com/articles/onnx-ai-inference-with-java/)

### Tribuo
- **Badge:** Training
- **Description:** Oracle Labs' ML library for classification, regression, clustering, and anomaly detection. Strong typing, provenance tracking for reproducibility, and integrations with XGBoost, ONNX Runtime, TensorFlow, and LibSVM.
- **Links:** [Website](https://tribuo.org/) · [GitHub](https://github.com/oracle/tribuo)

### GPULlama3.java
- **Badge:** Inference
- **Description:** First Java-native Llama 3 implementation with automatic GPU acceleration via TornadoVM. No CUDA or native code needed — GPU-accelerated LLM inference in pure Java. From the University of Manchester's Beehive Lab.
- **Links:** [InfoQ](https://www.infoq.com/news/2025/06/gpullama3-java-gpu-llm/)

### TensorFlow Java
- **Badge:** Training
- **Description:** Official Java bindings for TensorFlow. Train and deploy TF models entirely in Java. Used by Tribuo under the hood. Suitable for teams that want to stay within the JVM ecosystem while using TensorFlow's model formats.
- **Links:** [Docs](https://www.tensorflow.org/jvm) · [GitHub](https://github.com/tensorflow/java)

---

## People to Follow

Key voices at the intersection of Java and AI.

| Name | Initials | Role | Links |
|------|----------|------|-------|
| James Ward | JW | Developer Advocate — Java, Kotlin, Cloud, AI | [@_JamesWard](https://twitter.com/_jamesward) · [Blog](https://jamesward.com) |
| Josh Long | JL | Spring Developer Advocate, Spring AI talks | [@starbuxman](https://twitter.com/starbuxman) · [Spring Blog](https://spring.io/authors/joshlong/) |
| Craig Walls | CW | Author of *Spring AI in Action* | [@habuma](https://twitter.com/habuma) |
| Lize Raes | LR | LangChain4j core team, Oracle, conference speaker | [@LizeRaes](https://twitter.com/LizeRaes) |
| Mark Sailes | MS | AWS Developer Advocate — Java & Serverless | [@MarkSailes3](https://twitter.com/MarkSailes3) |
| Dan Vega | DV | Spring Developer Advocate, YouTube educator | [@therealdanvega](https://twitter.com/therealdanvega) · [Blog](https://www.danvega.dev/) |
| Dmytro Liubarskyi | DL | Creator of LangChain4j | [GitHub](https://github.com/langchain4j) |
| Mark Pollack | MP | Spring AI project lead | [@markpollack](https://twitter.com/markpollack) |
| Cédric Champeau | CC | Gradle engineer, Java performance & AI | [@CedricChampeau](https://twitter.com/CedricChampeau) |
| Bartosz Sorrentino | BS | LangGraph4j creator | [GitHub](https://github.com/langgraph4j) |
| Guillaume Laforge | GL | Google Developer Advocate — Java, Groovy, AI | [@glaforge](https://twitter.com/glaforge) · [Blog](https://glaforge.dev/) |
| Rod Johnson | RJ | Creator of Spring Framework, CEO of Embabel | [@springrod](https://twitter.com/springrod) · [Blog](https://medium.com/@springrod) |
| Dmitry Vinnik | DV | Engineering Manager (AI/ML) at Meta | [@DmitryVinnik](https://twitter.com/DmitryVinnik) · [Blog](https://dvinnik.dev/) |
| T. Jake Luciani | TK | Creator of Jlama — Java LLM inference | [GitHub](https://github.com/tjake) |

---

## Learning Resources

Videos, blogs, tutorials, and conferences to level up your Java AI skills.

### Videos & Talks

| Title | URL | Description |
|-------|-----|-------------|
| Spring Developer YouTube | https://www.youtube.com/@SpringSourceDev | Josh Long's Spring AI deep dives, Boot tutorials, and weekly tips |
| Production LangChain4j — Inside.java | https://inside.java/2026/02/01/devoxxbelgium-production-langchain4j/ | Advanced RAG, agentic workflows, and production tips from Devoxx Belgium |
| Inside Java YouTube | https://www.youtube.com/@java | Oracle's official Java channel — JEP deep dives, Vector API, and more |
| Google ADK Java Codelab | https://codelabs.developers.google.com/adk-java-getting-started | Hands-on: build AI agents in Java with Google's ADK |
| Devoxx YouTube | https://www.youtube.com/@DevoxxForever | Thousands of conference talks on Java, AI, cloud, and architecture |
| James Ward's Presentations | https://jamesward.com/presos/ | Talks on Java, Kotlin, cloud-native, and AI topics |
| Coffee + Software with Josh Long | https://youtube.com/@coffeesoftware | Spring ecosystem, AI integration, and Java community |
| Foojay Podcast: Java AI Revolution | https://foojay.io/today/foojay-podcast-86/ | Agents, MCP, graph databases — developers navigate the AI revolution |

### Blogs & Tutorials

| Title | URL | Description |
|-------|-----|-------------|
| Foojay.io | https://foojay.io/ | Friends of OpenJDK — Java AI webinars, podcasts, and guides |
| Inside.java | https://inside.java/ | Oracle's hub for Java news, JEPs, and AI ecosystem evolution |
| Spring Blog | https://spring.io/blog/ | Official Spring AI updates, tutorials, and release notes |
| InfoQ Java | https://www.infoq.com/java/ | In-depth articles on ONNX inference, DJL, and enterprise Java AI |
| Baeldung — Spring AI | https://www.baeldung.com/spring-ai | Practical tutorials on Spring AI, Jlama, Tribuo, and more |
| JavaPro: LangChain4j Hands-On | https://javapro.io/2025/04/23/build-ai-apps-and-agents-in-java-hands-on-with-langchain4j/ | Step-by-step guide to building AI apps and agents in Java |
| ADK for Java Getting Started | https://glaforge.dev/posts/2025/05/20/writing-java-ai-agents-with-adk-for-java-getting-started/ | Guillaume Laforge's walkthrough of Google's ADK for Java |

### Conferences

| Name | URL | Description |
|------|-----|-------------|
| Devoxx | https://www.devoxx.com/ | Belgium, UK, France, Morocco — Europe's premier Java conference series |
| Spring I/O 2026 | https://2026.springio.net/ | April 13–15, Barcelona — two days of Spring awesomeness |
| Devnexus | https://devnexus.com/ | Atlanta — the largest Java conference in North America |
| Jfokus | https://www.jfokus.se/ | Stockholm — leading Scandinavian developer conference |
| QCon | https://qconferences.com/ | San Francisco, London, Shanghai — senior engineer focused |
| JNation | https://jnation.pt/ | Coimbra, Portugal — growing Java and developer community |
| JavaOne 2026 | https://dev.java/community/javaone-2026/ | March 17–19, Redwood City — Oracle's flagship Java conference returns |
| Java Conferences Tracker | https://javaconferences.org/ | Community-maintained calendar of all Java conferences worldwide |

### Community & Repos

| Title | URL | Description |
|-------|-----|-------------|
| Awesome Spring AI | https://github.com/spring-ai-community/awesome-spring-ai | Curated list of Spring AI resources, tools, and tutorials |
| Google ADK Samples | https://github.com/google/adk-samples | Sample agents for Java, Python, TypeScript, and Go |
| Evolution of Java for AI | https://inside.java/2025/01/29/evolution-of-java-ecosystem-for-integrating-ai/ | Inside.java overview of how the Java ecosystem is evolving for AI |
| Quarkus + Jlama | https://quarkus.io/blog/quarkus-jlama/ | Pure Java LLM-infused app with Quarkus, LangChain4j, and Jlama |
| LangChain4j Courses | https://www.classcentral.com/subject/langchain4j | 60+ online courses on Class Central |
| Spring AI in Action (Manning) | https://www.manning.com/books/spring-ai-in-action | Book by Craig Walls — comprehensive guide to building AI apps with Spring |
| Making Java a First-Class AI Citizen | https://www.javaadvent.com/2025/12/making-java-a-first-class-ai-citizen-with-langchain4j.html | JVM Advent 2025 — deep dive into LangChain4j's role in the ecosystem |
| Java Relevance in the AI Era | https://redmonk.com/jgovernor/java-relevance-in-the-ai-era-agent-frameworks-emerge/ | RedMonk analysis of Java's position as agent frameworks emerge |

---

## Footer

"AI4JVM — Curating the Java AI ecosystem. Contributions welcome on [GitHub](https://github.com/jamesward/ai4jvm)."
