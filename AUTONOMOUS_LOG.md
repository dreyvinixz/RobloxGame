# Registro de trabalho autônomo

Atualizado em 2026-10-15. Este registro acompanha as issues abertas #13–#32. `Concluída` exige PR e critérios de aceite atendidos; documentação ou código sem playtest exigido permanece parcial.

| Issue | Estado | PR | Decisão e pendência principal |
|---|---|---|---|
| #13 FL-013 | Parcial | [#43](https://github.com/dreyvinixz/RobloxGame/pull/43) | Direção visual, guia, seleção e procedência registrados; validação estática, 3 testes Python e Rojo build passaram. PR #43 foi integrado à branch FL-012; a pilha ainda aguarda integração à `main`. |
| #14 FL-014 | Parcial | [#44](https://github.com/dreyvinixz/RobloxGame/pull/44), [#45](https://github.com/dreyvinixz/RobloxGame/pull/45) | Aprovados para prototipagem o rifle visual limpo, rig R15 e três props. Studio confirmou 4/31/10 conteúdos carregados; bus stop reposicionado em X=112 e percurso local sem bloqueio. PR #45 está aberto sobre a branch de dependência; integração final e permissões fora desta experiência local permanecem pendentes. |
| #15 FL-015 | Parcial | [#46](https://github.com/dreyvinixz/RobloxGame/pull/46) | Viewmodel local R15, rifle visual limpo, recuo/recarga client-side; validator, 3 testes e Rojo build passaram. Captura confirmou sightline em repouso. Studio Play confirmou nova identidade de Character após `LoadCharacterAsync`, HP=100 em `Spawn_WestEntry` e `FrontlineViewmodel` presente no Client após respawn. Inspeção de quadros transitórios de animação segue pendente. PR draft empilhado em #14. |
| #16 FL-016 | Parcial | [#47](https://github.com/dreyvinixz/RobloxGame/pull/47) | PR anterior integrado na linha de desenvolvimento. Esta revisão em `dev` confirmou que `FL013_TestArena` ainda era uma cópia de teste separada; ela foi movida do Workspace para `ServerStorage.FL016_Quarantine` (10.476 descendentes preservados). `ArenaBuilder` ainda gera geometria com Parts. WW2 Map (15 scripts com fonte ilegível) e Military Map (100 scripts; `require` dinâmico observado) estão em quarentena com scripts desativados; nenhum executado ou usado na arena. Nenhum mapa completo aprovado. Auditoria: `docs/ASSET_AUDITS/FL-016-assets.md`. Substituição do gerador, assets de cenário, revisão das rotas/colisões e Playtest continuam pendentes. |
| #17 FL-017 | Parcial | [#48](https://github.com/dreyvinixz/RobloxGame/pull/48) | Baseline Studio local medida em host identificado (i5-11400H, GTX 1650 Max-Q disponível, 16 GB). FPS/memória/render/geom./rede/load documentados sem extrapolar. PR draft; confirmar que este é hardware-alvo e repetir no cliente standalone antes de definir orçamento. |
| #18 FL-018 | Parcial | [#49](https://github.com/dreyvinixz/RobloxGame/pull/49) | Dois clientes simulados validaram FireWeapon→DamageService→MatchService, equipes, placar, respawn e proteção. Transição por tempo/score-win não foi acelerada no teste; revisão e integração empilhada pendentes. |
| #19 FL-019 | Parcial | [#50](https://github.com/dreyvinixz/RobloxGame/pull/50) | Retry Studio de 2 clientes (comentário do responsável): três payloads inválidos deixaram HP 100; tiro válido levou HP server/cliente 100→75, observador também 75, score inalterado; 50 reloads geraram 4 respostas. Variação de latência pendente: tentativa 120 ms por sentido + jitter 20 ms não iniciou por sessão StudioTestService anterior ativa; settings/harness temporários restaurados. Ver relatório. |
| #20 FL-020 | Parcial | [#51](https://github.com/dreyvinixz/RobloxGame/pull/51) | Play local confirmou equip, pente por arma, reload e falloff a ~200 studs (23,225 de dano). TTK local: rifle 0,532 s/4 hits e pistola 0,747 s/3 hits. Retry Studio com 2 clientes confirmou armas, falloff 23,27 em ~199 studs, HP observado replicado, pistola 3 hits e pente mantido (pistola 9/rifle 29); TTK observado 0,87 s não é medição controlada. Latência explícita e clientes standalone ainda pendentes. Ver relatório. |
| #21 FL-021 | Parcial | [#52](https://github.com/dreyvinixz/RobloxGame/pull/52) | Play local confirmou HP 100→75→50→25→0, estados Intact/Damaged/Destroyed e ocultação/colisão desligada após destruição. Alteração local do cliente não mudou o núcleo no servidor. StudioTestService com 2 clientes confirmou 0 HP, Destroyed, ocultação e CanCollide/CanQuery=false; terceiro cliente adicionado após destruição recebeu o mesmo snapshot. Teste de bloqueio: 4 tiros não causaram dano ao alvo atrás de cobertura intacta; após destruição, o próximo tiro causou 100→75 também no observador. Captura visual separada e repetição na aceitação integrada pendentes; ver relatório. |
| #22 FL-022 | Parcial | [#53](https://github.com/dreyvinixz/RobloxGame/pull/53) | Capturas Studio Device Simulator em iPhone 17 Pro (874×402) e iPhone 7 (667×375) mostram HP, placar e munição nos estados Waiting, Active e Result. Corrigi status de rodada truncado e sobreposição da munição com pulo touch; posições confirmadas sem overlap no viewport 666×374. Contagem ativa e painel de resultado capturados em ambos os dispositivos; largura do painel refinada após quebra de linha no iPhone 7. Validator, 3 testes e Rojo build passam. |
| #23 FL-023 | Parcial | [#54](https://github.com/dreyvinixz/RobloxGame/pull/54) | QA-04 passou em burst local de 10 tiros (um hit aceito); QA-11 passou com T, novo dummy e HUD 100/100. QA-03/06/08/09 têm passes direcionados anteriores em multiplayer simulado. A matriz integrada QA-01–QA-11 e QA-10 (10 min) seguem pendentes; NO-GO mantido por latência, integração e aceite humano. Ver `docs/TEST_REPORTS/FL-023.md`. |
| #24 FL-024 | Parcial | [#56](https://github.com/dreyvinixz/RobloxGame/pull/56) | Scout procedural e servidor autoritativo. Play de um cliente com teclado real confirmou entrada, avanço (pivot z -8→-40.04), throttle-release até velocidade 0, curva (LookVector -0.553, 0, -0.833), ré a -24 studs/s, saída e câmera restaurada; script Studio restaurado após o teste. Rota básica passou; colisão controlada, limite, observador segundo cliente, vídeo e repetição no build integrado pendentes. Ver `docs/TEST_REPORTS/FL-024.md`; gate MVP permanece NO-GO. |
| #25 FL-025 | Parcial | [#57](https://github.com/dreyvinixz/RobloxGame/pull/57) | Play Studio de um cliente confirmou tiro aceito HP 300→275; 11 tiros destruíram (HP 0, driver 0, speed 0, assento desativado), Enter foi bloqueado e Reset recriou um scout ativo HP 300 no pivot Y=3.15. Obstáculo queryable causou dano de colisão 300→290.4 e speed 0; removido o obstáculo, driver continuou e percorreu Z=-14.10→-24.36. Validator, 9 testes e Rojo passam. Replicação em 2 clientes, spam/cooldown e late join pendentes; ver relatório. |
| #26 FL-026 | Parcial | [#58](https://github.com/dreyvinixz/RobloxGame/pull/58) | S4 idle sample 30.022 s coletado: 56.21 FPS médio/p1 8.91; LibMP 62 frames, 15.71 ms média. Nove outras sessões Studio em Play e cena/viewport diferentes do S2 tornam a amostra não comparável; não atribuir regressão ao jogo. Repeat equivalente, MicroProfiler com cena controlada, draw calls/triângulos e leak/warning check seguem pendentes. Ver `docs/TEST_REPORTS/FL-026.md` e `docs/PERFORMANCE.md`. |
| #27 FL-027 | Parcial / NO-GO | [#59](https://github.com/dreyvinixz/RobloxGame/pull/59) | Checklist e changelog draft, runbook de rollback e revisão estática de assets/privacidade em `docs/ALPHA_RELEASE_CHECKLIST.md`. FL-023, FL-025 e FL-026 mantêm gates abertos; nada foi publicado. |
| #28 FL-028 | Parcial | [#55](https://github.com/dreyvinixz/RobloxGame/pull/55) | ADR-0002 recomenda NO-GO para ponte com processo BF6 ao vivo; GO somente para Roblox independente, workflow Portal dentro do escopo oficial ou mock sintético. Fontes oficiais, obstáculos e política anticheat documentados; sem alteração de executáveis. |
| #29 FL-029 | Parcial / bloqueado | [#60](https://github.com/dreyvinixz/RobloxGame/pull/60) | Plano server-authoritative e experimento em `docs/AI_BOT_READINESS.md`; implementação aguardará FL-023 NO-GO e perfil S4. |
| #30 FL-030 | Parcial / bloqueado | [#61](https://github.com/dreyvinixz/RobloxGame/pull/61) | Plano de reuso e rotação server-owned em `docs/MAP_2_READINESS.md`; aguardando FL-027 NO-GO. |
| #31 FL-031 | Parcial / bloqueado | [#62](https://github.com/dreyvinixz/RobloxGame/pull/62) | Design de assets, mix e pool cosmetic em `docs/AUDIO_VFX_READINESS.md`; aguarda FL-027. Nenhum efeito importado. |
| #32 FL-032 | Parcial / bloqueado | [#63](https://github.com/dreyvinixz/RobloxGame/pull/63) | Gaps desktop-only e plano touch/dispositivo físico em `docs/MOBILE_READINESS.md`; aguarda FL-027 e smartphone real. |

## Decisões de FL-013

- Primeiro lote visual: `StreetLightPole_01_A`, `Bus_Stop_01_A` e `FireHydrant_01_A` do pacote gratuito da Roblox.
- Um exemplar de `New York City Corner Apartment Building` fica como candidato condicional ao setor noroeste. Sua estrutura de 10.427 descendentes exige otimização e benchmark definitivo.
- A branch FL-016 já contém fachadas modulares nativas. A fachada importada deverá substituir os módulos visuais de apenas um setor, sem duplicação de geometria, e preservar uma colisão coerente.
- Os originais permanecem em `ServerStorage.FL013_Quarantine`. Os dois scripts `LightStateChanger` estão desativados. A FL-014 confirma permissões de dependências e promove apenas ativos aprovados.
- A sessão de playtest com cópias temporárias mediu 118,6 FPS e 1.922 MB por 5 segundos nesta máquina; não representa hardware-alvo. O proprietário confirmou percurso jogável após corrigir sobreposições. As posições temporárias precisam ser persistidas na fonte.

## Revisão do responsável

Revisar primeiro procedência e permissões dos assets escolhidos, depois o setor noroeste da FL-016 e o benchmark FL-017. Nenhum asset pago foi adquirido e nenhuma experiência Roblox foi publicada.

## Aprovação da FL-014 — 2026-10-15

- Aprovados apenas os clones sem scripts: rifle visual, rig técnico R15 e três props urbanos. Os originais e o sistema de arma importado seguem em quarentena.
- O ponto de ônibus sobrepunha o bloco de teste em X=84; foi movido no Place1 salvo para X=112. A caixa AABB não cruza estruturas e o personagem percorreu a rota lateral no Play com 100 HP.
- PreloadAsync em instâncias reais: 4/4 conteúdos do rifle, 31/31 do rig e 10/10 do kit urbano com Success. Isso não comprova acesso numa experiência publicada diferente.
- PR [#45](https://github.com/dreyvinixz/RobloxGame/pull/45) usa `feat/FL-014-approve-assets` sobre a branch de dependência FL-014. A issue permanece aberta até integração na `main`; FL-016 ainda deve versionar as posições e colisões finais.

## Implementação parcial da FL-015 — 2026-10-15

- `FirstPersonViewmodel` cria seis braços locais simples a partir da validação do rig R15, evita diferenças de escala dos meshes de avatar e acompanha a câmera; arma tem recuo e movimento de recarga locais. O `WeaponController` conserva raio de mira pela câmera e o servidor conserva validação do disparo.
- `ViewmodelAssetService` replica somente o clone visual aprovado e rejeita BaseScripts, remotes ou sons; o pacote importado segue em quarentena.
- Play local confirmou construção do viewmodel e sightline livre na captura `FL015_rest2`; fire/reload inputs foram enviados. Teste de morte/respawn foi inconclusivo para troca de identidade. Detalhes e pendências em `docs/TEST_REPORTS/FL-015.md`.
- PR draft [#46](https://github.com/dreyvinixz/RobloxGame/pull/46) em `feat/FL-015-first-person-viewmodel`, empilhado sobre `feat/FL-014-approve-assets`; integração final aguarda as branches precedentes.

## Implementação da FL-016 — 2026-10-15

- `ArenaBuilder` mantém o layout modular existente e adiciona somente os três props aprovados. O clone é recusado se tiver scripts, remotes ou sons; as cópias ficam ancoradas, sem colisão/consulta, e o greybox conserva colisão.
- Place1 Play executou o módulo Rojo real: 3 props, 3 route markers, 16 peças colidíveis na base, nenhuma interseção AABB com prop decorativo. Navegação alcançou `z=-32`, `0` e `32`; humanoide no fim: 100 HP, Running.
- Reporte e registro do asset atualizados em `docs/TEST_REPORTS/FL-016.md` e `assets/registry.csv`; captura do gerador real em `docs/TEST_REPORTS/FL-016-generated-arena.jpg`.
- PR [#47](https://github.com/dreyvinixz/RobloxGame/pull/47), branch `feat/FL-016-modular-arena`, base `feat/FL-015-first-person-viewmodel`. Revisão externa e integração aguardam.

## Baseline local da FL-017 — 2026-10-15

- Host medido: i5-11400H, 16 GiB, adaptadores Intel UHD e GTX 1650 Max-Q, desktop 1920×1080; GPU ativa não foi confirmada. Studio `0.743.0.7431133`, qualidade automática.
- Sample idle de 30.008 s: 120.03 FPS média, 100.94 FPS p1, 29 draw calls, 46,779 triângulos, 2,104.39 MB processo, CPU/GPU render 7.17/2.49 ms médios. Rates de rede ficaram quase nulos; ping/data ping são locais do Studio. Start-to-ready via MCP levou 3.612 s com overhead de ferramenta.
- Gargalo CPU/render é hipótese por frame-time relativo e p1, ainda precisa MicroProfiler; não fixar budget do jogo a partir desse sample. O hardware-alvo não foi confirmado. Método/dados em `docs/PERFORMANCE.md` e `docs/TEST_REPORTS/FL-017.md`.
- PR draft [#48](https://github.com/dreyvinixz/RobloxGame/pull/48), branch `feat/FL-017-performance-baseline`, base `feat/FL-016-modular-arena`.

## Validação parcial da FL-019 — 2026-10-15

- Revisão de `FireWeapon`: chaves exatas, vetores finitos, arma permitida, direção unitária e coerente com alvo, alcance, origem próxima à cabeça, cooldown e rejeição de argumentos extras. Dano permanece calculado por configuração do servidor. `DamageService` limita reload a um pedido por 0.25 s/jogador e limpa o relógio ao sair.
- Retry Studio com 2 clientes reportado pelo responsável: extra `damage`, argumento extra e origem forjada deixaram HP em 100; tiro válido alterou HP server/cliente 100→75, observador também 75 e score permaneceu igual; 50 pedidos de reload geraram quatro respostas `WeaponState`.
- Tentativa de latência configurou 120 ms mínimo em cada sentido e jitter de 20 ms em cada direção. `ExecuteMultiplayerTestAsync` não iniciou porque já havia outra sessão ativa. Não interrompi os testes FL-023 em andamento. O harness e sync temporários foram removidos, fontes restauradas ao snapshot, settings voltaram a zero; uma tentativa de abrir build isolada não produziu janela/conexão Studio utilizável e o processo iniciado foi encerrado.
- Sem resultado condicionado à latência. FL-019 permanece parcial até repetir a bateria de 2 clientes com latência/jitter não-zero. Relatório em `docs/TEST_REPORTS/FL-019.md`; PR draft #50 empilhado sobre FL-018.

## Implementação parcial da FL-021 — 2026-10-15

- `DestructibleCoverService` inicializa núcleos com 100 HP e estados `Intact`, `Damaged` (≤50 HP) e `Destroyed` (0 HP). Só tiros aprovados pelo `CombatRequestService` chegam ao serviço via `DamageService`.
- A destruição oculta núcleo e painéis e desativa colisão e raycast. Atributos e propriedades replicam pelo servidor; não existe remote de destruição para o cliente.
- Validator, 3 testes Python, Rojo build e diff check passaram. Playtest de dano em estágios, colisão/visual em dois clientes, tentativa client-only e late join permanece pendente por falta de sync estável.
- Detalhes em `docs/TEST_REPORTS/FL-021.md`; PR draft #52 empilhado sobre FL-020.

## Implementação da FL-018 — 2026-10-15

- `MatchService` atribui Azul/Laranja de forma balanceada, configura spawns protegidos, mantém KOs/Deaths e estado de rodada autoritativos; `DamageService` recusa fogo amigo e mortes de jogadores fora da rodada.
- `StudioTestService.ExecuteMultiplayerTestAsync(2, "FL018_Acceptance")` passou com servidor e dois clientes simulados. O cliente de teste enviou o payload FireWeapon por RemoteEvent com câmera central e posições controladas; não foi clique físico de mouse. Resultado: `PASS | FireWeapon server-validated | Azul vs Laranja | scores Azul=1 Laranja=0 | spawn e escudo validados`.
- Confirmados bloqueio e expiração da proteção inicial, dano letal validado, incrementos de score/KOs/Deaths, respawn no time certo e reaplicação de ForceField. A transição de timeout e a condição de vitória foram inspecionadas no código, sem avanço de relógio no teste.
- Relatório em `docs/TEST_REPORTS/FL-018.md`. PR [#49](https://github.com/dreyvinixz/RobloxGame/pull/49) empilhado sobre FL-017; revisão e integração pendentes.

## Implementação parcial da FL-022 — 2026-10-15

- `HudController` exibe HP/barra, placar Azul/Laranja, fase/cronômetro e resultado final a partir do Humanoid local e atributos replicados de `MatchState`.
- `WeaponController` mantém munição/reload/arma atual com layout relativo à viewport; dano confirmado pelo servidor aciona hit marker, sem feedback de hit decidido pelo cliente.
- Validator, 3 testes Python, Rojo build e diff check passaram. Falta validar legibilidade visual e salvar capturas em duas resoluções no Studio.
- Evidência e limitação em `docs/TEST_REPORTS/FL-022.md`; PR draft #53 empilhado sobre FL-021.

## FL-023 — evidência atualizada e decisão de gate — 2026-10-15

- `docs/TEST_PLAN.md` contém 11 casos QA-01–QA-11, embora a issue diga “10”; matriz preserva os 11.
- Studio local: 10 requests imediatos de rifle resultaram em um hit (HP 100→75); após três tiros válidos espaçados o dummy chegou a 0, a tecla T recriou o alvo, e a inspeção confirmou Humanoid 100/100 e rótulo `DUMMY  100 / 100 HP`.
- Evidência dirigida anterior: QA-03/06/08/09 passaram em sessões `StudioTestService` com clientes simulados, QA-05 tem três payloads inválidos sem alterar HP no cliente shooter. Repetições integradas, snapshots de observador após cada payload inválido e latência variada continuam pendentes.
- QA-10 permanece sem resultado: um teste de 10 minutos não foi concluído. O runner atual recusou nova sessão por `Failed to start the test because a previous one is still in progress`; o monitor que foi iniciado por menos de um minuto foi excluído da evidência.
- Decisão **NO-GO**: zero bloqueadores P0 não está demonstrado e nenhuma aprovação humana do MVP foi dada. PR draft #54 segue empilhado sobre FL-022; revisar relatório e executar matriz integrada antes de liberar S4.
- Neste commit: validator passou, 3 testes Python passaram e `git diff --check` passou. `rojo build` foi tentado mas `rojo` não está instalado/no PATH; Selene e StyLua também indisponíveis. Resultados de build em commits ancestrais não foram reivindicados para esta revisão.

## Implementação parcial da FL-020 — 2026-10-15

- `WeaponConfig` agora tem rifle e pistola com dano, cadência, munição, reload, alcance, multiplicador de headshot e falloff linear. `DamageService` aplica a queda por distância real do raycast, e cada arma mantém pente/reload próprio no servidor.
- O cliente solicita troca em 1/2. `CombatRequestService` permite apenas IDs configurados, exige arma selecionada e limita frequência de tiro/troca no servidor.
- Números e TTK calculados em `docs/WEAPONS.md`; relatório `docs/TEST_REPORTS/FL-020.md` distingue cálculo de medição.
- Validator, 3 testes Python, Rojo build e diff check passaram. Retry posterior com dois clientes confirmou equip, munição, falloff e TTK observado; latência variada e medida controlada continuam pendentes (ver relatório).
- PR draft #51 empilhado sobre FL-019.

## Implementação parcial da FL-025 — 2026-10-15

- Health/estado do scout são server-owned e replicados por atributos. Tiros chegam ao serviço somente após validação do request e raycast servidor; colisão em velocidade aplica dano. Destruição ejeta o motorista, bloqueia movimento/entrada e reset próximo recria o modelo no spawn com cooldown. Dano e reset têm throttles.
- Validação estática em andamento. Probe de ciclo completo e replicação de dois clientes ainda pendentes; a issue fica IN_PROGRESS até evidência Studio. Ver `docs/TEST_REPORTS/FL-025.md`.\n

## Implementação parcial da FL-026 — 2026-10-15

- Baseline S2 registrada (idle local, 30 s). Repetição S4, MicroProfiler, contagem de warnings/leaks e standalone permanecem pendentes porque a branch ainda não foi sincronizada no Studio e Rojo não está disponível. Fontes revisadas sem atribuir gargalo ou propor otimização especulativa.
- Issue em IN_PROGRESS; ver `docs/TEST_REPORTS/FL-026.md`.

## Preparação parcial FL-027 — 2026-10-15

- Inventário dos 10 registros de assets: 3 aprovados para protótipo, 3 em quarentena, 3 descobertos e 1 procedural em protótipo. Nenhum item fora do estado aprovado/protótipo foi promovido. Não houve compra/publicação.
- Scan de código não achou DataStore, HttpService ou AnalyticsService customizados em `src/`; configurações da experiência e política de privacidade continuam revisão do proprietário. Questionário de maturidade deixado para revisão manual do conteúdo final.
- FL-023 segue NO-GO; FL-025/026 têm evidências multiplayer/performance pendentes. Checklist não autoriza publicação.

## Preparação parcial FL-029 — 2026-10-15

- Design de bot server-authoritative, estados, cotas e sequência de benchmark registrados. FL-023 ainda NO-GO; não foram criados NPC, scripts ou novos assets antes da estabilidade multiplayer.

## Preparação parcial FL-030 — 2026-10-15

- Documentados limites entre builder, serviços de partida e conteúdo, rotação permitida somente entre rounds e cenário de benchmark/reconexão. Nenhum asset novo inserido antes do gate alpha.

## Preparação parcial FL-031 — 2026-10-15

- Definidos gates de licença, pool de partículas limitado, feedback cosmetic e teste A/B com duas sessões e dois clientes. Nenhum audio/efeito adicionado, sem compras e sem medida A/B.

## Preparação parcial FL-032 — 2026-10-15

- Inspeção encontrou sprint/fire/reload/equip/vehicle control mapeados a teclado/mouse. HUD tem apenas Device Simulator layout evidence da FL-022. Plano de touch e aceitação física registrado; nenhum smartphone real foi usado e nenhum código de controle foi adicionado.

## Verificação retrospectiva de build Rojo — 2026-10-15

- Após a validação inicial, obtive Rojo 7.7.1 oficial para Windows x86_64 e confirmei o SHA-256 do zip com o digest da release GitHub. `rojo build <branch> --output <temp>.rbxlx` passou nos heads das branches dos PRs #54–#63 (issues #23–#27 e #28–#32). Binário e builds ficaram em `%TEMP%`; nenhum foi adicionado ao projeto.
- A validação de serialização não demonstra comportamento Luau/Studio nem substitui os playtests ainda pendentes. Selene e StyLua seguem indisponíveis.

## Integração final — 2026-10-15

- README atualizado para refletir o protótipo local e o gate de release NO-GO. PR draft [#64](https://github.com/dreyvinixz/RobloxGame/pull/64) agrupa o sumário do stack e docs/TEST_REPORTS/INTEGRATION.md; sem push em main e sem publicação Roblox.


## Terrain 2 — pós-V5/V6/V7 evidência de perfil — 2026-10-16

- Captura LibMP adicional apenas no candidato: 109 frames completos; CPU mediana 16.688 ms, p95 18.114 ms, máximo 18.760 ms. A captura vazia correspondente não foi concluída/obtida; resultado A/B e gate de desempenho continuam inconclusivos.
- Para preparar baseline, os limites de teste foram limpos reversivelmente com `CopyRegion`; leitura do servidor confirmou 0 voxels e backup em memória presente. Após `PasteRegion`, leitura no servidor e no Edit confirmou 370,626 voxels (Water 146,120; Rock 195,768; Sand 3,485; Grass 25,253). A sessão Studio continua não salva.
- `tools/terrain_2_v3/V6_V7_README.md` e atributos do modelo isolado registram a captura parcial e a restauração. Sem mudanças em `main` ou no lugar de produção; gates visuais V5, persistência V6 e aceitação V7 continuam abertos.
- Alteração documental; nenhum teste automatizado executado nesta atualização.

## Terrain 2 — experimento de resolução V5 513×513 — 2026-10-16

- Reexecutei V3/V4/V5 com grade 513 usando as referências originais cujos hashes estão no relatório. A malha adaptativa selecionada produziu 75,248 vértices e 148,797 triângulos; o V4 da mesma grade produziu baseline consistente.
- A V5 513 reduziu a média dos perfis cardinais de 13.41 para 12.96 px-equivalentes e melhorou o score do atlas, mas o holdout wireframe-2 regrediu de 0.87909 para 0.89932 (limite 0.88409). Resultado `V5_NO_GO_MULTIVIEW_GEOMETRY`; candidato não promovido. A V5 257 previamente selecionada permanece a candidata relativa.
- O resultado e a razão da rejeição foram registrados em `tools/terrain_2_v3/V5_README.md`. Escala maior sozinha não resolve a discrepância multivista; fidelidade absoluta continua NO-GO.

## Terrain 2 — métrica proxy de V6 field→voxel — 2026-10-16

- Confirmei o hash da fonte V5 (`ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`) e comparei o heightfield Y=100+relief com o topo estimado por coluna do `ReadVoxels`, nas 37,818 colunas da máscara terrestre V2, respeitando o eixo Z invertido.
- MAE 0.307 studs, RMSE 0.943 studs, máximo 9.3 studs; 97.2% das colunas ficaram dentro de 2 studs e 1.6% tiveram erro de 4 studs ou mais. O método é proxy de quantização/alinhamento; a revisão espacial dos outliers e a comparação direta da malha com os voxels seguem abertas.
- Atualizei `tools/terrain_2_v3/V6_V7_README.md`. Sem alteração de terreno neste passo; sem testes automatizados.

## Terrain 2 — correção da métrica proxy V6 — 2026-10-16

- A primeira comparação usou toda a máscara terrestre e contou 993 células cobertas pela água do canal; nessas células, o topo de água foi incorretamente comparado ao terreno submerso. Essa estatística foi substituída.
- Recalculei com a máscara `land_all_components` menos `water_width_1.0_depth_1.0.png`: 36,825 colunas secas, MAE 0.195 studs, RMSE 0.505, máximo 2.0; 99.4% dentro de 2 studs. Confirmada relação de coordenadas e fonte V5 com hash `ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`.
- README atualizado; comparação direta com a malha adaptativa permanece aberta.

## Terrain 2 — refinamento local da malha V5 — 2026-10-16

- Acrescentei refinamento iterativo guiado pelo erro à exportação da malha adaptativa. O processo insere amostras terrestres onde a interpolação linear da triangulação excede 2 unidades relativas; não altera o campo de elevação escolhido, a seleção multivista, nem atribui escala física.
- Reexportei diretamente o campo original V5 com SHA-256 `ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`: 19,070 vértices e 37,266 triângulos (145 vértices adicionais). Em 36,821 amostras terrestres cobertas, erro da malha contra o campo: RMSE 0.096 unidades relativas e máximo 1.994; quatro colunas secas não têm triângulo retido.
- Contra o proxy de topo dos voxels lido do Studio, nos mesmos pontos cobertos: MAE 0.196 studs, RMSE 0.513, máximo 3.8; 99.1% até 2 studs. É comparação de amostras de grade, não uma auditoria integral da superfície de colisão. A malha refinada ainda não foi importada para o place.
- Atualizados `tools/terrain_2_v3/V5_README.md` e `tools/terrain_2_v3/V6_V7_README.md`. O place permanece sem salvar e as validações visuais V5, persistência V6 e gates de jogabilidade/desempenho V7 continuam abertas. Nenhum teste automatizado local foi executado nesta atualização.
