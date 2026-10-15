# FL-014 — Auditoria do kit militar mínimo

**Data:** 2026-10-15 · **Studio:** `Place1`, modo Edit · **Estado:** candidatos em quarentena, sem promoção ao mapa final.

## Decisão de seleção

| Papel | Candidato | Origem e termos | Resultado |
|---|---|---|---|
| Rifle visual | [Auto Rifle oficial](https://create.roblox.com/store/asset/4842207161/Auto-Rifle), ID `4842207161`, `@Roblox` | Gratuito; [Weapons Kit](https://create.roblox.com/docs/resources/weapons-kit) sob [Limited Use License](https://create.roblox.com/docs/resources/limited-use-license), para desenvolvimento de experiências Roblox | Usar somente a geometria de um dos três rifles importados; o sistema próprio de combate não será usado. |
| Rig técnico | R15 neutro gerado pelo [Rig Builder/API do Studio](https://create.roblox.com/docs/studio/rig-builder), ID interno `builtin:R15` | Recurso nativo da Roblox, sem compra ou asset de terceiro | Base R15 para FL-015; uniforme e equipamento visual ainda faltam. |
| Kit urbano | [City Props Pack](https://create.roblox.com/store/asset/6370681139), ID `6370681139`, `@Roblox` | Get Model gratuito; termos do [Creator Store](https://create.roblox.com/docs/production/creator-store) | Subconjunto: `StreetLightPole_01_A`, `Bus_Stop_01_A`, `FireHydrant_01_A`. |

A busca do Studio por rigs militares trouxe resultados com nomes de criador que imitam `Roblox` usando caracteres invisíveis. Eles não foram escolhidos. O apartamento da FL-013 tem 10.427 descendentes e segue como candidato condicional, fora do kit mínimo.

## Isolamento e auditoria

- Originais da FL-013 continuam em `ServerStorage.FL013_Quarantine`. O Auto Rifle completo foi importado em `ServerStorage.FL014_Quarantine.FL014_Roblox_Auto_Rifle`; seus seis scripts executáveis foram desativados. O modelo contém três `Tool`, 42 `ModuleScript`, 3 `Script`, 3 `LocalScript` e 3 `RemoteEvent`. Ele não foi colocado em `StarterPack` nem em `Workspace`.
- A cópia `FL014_RifleVisual_Candidate` contém 3 `MeshPart`, 7 `Attachment`, 1 `Motor6D` e 1 `WeldConstraint`; zero scripts, remotes, sons ou efeitos. Todas as peças foram ancoradas e ficaram sem colisão na quarentena. IDs de malha/textura: `2492890820`, `2492891824`, `2492892116`, `2492896951`.
- O `FL014_R15_Rig_Candidate` foi gerado a partir de `HumanoidDescription` vazio; 1 script `Animate` e 27 `Animation` de exemplo foram removidos. Permanecem 15 `MeshPart`, 1 `Part`, `Humanoid` e juntas R15; zero scripts/animações na cópia. Os 16 IDs de malha/textura são de `assetdelivery.roblox.com`: `111092388570647`, `123480233606534`, `7430070991`, `7430070997`, `7430071005`, `7430071013`, `7430071038`, `7430071039`, `7430071041`, `7430071044`, `7430071049`, `7430071065`, `7430071082`, `7430071105`, `7430071109`, `7430071119`.
- `FL014_UrbanProps_Candidate` contém só os três props selecionados: 9 `MeshPart`, 2 `SurfaceAppearance`, 1 `SpotLight`, 1 `Attachment`; zero scripts, módulos ou remotes. As peças estão ancoradas e sem colisão na quarentena. IDs de malha/textura: `4689828774`, `5350235863`, `5350236126`, `5350236341`, `5350236543`, `5356592521`, `5356592795`, `5356592878`, `5356592944`, `5356593007`, `5356593073`, `5946954074`, `5946954123`, `5946954949`, `5946955292`, `5947003401`, `5947017173`, `6432534338`.
- `ContentProvider:PreloadAsync` retornou `Success` para 4 conteúdos no rifle, 31 no rig e 10 nos props. É evidência de carregamento nesta sessão local, não garantia de publicação em outra experiência.
- A inspeção visual está em [FL-014-preview.jpg](../TEST_REPORTS/FL-014-preview.jpg). A vitrine temporária usada para a captura foi removida do `Workspace`; os candidatos seguem em `ServerStorage.FL014_Quarantine`.

## Benchmark local exploratório

Playtest de cliente no Studio com a mesma câmera fixa (`0,12,35` olhando para `0,3,0`) e amostra de 5 segundos por cena. Linha de base da arena sem candidatos: 596 frames em 5,008 s, 119,01 FPS médios e 2.031,28 MB. Com rifle visual, R15 e três props posicionados temporariamente à frente da câmera: 594 frames em 5,008 s, 118,61 FPS médios e 2.104,60 MB. Os mínimos instantâneos foram 17,79 e 19,93 FPS, respectivamente, indicando picos breves; não afirmar estabilidade a 60 FPS a partir da média. Ambas as médias ficaram próximas do teto de 120 FPS da sessão, portanto o teste não quantifica o custo real dos modelos. A diferença de memória entre sessões também não é atribuível somente ao kit.

O Output coletado após o playtest não trouxe mensagens de falha de carregamento ou permissão dos candidatos. A vitrine temporária foi removida do `Workspace` ao encerrar o teste. Este benchmark cobre apenas o lote mínimo, nesta máquina e nesta câmera; a FL-017 mede a arena final em hardware-alvo.

## Resultado visual e gates

O rifle tem silhueta adequada como visual de teste. O R15 gerado ainda é um manequim escuro; a FL-015 precisa de uniforme, braços em primeira pessoa e animações próprias. O ponto de ônibus é relativamente grande para a largura das rotas e precisa de posicionamento final na FL-016. O lote não deve ser copiado inteiro para a arena, pois o sistema do Auto Rifle duplicaria o combate e a câmera existentes.

As cópias estão em `PERFORMANCE_TESTED` como teste local exploratório. Para `APPROVED`, faltam verificação de escala/colisão no mapa persistido e confirmação de carregamento das dependências na experiência de destino quando ela for publicada. A FL-016 deve persistir posição e colisão simplificada na fonte; o Studio aberto guarda os modelos, mas Git versiona somente IDs e a auditoria.
