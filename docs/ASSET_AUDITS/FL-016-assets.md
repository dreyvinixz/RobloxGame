# FL-016 — auditoria inicial de assets de mapa

**Data:** 2026-10-15 · **Branch:** `dev` · **Destino de inspeção:** `ServerStorage.FL016_Quarantine` no Roblox Studio Edit.

## Escopo

Os dois mapas Creator Store indicados pelo responsável foram importados somente para a quarentena. Nenhum script foi executado e nenhum mapa de terceiros foi movido para a arena. A sandbox do importador foi aplicada; em seguida, os `BaseScript` encontrados foram explicitamente desativados. A cópia `Workspace.FL013_TestArena` tinha o atributo `TemporaryTestCopy=true` e 10.476 descendentes; foi movida inteira para `ServerStorage.FL016_Quarantine`, preservando seus dados fora do mapa ativo. A prévia temporária `Workspace.FL016_TemporaryAssetPreview` também foi removida.

## Resultados

| Asset | Evidência observada no Studio | Decisão |
|---|---|---|
| [WW2 Map (959903202)](https://create.roblox.com/store/asset/959903202/WW2-Map), Nick01001 | 9.816 descendentes, incluindo 15 scripts. Scripts estão desativados, mas o código-fonte não ficou legível para auditoria. Foi isolado o `Model.Baseplate`: um Part estático com material Grass, 512 × 99 × 455 studs, sem executáveis dentro do próprio Part. | Manter pacote em quarentena; rejeitar uso integral. A cópia isolada da base foi redimensionada para 2 studs de espessura apenas no rascunho visual temporário; não está aprovada para a arena final. |
| [Military Map (8741869283)](https://create.roblox.com/store/asset/8741869283/Military-Map), WhiteShadowSAO | 32.814 descendentes: 523 MeshParts, 12.782 Parts, 1.800 unions, 1.265 Models, 47 Sounds e 100 scripts (79 Script + 21 LocalScript). Scripts desativados. Um script de portão usa `require` dinâmico ofuscado que resolve para o asset `628338147`; não foi executado. O filho `Sim Map` tem 424 MeshParts ancoradas/colidíveis e nenhum script/remotes/som, mas é um anel quadrado de rochas verdes, com centro vazio. Variantes de pinheiro sem script ainda não passaram por inspeção visual individual. | Manter pacote em quarentena; rejeitar uso integral. `Sim Map` não atende terreno de arena. Não aprovar árvores ou outros filhos sem inspeção isolada de geometria, dependências e origem. |

## Candidatos adicionais importados após aprovação

Os quatro candidatos foram importados para `ServerStorage.FL016_Quarantine` e auditados sem execução. Os quatro possuem o mesmo conjunto inesperado de conteúdo sob um `SurfaceAppearance`/modelo visual: `Runtime` (Script), `ScreenBuilder` (LocalScript), `InputBindingPlatform` (RemoteFunction) e `DialogSound` (Sound). Ambos os scripts estão desativados. O `Runtime` tem lógica de interface que referencia `PlayerGui` e só continua no Studio; `ScreenBuilder` também retorna fora do Studio e cria uma janela/overlay. A varredura de texto encontrou `PlayerGui`/comportamento de UI, sem correspondências para `require`, `HttpService` ou `loadstring`. Nada foi executado.

| Asset | Resultado real no Studio | Decisão |
|---|---|---|
| [Desert Mountain Hill Terrain Rock Hills (128439311971079)](https://create.roblox.com/store/asset/128439311971079) | 411 descendentes, 1 MeshPart; cerca de 39,9 × 33,4 × 59,4 studs. | Pacote rejeitado como está; examinar apenas mesh isolado e sanitizado. |
| [Grass Field (100432787162169)](https://create.roblox.com/store/asset/100432787162169) | 853 descendentes, 144 MeshParts; cerca de 148,3 × 5,4 × 157,8 studs. | Pacote rejeitado como está; custo e scripts impedem aprovação. |
| [Destroyed Building (101776749239326)](https://create.roblox.com/store/asset/101776749239326) | 411 descendentes, 1 MeshPart; cerca de 45,0 × 97,8 × 116,9 studs. | Pacote rejeitado como está; examinar apenas mesh isolado e sanitizado. |
| [Low-Poly Pine Trees (121575291347417)](https://create.roblox.com/store/asset/121575291347417) | 440 descendentes, 20 MeshParts; cerca de 59,2 × 31,5 × 29,7 studs. | Pacote rejeitado como está; examinar apenas geometria isolada e sanitizada. |

Os anúncios dos quatro afirmavam ausência de scripts. O conteúdo observado diverge e os modelos completos continuam em quarentena. Registro detalhado em `assets/registry.csv`.

## Assets adicionais aprovados para auditoria

Em 2026-10-15, o responsável aprovou explicitamente estes três IDs para importação apenas em `ServerStorage.FL016_Quarantine`:

| Asset | Resultado real no Studio | Decisão |
|---|---|---|
| [Grass Mountain Realistic Stone Terrain (139207374657719)](https://create.roblox.com/store/asset/139207374657719), anúncio Creator Store atribuído à conta verificada “Roblox” | 3.385 descendentes, 590 Parts (2 MeshParts), 2 scripts, 1 RemoteFunction e 1 Sound; cerca de 113,6 × 51,1 × 135,7 studs. Scripts desativados. Source scan: `PlayerGui`/UI, sem `require`, `HttpService` ou `loadstring`. | Pacote completo não aprovado. O anúncio alegava “sem scripts”; manter isolado. |
| [Military Crates Ammo Resupply Box Base Mesh (119441430498737)](https://create.roblox.com/store/asset/119441430498737), anúncio Creator Store atribuído à conta verificada “Roblox” | 850 descendentes, 26 MeshParts, 4 scripts (dois pares repetidos), 2 RemoteFunctions e 2 Sounds; cerca de 6,3 × 4,5 × 12,7 studs. Scripts desativados. Source scan: `PlayerGui`/UI, sem `require`, `HttpService` ou `loadstring`. | Pacote completo não aprovado. O anúncio alegava “sem scripts”; manter isolado. |
| [Silver Firs / Grey Pines Realistic Trees Pack PBR (18475173887)](https://create.roblox.com/store/asset/18475173887), Letaij | 45 descendentes, 16 MeshParts, nenhum Script/LocalScript/ModuleScript, remoto ou som; cerca de 16,4 × 27,3 × 89,4 studs. O importador reportou `sandboxed=false`, sem scripts para sandboxar. | Candidato visual; verificar procedência das texturas, escala, colisão e desempenho. Não aprovado para o mapa ainda. |

Os dois primeiros repetem o pacote de interface oculto visto nos candidatos anteriores; nenhum foi executado. O pinheiro PBR está livre de executáveis, mas isso não confirma licença das texturas nem desempenho.

## Peças para ampliar a composição

Dentro do modelo Military Map já importado, encontrei filhos estáticos separados, sem scripts/remotes/sounds nos exemplares verificados: `Pine Tree` (65 Parts; caixa de 28,2 × 31,7 × 29,2 studs), `Tower` (165 Parts; 16,8 × 34,8 × 164,8 studs), `Military_Barrier` (5 Parts; 7,2 × 4 × 2,8 studs) e `Military Crates` (64 Parts; 8,4 × 6,6 × 8,4 studs). Outros filhos verificados também estão sem executáveis: `Large Tent` (198 Parts), `Military Canvas` (337 Parts), `Gate` (33), `Tall Barbed Wire Fence` (31), `Props` (60), `AmmoBox` (6), `BoxTarp` (2), `Crates` (3), `Pallet` (3) e `USMC Stretcher` (7). `Realistic clouds` tem uma caixa de mais de 600 studs de altura e foi excluído do preview.

O `Workspace.FL016_AssetAuditPreview` é temporário e contém clones visuais fora da arena. O subgrupo `Sanitized_CreatorStore_Geometry_TEMPORARY` contém somente BaseParts e propriedades visuais dos candidatos (sem scripts, remotes, sons ou interatividade). Há também cópias sem código dos modelos acima. Todos os clones de preview estão ancorados, sem colisão/toque/consulta. O rascunho `Workspace.FL016_ArenaAssetDraft_TEMPORARY`, no Edit em X≈3200, contém uma base de grama achatada, fachada de limite, tenda, torre, duas groves de pinheiros PBR, três modelos Outpost, cobertura, cercas, caixas e props. Por decisão do responsável, as cópias `Hill_NorthWest`/`Hill_SE` e todas as `PineCluster_*` foram removidas por incompatibilidade visual; a cópia de auditoria `PineTree_MilitaryMap` também foi removida. Os pacotes-fonte permanecem em quarentena para auditoria. `Ruined_Facade_CenterNorth` é somente uma fachada de fundo/limite: não constitui prédio interativo e suas partes estão sem colisão, toque e consulta. Ainda não há um conjunto aprovado de prédios urbanos interativos; os três `Outpost_*` são postos pequenos e não substituem essa necessidade. O rascunho segue temporário, fora da arena ativa e desconectado da `ArenaBuilder`; o trabalho foi pausado a pedido do responsável.

## Direção para a arena

A avaliação visual deve ocorrer antes de retomar a construção. A matriz por categoria está em `docs/ASSET_AUDITS/FL-016-selection-queue.md`; a grade correspondente no Studio é `Workspace.FL016_AssetSelectionQueue`. As fontes externas estão em quarentena e os clones exibidos são apenas geometria visual sanitizada. As fontes ainda precisam de auditoria individual; não tratar os anúncios como aprovação.

O pacote completo de nenhum dos dois mapas está aprovado. Esses resultados não fornecem um asset adequado de terreno/grama/montanhas. A cópia da arena de teste saiu do `Workspace`, mas a `ArenaBuilder` atual ainda cria terreno, ruas, prédios e barreiras com Parts em código; essa implementação precisa ser substituída por composição de assets aprovados antes de remover o caminho atual, para não deixar a partida sem arena.

## Pendências

- Auditar candidatos de uso único para terreno/grama, relevo e estruturas destruídas; candidatos adicionais só serão importados após consentimento específico.
- Promover apenas cópias/filhos que passem inspeção de scripts, remotes, dependências, permissões, escala, colisão e desempenho.
- Atualizar `ArenaBuilder` e revisar a arena no Studio quando houver assets aprovados.
- A branch `dev` não contém, neste registro, prova de gameplay/Playtest ou benchmark de runtime.

## Candidatos de ruas modulares — 2026-10-15

Foram pesquisados modelos gratuitos no Creator Store e comparadas miniaturas e metadados de anúncio. Nenhum foi importado: os itens pertencem a outros criadores, e a ferramenta do Studio exige consentimento explícito antes de inserir conteúdo de terceiros no place. A auditoria de scripts, dependências, permissões, colisão e desempenho ainda está pendente.

| Asset | Evidência de busca | Avaliação inicial |
|---|---|---|
| [Wessel Realistic road pack (16088161488)](https://create.roblox.com/store/asset/16088161488/Wessel-Realistic-road-pack), Iamplayingrobloxwes | Importado para `ServerStorage.BR_TerrainWorkshop.RoadAssetQuarantine`. 26 descendentes: 8 Parts ancoradas e colidíveis, 15 Textures e 3 Decals; zero scripts, remotes e sons. O importador reportou `sandboxed=false`, sem executáveis para sandboxar. As referências visuais pertencem a Sir_Trolling (ID `30060913`), diferente do autor do pack. Um preview local no `BR_Peninsula_Draft` usa 629 módulos clonados com a marcação reta `2091416637`; a fonte permanece em quarentena. | Preview visual local solicitado pelo responsável. Status continua `QUARANTINED` até confirmar permissão das imagens; não publicar. Marcação de curva, cruzamento e faixa de pedestres ainda precisa de posicionamento por nós; trecho do rio segue sem ponte. |
| [Modular City Road Set (1415307242)](https://create.roblox.com/store/asset/1415307242/Modular-City-Road-Set), Eixl | Gratuito no resultado do Creator Store; miniatura exibe trecho reto e cruzamento. Descrição: “Enjoy”. | Alternativa de autoria identificável, porém com pouca informação pública; não aprovado. |
| [Roblox Realistic City (15928729124)](https://create.roblox.com/store/asset/15928729124), Iamplayingrobloxwes | Importado para a mesma quarentena. 15.261 descendentes: 6.547 BaseParts (6.410 MeshParts), todas ancoradas; 5.238 colidíveis; 40 Scripts, 40 BindableEvents, 80 SurfaceGuis e 1.989 SurfaceAppearances. Zero remotes e sons. Caixa total: 2.000 × 389,3 × 2.000 studs. Os scripts foram desativados; source legível descreve alternância de semáforos, sem `require`, `HttpService` ou `loadstring`. | Não usar o pacote completo: excede a escala do mapa e tem custo estático alto. Avaliar somente edifícios/peças individuais após auditoria de dependências e permissões. Nenhuma geometria foi copiada para Workspace. |

Foram descartados da shortlist os resultados `132579672220859` e `80983232791107`: em um, o nome do criador retornado diverge do nome “Wessel” do modelo; no outro, a descrição atribui o pack a ArcherJ6, mas o criador do item é Tivufulu867. O pack Wessel continua guardado na quarentena e seu preview visual local está em `Workspace.BR_Peninsula_Draft.Road_Assets_V7`; a cidade permanece fora do Workspace. As imagens seguem com permissão pendente. Registro atualizado em `assets/registry.csv`.
