# Ambiente e check de ferramentas

## Pré-requisitos no Windows
- Roblox Studio atualizado e logado em conta de desenvolvimento.
- Codex CLI ou outro cliente MCP; autenticação configurada pelo próprio usuário.
- Git + Python 3.11+ + GitHub CLI (`gh`) + Rojo v7 + plugin Rojo no Studio.
- Editor VS Code opcional com Luau LSP; StyLua/Selene são opcionais até o fechamento da FL-006.

## Primeiro smoke test
1. Abra um lugar vazio no Studio; salve uma cópia de segurança.
2. Em Assistant → Manage MCP Servers, habilite o MCP; conecte Codex via Quick Connect.
3. No Codex, solicite `get_studio_state`, `search_game_tree` e execução de `print('frontline-mcp-ok')` via `execute_luau` no contexto de Edit. **Não inventar êxito:** salve output e hora.
4. No terminal dentro do repo, execute `rojo serve` e conecte Studio ao plugin. Veja `ReplicatedStorage/Shared/Config`, `ServerScriptService/GameServer/Bootstrap`, `StarterPlayer/StarterPlayerScripts/GameClient/Bootstrap`.
5. Execute Play e Stop via MCP; leia `get_console_output`, confirme mensagens de bootstrap.
6. Anexe capturas/logs à issue FL-002 e FL-003; anote versões usadas.

## Diagnóstico
- `codex mcp list`: conferir conexão registrada (o nome pode variar).
- Se o Studio não aparecer, reinicie o cliente MCP após configuração.
- Se scripts sumirem, desconecte Rojo e compare paths com default.project.json; não sobrescreva lugar sem backup.
- Se comandos MCP não existirem, consulte docs oficiais e registre alternativa na issue FL-003.

## Validação local — 2026-10-14
- Roblox Studio MCP: sessão `Place1` encontrada em Edit mode; `list_roblox_studios` e `get_studio_state` responderam.
- Rojo CLI 7.7.1 instalado pelo release oficial para Windows x86_64; SHA-256 conferido contra o digest do release.
- Plugin Rojo instalado em `%LOCALAPPDATA%\Roblox\Plugins`.
- `rojo build default.project.json -o <arquivo temporário>`: build concluído.
- `rojo serve default.project.json`: servidor ativo em `localhost:34872`; Studio conectado em Edit mode.
- Árvore confirmada via MCP: `ReplicatedStorage.Shared.Config` (ModuleScript), `ServerScriptService.GameServer.Bootstrap` (Script) e `StarterPlayer.StarterPlayerScripts.GameClient.Bootstrap` (LocalScript).
- Hot sync comprovado no commit `652a59a8908b84ac297b6b85757e78bad52d6978`: o comentário de mapeamento do módulo Config foi lido no Studio após o commit.
- MCP Play/Stop: `Place1` iniciou em Edit, executou Play e retornou a Edit; console confirmou `[Frontline][server] bootstrap ok | Project Frontline` e `[Frontline][client] bootstrap ok | Project Frontline`.
- Tentativa de `print('frontline-mcp-ok')` no MCP foi bloqueada pelo cliente: a ferramenta exige aprovação, mas a política desta execução é `never`; nenhum Luau foi executado por essa tentativa.
- Durante o smoke test, Studio/CorePackages emitiu avisos repetidos `FoundationProvider not found`; não houve erro nos bootstraps do projeto. Revisar esses avisos na issue FL-003 se persistirem em novo teste.

## Repositório GitHub — 2026-10-15
- `dreyvinixz/RobloxGame` é público; Issues habilitadas; issues `[FL-001]` a `[FL-032]` e milestones S0–S4 publicadas.
- Proteção de `main` ativa e conferida via GitHub CLI: PR obrigatório, check `verify-planning` obrigatório e estrito, resolução de conversas obrigatória, admins incluídos, force-push e exclusão desativados.
- Aprovações obrigatórias: 0, para não impedir merge neste projeto solo; revisão de PR continua sendo a convenção de contribuição.

Referências: https://create.roblox.com/docs/studio/mcp e https://rojo.space/docs/v7/
