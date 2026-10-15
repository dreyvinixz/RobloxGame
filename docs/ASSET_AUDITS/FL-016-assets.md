# FL-016 — auditoria inicial de assets de mapa

**Data:** 2026-10-15 · **Branch:** `dev` · **Destino de inspeção:** `ServerStorage.FL016_Quarantine` no Roblox Studio Edit.

## Escopo

Os dois mapas Creator Store indicados pelo responsável foram importados somente para a quarentena. Nenhum script foi executado e nenhum mapa de terceiros foi movido para a arena. A sandbox do importador foi aplicada; em seguida, os `BaseScript` encontrados foram explicitamente desativados. A cópia `Workspace.FL013_TestArena` tinha o atributo `TemporaryTestCopy=true` e 10.476 descendentes; foi movida inteira para `ServerStorage.FL016_Quarantine`, preservando seus dados fora do mapa ativo. A prévia temporária `Workspace.FL016_TemporaryAssetPreview` também foi removida.

## Resultados

| Asset | Evidência observada no Studio | Decisão |
|---|---|---|
| [WW2 Map (959903202)](https://create.roblox.com/store/asset/959903202/WW2-Map), Nick01001 | 9.816 descendentes, incluindo 15 scripts. Scripts estão desativados, mas o código-fonte não ficou legível para auditoria. A inspeção de nomes não localizou terreno, grama, montanha ou prédio isolável que resolva a necessidade atual. | Manter pacote em quarentena; rejeitar uso integral. Não aprovar filhos sem inspeção individual legível e sem scripts. |
| [Military Map (8741869283)](https://create.roblox.com/store/asset/8741869283/Military-Map), WhiteShadowSAO | 32.814 descendentes: 523 MeshParts, 12.782 Parts, 1.800 unions, 1.265 Models, 47 Sounds e 100 scripts (79 Script + 21 LocalScript). Scripts desativados. Um script de portão usa `require` dinâmico ofuscado que resolve para o asset `628338147`; não foi executado. O filho `Sim Map` tem 424 MeshParts ancoradas/colidíveis e nenhum script/remotes/som, mas é um anel quadrado de rochas verdes, com centro vazio. Variantes de pinheiro sem script ainda não passaram por inspeção visual individual. | Manter pacote em quarentena; rejeitar uso integral. `Sim Map` não atende terreno de arena. Não aprovar árvores ou outros filhos sem inspeção isolada de geometria, dependências e origem. |

## Direção para a arena

O pacote completo de nenhum dos dois mapas está aprovado. Esses resultados não fornecem um asset adequado de terreno/grama/montanhas. A cópia da arena de teste saiu do `Workspace`, mas a `ArenaBuilder` atual ainda cria terreno, ruas, prédios e barreiras com Parts em código; essa implementação precisa ser substituída por composição de assets aprovados antes de remover o caminho atual, para não deixar a partida sem arena.

## Pendências

- Auditar candidatos de uso único para terreno/grama, relevo e estruturas destruídas; candidatos adicionais só serão importados após consentimento específico.
- Promover apenas cópias/filhos que passem inspeção de scripts, remotes, dependências, permissões, escala, colisão e desempenho.
- Atualizar `ArenaBuilder` e revisar a arena no Studio quando houver assets aprovados.
- A branch `dev` não contém, neste registro, prova de gameplay/Playtest ou benchmark de runtime.
