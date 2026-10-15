# Sistema de planejamento

`backlog.json` é a fonte canônica de 32 issues, com IDs fixos, sprints, dependências, prioridades, critérios de aceite e pontos. `backlog.csv` e `issues/*.md` são representações para revisão/importação e devem permanecer consistentes.

- `S0`...`S4`: cinco sprints sugeridas com milestones e exit gates.
- `LATER`: pesquisa ou incrementos futuros, sem data nem compromisso de execução.
- Importador `scripts/publish_issues.py` usa `gh` autenticado e, com `--apply`, cria labels, milestones e issues no repo informado; idempotência por título exato. Revise antes de executar.

Ao alterar IDs ou dependências, execute `scripts/validate_project.py`. A criação de Issues no GitHub **não** é feita automaticamente ao descompactar.
