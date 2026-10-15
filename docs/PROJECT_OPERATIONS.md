# Operação e gestão

## Cadência proposta
Sprints de 2 semanas, planejamento no primeiro dia, revisão + retrospectiva no último. Sessões diárias curtas opcionais com registro do que mudou, próximo passo e bloqueios. Capacidade inicial não presumida: ajustar story points após S0.

## Fluxo issue → PR
Backlog → Ready → In Progress (WIP máximo 2) → Review → QA → Done.
- Ready: Definition of Ready satisfeita e sem dependências abertas.
- In Progress: branch criada.
- Review: PR aberto e CI.
- QA: playtest e evidências concluídos; correções abertas como bugs.
- Done: aceite humano + merge.

## Estimativa
Story points Fibonacci simplificado (1,2,3,5,8); representam esforço relativo, não horas. Replanejar issues grandes antes de começar; não usar velocidade até ter histórico.

## Cerimônias
Planning: escolher issues P0 desbloqueadas. Daily curta: feito, próximo, impedimentos. Review: executar demo e checar critérios. Retro: 1 melhoria no próximo sprint.

## Riscos
Roblox MCP muda; assets maliciosos; direitos de uso; performance de assets ultra-detalhados; multiplayer server authority. Dono de cada risco e plano de mitigação devem constar nas issues.
