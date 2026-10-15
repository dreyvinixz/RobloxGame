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

Referências: https://create.roblox.com/docs/studio/mcp e https://rojo.space/docs/v7/
