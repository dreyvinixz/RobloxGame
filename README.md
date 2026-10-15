# Project Frontline — Roblox tactical FPS (projeto independente)

> **Status:** planejamento e scaffold v0.1.0 · **Tipo:** projeto independente de FPS militar no Roblox · **Não afiliado à EA, Battlefield ou Roblox Corporation.**

**Visão:** criar FPS multiplayer militar com referências de ritmo, balística e cenários de Battlefield 6, mas com modelos e código de procedência autorizada. **Sem modelagem manual obrigatória:** Creator Store + geração 3D autorizada + assets licenciados. Não há promessa de integrar diretamente os executáveis Roblox/BF6.

## Fonte da verdade
- Produto e limites: [docs/PRD.md](docs/PRD.md)
- Arquitetura: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Roadmap: [ROADMAP.md](ROADMAP.md)
- Backlog canônico: [planning/backlog.json](planning/backlog.json) (32 issues; versões .md e .csv geradas)
- Sprints: [planning/sprints](planning/sprints)
- Acordo de trabalho para IA: [.agents/AGENTS.md](.agents/AGENTS.md)
- Critérios QA: [docs/TEST_PLAN.md](docs/TEST_PLAN.md)
- Proveniência e segurança: [docs/ASSET_PIPELINE.md](docs/ASSET_PIPELINE.md)

## Primeiro início no Windows
1. Instale Git, Python 3.11+, Roblox Studio, Codex, GitHub CLI (`gh`) e Rojo v7. 
2. Clone o repositório existente e entre na pasta:

```powershell
git clone https://github.com/dreyvinixz/RobloxGame.git
cd RobloxGame
```

3. Abra um lugar local no Studio e habilite **Assistant → Manage MCP Servers → Enable Studio as MCP server**; conecte o Codex pelo Quick Connect (FL-003).
4. Confirme `rojo --version`, execute `rojo serve` nesta pasta e conecte o plugin Rojo ao Studio (FL-002).
5. Rode `python scripts/validate_project.py` e `python -m unittest discover -s tests -v`.

O repositório GitHub é [dreyvinixz/RobloxGame](https://github.com/dreyvinixz/RobloxGame). As [32 issues](https://github.com/dreyvinixz/RobloxGame/issues) e milestones S0–S4 já estão publicadas. Para importar novas entradas do backlog, autentique `gh`, revise primeiro com `python scripts/publish_issues.py --repo dreyvinixz/RobloxGame --dry-run` e use `--apply` somente para publicar. O importador não publica a experiência Roblox.

## Regras operacionais
- Sempre trabalhar a partir de uma `FL-xxx` com escopo claro; uma issue por PR, salvo justificativa.
- `main` protegida; branch `feat/FL-010-rifle`, `fix/FL-xxx-*` ou `docs/FL-xxx-*`.
- Rojo/Git mantém scripts como fonte da verdade. MCP no Studio é usado para testes e assets; mudanças em scripts via Studio devem ser reconciliadas e commitadas.
- Qualquer importação de modelo é isolada, auditada e registrada em `assets/registry.csv` **antes** de entrar na cena final.
- IA **não** faz compras, publicação externa ou inclusão de assets sem licença sem aprovação explícita.

## Estado atual
Inclui documentação, planejamento, templates, scripts mínimos de bootstrap e verificador de consistência. **Não é um jogo jogável ainda.** O primeiro loop combatível é a meta da Sprint 1.

## Referências oficiais
- Roblox MCP: https://create.roblox.com/docs/studio/mcp
- Rojo: https://rojo.space/docs/v7/
- Roblox segurança de assets: https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities
- Roblox IP: https://create.roblox.com/docs/production/publishing/ip-guidelines
