# Installing the Nice HMS skills

Pick your tool. Nothing is uploaded anywhere — the skills read files on your machine.

---

## Claude Code

Skills are read from `.claude/skills/` **inside the folder you open**. So:

1. Clone this repo once:
   ```
   git clone https://github.com/umeshramya/nice-hms-skills.git
   ```
2. Copy the skills into the folder you actually work in — the unpacked monthly pack, or any
   project folder:

   **Windows (PowerShell)**
   ```
   Copy-Item -Recurse nice-hms-skills\skills <your-folder>\.claude\skills
   ```
   **Windows (cmd)**
   ```
   xcopy nice-hms-skills\skills <your-folder>\.claude\skills /E /I /Y
   ```
   **macOS / Linux**
   ```
   mkdir -p <your-folder>/.claude/skills && cp -R nice-hms-skills/skills/* <your-folder>/.claude/skills/
   ```
3. Open that folder and run `claude`.

> Already opened the monthly pack? It ships its own `.claude/skills/` — you may not need this repo
> at all. Copy these skills only for the extras (research paper, presentation).

---

## OpenAI Codex

Codex reads **`AGENTS.md`** in the folder it runs in, so no copy is needed:

```
git clone https://github.com/umeshramya/nice-hms-skills.git
cd nice-hms-skills
codex
```

To use them against your monthly pack instead, copy `AGENTS.md` from this repo into the unpacked
pack folder and run `codex` there.

---

## Gemini CLI

Gemini reads **`GEMINI.md`**, which this repo points at `AGENTS.md`:

```
git clone https://github.com/umeshramya/nice-hms-skills.git
cd nice-hms-skills
gemini
```

---

## Cursor, VS Code Copilot, and any other AGENTS.md tool

Open the repo (or the unpacked pack) as your workspace. These tools pick up `AGENTS.md`
automatically.

---

## Any other tool (DeepSeek, OpenRouter, a web chat)

There is no install. Open `AGENTS.md`, paste it as the system prompt (or into the chat first),
then ask your question. Keep the pack folder open so you can paste a file's contents when the
agent asks for it.

---

## What "installed" means

A skill only loads when your question matches its description. You do not have to call it by
name — ask *"where are we losing money?"* and the leakage skill is the one that answers.

To check it worked, ask: **"What can you tell me from this pack?"** The agent should describe the
files it can see, not make up figures.
