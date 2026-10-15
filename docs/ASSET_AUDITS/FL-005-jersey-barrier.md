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

- **Colisão estrutural:** propriedades `CanCollide=true` e `CollisionGroup=Default` nas quatro partes; isto confirma a configuração, não um contato físico testado durante gameplay.
- **Resultado de teste relatado pelo proprietário (2026-10-15):** leitura isolada de 60 FPS; personagem pareceu atravessar/passar pela barreira. Não foi feita comparação com/sem asset nas mesmas condições.
- **Diagnóstico de posicionamento:** no Studio, a baseplate está com superfície superior em Y=0 e a barreira em ServerStorage tinha seu ponto mais baixo aproximadamente em Y=12.17. Um teste com o asset nesse posicionamento pode deixar o personagem passar por baixo, sem indicar falha de `CanCollide`. A barreira não estava em Workspace no momento da inspeção, então não foi possível confirmar onde estava durante o teste relatado.
- **Triagem de custo:** quatro peças ancoradas, sem MeshParts, texturas ou scripts; estrutura pequena e estática, com baixa complexidade aparente. Uma leitura de 60 FPS, sem linha de base e possivelmente limitada pelo teto de frames, não mede impacto de FPS, memória, física ou draw calls.
- **Próximo gate:** em teste temporário, mover o conjunto cerca de 12.2 studs para baixo até a base encostar na baseplate e repetir o contato. Comparar desempenho com e sem o asset, sob as mesmas condições. Até lá, manter o candidato em quarentena e fora do mapa final.

## Decisão

Importação, procedência disponível, isolamento e inspeção de scripts foram validados como primeira amostra do pipeline. O item permanece **QUARANTINED**; não está aprovado para integrar a arena porque colisão em runtime e benchmark ainda não foram medidos.
