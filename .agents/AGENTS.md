# Instruções para agentes de IA — Project Frontline

> A missão do agente é implementar pequenas issues reprodutíveis, não gerar um jogo inteiro de uma só vez.

## Ordem obrigatória ao iniciar trabalho
1. Leia `README.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/ASSET_PIPELINE.md`, `docs/TEST_PLAN.md`.
2. Leia `planning/backlog.json` e o arquivo da issue em `planning/issues/FL-xxx.md`. Respeite dependências e gates.
3. Explique o plano da **issue selecionada** (arquivos afetados, ações no Studio, testes e riscos) antes de modificar o projeto.
4. Trabalhe em branch vinculada à issue; limite o diff. Não crie novos sistemas fora do escopo.
5. Teste estaticamente sempre; para afirmar que algo funciona no jogo, execute playtest no Roblox Studio e registre evidência (console/print/video).
6. Atualize docs, asset registry e status; abra PR com `Closes #NUMERO` após issue estar publicada no GitHub.

## Rojo + MCP: prevenção de conflito
- **Fonte dos scripts:** `src/` via Git/Rojo. Use MCP para inspecionar Studio, criar/posicionar assets, controlar playtest e coletar logs.
- Se usar MCP para escrever código Luau no Studio, exporte/reconcilie a alteração com `src/` antes de concluir; nunca aceite dois estados concorrentes sem diff.
- Não presuma que o MCP está conectado; inspecione `get_studio_state` e árvores com `search_game_tree` quando disponíveis.
- Não use `execute_luau` em modo Play sem verificar o datamodel e o efeito esperado; evite scripts destrutivos.

## Segurança e ativos
- Sem exportar, descompactar ou copiar assets originais de Battlefield 6 sem autorização específica.
- Sem contornar anticheat, DRM, autenticação, fazer memory injection em jogos online ou operar jogos de terceiros em produção.
- Modelos Creator Store podem ter backdoors. Isolar, auditar scripts e dependências (`require(assetId)`, `loadstring`, acesso a HTTP, remotes e DataStore), remover scripts dispensáveis.
- Registrar em `assets/registry.csv` URL/ID/autor/direitos/revisão antes de mover da quarentena.
- Não comprar assets nem publicar experiências sem confirmação explícita do usuário.

## Padrões de implementação
- Cliente: entrada, câmera, UI, FX; servidor: regras, HP, danos, cadência, estados e equipes.
- Validar todas as requisições do cliente, throttling/rate limit e alcance.
- ModuleScripts compartilhados são contratos puros/dados; sem segredos no ReplicatedStorage.
- Código organizado por domínio (weapons, gameplay, vehicles), nomes descritivos, sem dependências novas por conveniência.
- Não marcar issue `DONE` baseada apenas em lint/CI se exigir playtest.

## Entrega de cada issue
**Resumo:** o quê/por quê. **Evidência:** comando + logs + Studio. **Verificação:** critérios de aceite. **Riscos:** limitações. **PR:** escopo estrito.
