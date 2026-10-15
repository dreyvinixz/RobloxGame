# FL-005 — Auditoria de barreira de concreto

**Data:** 2026-10-15 · **Estado do candidato:** QUARANTINED · **Revisor:** Codex

## Procedência e acesso

- **Nome/tipo:** Jersey Barrier / Model
- **Criador exibido pelo Creator Store:** `TheRoyal_Archer`
- **Asset ID:** `2661884104`
- **Origem:** Roblox Creator Store — https://create.roblox.com/store/asset/2661884104
- **Preço observado na busca do Studio:** gratuito (`isFree: true`, 0 cents).
- **Descrição observada:** “Basic concrete barrier for cover or detail.”
- **Termos:** a documentação do Roblox Creator Store descreve assets do catálogo como feitos para outros usarem no desenvolvimento de experiências Roblox; assets grátis são disponibilizados a todos os criadores. Continuam aplicáveis os Termos de Uso e as diretrizes de IP do Roblox. A busca do Studio não exibiu licença independente, autoria da geometria ou direitos fora do ecossistema Roblox; isso não é inferido neste relatório.
- **Referências oficiais:** [Creator Store](https://create.roblox.com/docs/production/creator-store), [vulnerabilidades em assets de terceiros](https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities).

## Isolamento e inspeção no Studio

- Estado do Studio: Edit.
- Importado via MCP como `ServerStorage.FL005_Quarantine_JerseyBarrier`.
- Não foi inserido em `Workspace`, na cena final ou iniciado em Play.
- Estrutura reportada: um `Folder` com quatro `BasePart` descendentes: dois `Part` e dois `WedgePart`.
- Todos os quatro estavam `Anchored=true`, `CanCollide=true`, `CanQuery=true` e `CanTouch=true`.
- Dimensões reportadas (studs): `8 × 2.89 × 1`, `8.00001 × 0.52 × 2.13`, `8 × 1 × 2`, `8.00001 × 0.51 × 2.13`.
- Nenhum `Script`, `LocalScript`, `ModuleScript`, `MeshPart`, `MeshId`, `TextureID` ou referência externa foi reportado na árvore inspecionada. Nenhum código do asset foi executado.

## Colisão e triagem de desempenho

- **Colisão estrutural:** propriedades `CanCollide=true` em todas as partes; isto confirma a configuração, não um contato físico testado durante gameplay. A forma/cobertura balística e a colisão efetiva ainda precisam de playtest antes de usar a barreira no mapa.
- **Triagem de custo:** quatro peças ancoradas, sem MeshParts, texturas ou scripts; estrutura pequena e estática, com baixa complexidade aparente. Esta é evidência estrutural, não medição de FPS, memória, custo de física ou draw calls. Nenhum número de desempenho foi medido ou inventado.
- **Próximo gate:** testar contato/oclusão em sessão isolada; colher benchmark em hardware-alvo quando a etapa de performance S2 estiver disponível. Até lá, manter o candidato em quarentena e fora do mapa final.

## Decisão

Importação, procedência disponível, isolamento e inspeção de scripts foram validados como primeira amostra do pipeline. O item permanece **QUARANTINED**; não está aprovado para integrar a arena porque colisão em runtime e benchmark ainda não foram medidos.
