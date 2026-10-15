# Project Frontline — Roblox tactical FPS (projeto independente)

> **Status:** planejamento e scaffold v0.1.0 · **Tipo:** projeto independente de FPS militar no Roblox · **Não afiliado à EA, Battlefield ou Roblox Corporation.**

**Visão:** criar FPS multiplayer militar com referências de ritmo, balística e cenários de Battlefield 6, mas com modelos e código de procedência autorizada. **Sem modelagem manual obrigatória:** Creator Store + geração 3D autorizada + assets licenciados. Não há promessa de integrar diretamente os executáveis Roblox/BF6.

## Fonte da verdade
- Produto e limites: [docs/PRD.md](docs/PRD.md)
- Arquitetura: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Roadmap: [ROADMAP.md](ROADMAP.md)
- Backlog canônico: [planning/backlog.json](planning/backlog.json) (32 issues; versões .md e .csv geradas)
- Sprints: [planning/sprints](planning/sprints)
- Acordo de trabalho para IA: [AGENTS.md](AGENTS.md)
- Critérios QA: [docs/TEST_PLAN.md](docs/TEST_PLAN.md)
- Proveniência e segurança: [docs/ASSET_PIPELINE.md](docs/ASSET_PIPELINE.md)

## Primeiro início no Windows
1. Instale Git, Python 3.11+, Roblox Studio, Codex, GitHub CLI (`gh`) e Rojo v7. 
2. Abra o Studio e habilite **Assistant → Manage MCP Servers → Enable Studio as MCP server**; conecte Codex por Quick Connect e valide a conexão (FL-003).
3. Confirme `rojo --version`, execute `rojo serve` nesta pasta e conecte o plugin Rojo ao Studio com um lugar vazio; preserve objetos visuais criados via Studio (FL-002).
4. Rode `python scripts/validate_project.py` e `python -m unittest discover -s tests -v`.
5. Para criar **seu** repositório privado (não criado automaticamente neste pacote):

```powershell
git init -b main
git add .
git commit -m "chore: bootstrap Project Frontline"
gh auth login
gh repo create dreyvinixz/project-frontline-roblox --private --source . --remote origin --push
python scripts/publish_issues.py --repo dreyvinixz/project-frontline-roblox --dry-run
python scripts/publish_issues.py --repo dreyvinixz/project-frontline-roblox --apply
```

O importador cria labels, milestones e issues sem duplicar títulos existentes. `--dry-run` é obrigatório como primeiro teste recomendado. **Não publica experiências no Roblox.**

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
