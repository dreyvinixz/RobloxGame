# Contribuindo

## Fluxo
1. Escolha uma `FL-xxx` em `planning/backlog.json` e confira dependências.
2. Crie branch `feat/FL-xxx-resumo` (ou `fix/`, `docs/`).
3. Execute `python scripts/validate_project.py` e `python -m unittest discover -s tests -v`.
4. Se alterou gameplay, faça playtest real no Studio e anexe logs/capturas ao PR.
5. PR pequeno, revisão e merge em `main`; nunca commitar diretamente em `main` quando branch protection estiver ativada.

## Definition of Ready
Issue possui objetivo, escopo, critérios de aceite, dependências, forma de teste e estimativa. Não iniciar tarefa bloqueada.

## Definition of Done
Critérios verificáveis atendidos; evidência disponível; sem erros críticos no console; ativos revisados/licenciados; documentação ajustada; CI verde; PR revisado; merge efetuado.

## Convenções
Commits: Conventional Commits, por exemplo `feat(weapons): FL-010 add rifle raycasts`. Scripts `.luau` formatados com StyLua quando instalado; lint Selene quando configurado em FL-006. Revisar logs de playtest, nunca inventá-los.

## Board
Sugestão GitHub Projects: Backlog → Ready → In Progress (WIP ≤2) → Review → QA → Done. Milestones S0–S4. Etiquetas têm prefixo `type:`, `area:`, `priority:`, `sprint:`; status visual do Board deve refletir o PR.
