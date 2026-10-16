# Registro de trabalho autônomo

Atualizado em 2026-10-15. Este registro acompanha as issues abertas #13–#32. `Concluída` exige PR e critérios de aceite atendidos; documentação ou código sem playtest exigido permanece parcial.

| Issue | Estado | PR | Decisão e pendência principal |
|---|---|---|---|
| #13 FL-013 | Parcial | [#43](https://github.com/dreyvinixz/RobloxGame/pull/43) | Direção visual, guia, seleção e procedência registrados; validação estática, 3 testes Python e Rojo build passaram. PR #43 foi integrado à branch FL-012; a pilha ainda aguarda integração à `main`. |
| #14 FL-014 | Parcial | [#44](https://github.com/dreyvinixz/RobloxGame/pull/44), [#45](https://github.com/dreyvinixz/RobloxGame/pull/45) | Aprovados para prototipagem o rifle visual limpo, rig R15 e três props. Studio confirmou 4/31/10 conteúdos carregados; bus stop reposicionado em X=112 e percurso local sem bloqueio. PR #45 está aberto sobre a branch de dependência; integração final e permissões fora desta experiência local permanecem pendentes. |
| #15 FL-015 | Parcial | [#46](https://github.com/dreyvinixz/RobloxGame/pull/46) | Viewmodel local R15, rifle visual limpo, recuo/recarga client-side; validator, 3 testes e Rojo build passaram. Captura confirmou sightline em repouso. Studio Play confirmou nova identidade de Character após `LoadCharacterAsync`, HP=100 em `Spawn_WestEntry` e `FrontlineViewmodel` presente no Client após respawn. Inspeção de quadros transitórios de animação segue pendente. PR draft empilhado em #14. |
| #16 FL-016 | Parcial / fila de seleção | [#47](https://github.com/dreyvinixz/RobloxGame/pull/47) | Construção do mapa pausada por solicitação. `Workspace.FL016_AssetSelectionQueue` contém 39 modelos visuais em 10 linhas por categoria e quatro colunas; cópias de geometria sem scripts/remotes/sounds, alinhadas no mesmo plano. Fontes de Creator Store estão em quarentena; 159 `BaseScript` foram desativados e nenhum executado. Os modelos ainda precisam de auditoria individual de dependências, licença, colisão e adequação; nenhum foi aprovado para a arena. A matriz com miniaturas e links está em `docs/ASSET_AUDITS/FL-016-selection-queue.md`. `Hill_NorthWest`/`Hill_SE` e `PineCluster_*` rejeitados foram removidos das cópias temporárias; a fachada arruinada é apenas limite visual. `ArenaBuilder` continua inalterado. |
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

# FL-016 — identificação visual de prédios na fila — 2026-10-15

- Para responder à falta de prédios identificáveis, seis candidatos 3D gratuitos foram importados em `ServerStorage.FL016_Quarantine` e organizados em `Workspace.FL016_AssetSelectionQueue`, fileiras `11_URBAN_BUILDINGS_A` e `12_DAMAGED_STRUCTURES_B`.
- A matriz agora contém 12 fileiras e 45 modelos; a galeria segue isolada da arena. Cópias visuais foram alinhadas nos mesmos centros de coluna e niveladas no piso. Scripts, remotes e sons foram removidos das cópias; scripts encontrados nas fontes foram desativados.
- Evidência de Studio Edit: tela capturada na linha das construções. Os seis modelos possuem 48–966 Parts. Os dois pacotes que continham scripts/remotes/sons seguem em quarentena, sem avaliação de licença/segurança concluída. Nada foi aprovado ou integrado ao mapa.

# FL-016 — hangares e interiores para combate — 2026-10-15

- O responsável observou que ainda faltavam estruturas percorríveis para a experiência FPS/Battle Royale. Mantive o fluxo de decisão visual antes de construir o mapa e ampliei `Workspace.FL016_AssetSelectionQueue` com as fileiras 13 (`13_HANGARS_GARAGES`) e 14 (`14_ENTERABLE_INTERIORS_FPS`), além dos seis prédios já avaliados na fila.
- O Creator Store retornou oito candidatos grátis para avaliação: quatro hangares/garagens, um prédio de apartamentos com interior, um prédio danificado com interior, um warehouse com interior e um layout FPS de paintball rotulado como referência. Galeria agora soma 14 fileiras e 53 candidatos.
- Cópias de preview estão alinhadas no mesmo plano e sem colisão. Scripts/remotes/sons foram removidos das cópias; scripts executáveis encontrados nas fontes foram desativados na quarentena. A indicação "interior" é apenas sinal para avaliar: nenhuma circulação foi comprovada por playtest. Nenhum asset foi aprovado ou integrado à arena.

# FL-016 — pontes, rapel, radar e antenas — 2026-10-15

- Ampliei a fila de avaliação com quatro fileiras: `15_BRIDGES`, `16_RAPEL_VERTICAL_ACCESS`, `17_RADAR_SURVEILLANCE` e `18_COMMUNICATION_ANTENNAS`, quatro candidatos por fileira. A matriz soma 18 linhas e 69 candidatos visuais.
- Fontes importadas para `ServerStorage.FL016_Quarantine`; scripts encontrados foram desativados. Os previews foram alinhados no mesmo plano e removidos de scripts, remotes e sons. O maior bundle de rapel contém 56 scripts, 66 remotes e 42 sons; foi mantido em quarentena e só a geometria limpa aparece na fila.
- Verificação em Studio Edit: 18.898 Parts de preview, zero scripts/remotes/sons na galeria e zero scripts de fonte habilitados nos 16 itens novos. O Creator Store só retornou um modelo rotulado explicitamente como rapel; a mecânica de descida não foi implementada nem testada. Nenhum item foi aprovado ou integrado à arena.


# FL-016 — armas, granadas, loot e vegetação na fila — 2026-10-15

- Reorganizei `Workspace.FL016_AssetSelectionQueue` em 23 classes/linhas contíguas e 89 candidatos, incluindo 20 novos previews: quatro armas, quatro granadas/itens de fumaça, quatro airdrops, quatro árvores e quatro opções de grama/arbustos.
- Props antigos foram redistribuídos entre loot/suprimentos, fortificações, acesso vertical, árvores e vegetação. Nenhum candidato foi aprovado ou colocado na arena; fontes seguem em `ServerStorage.FL016_Quarantine`.
- Verificação em Studio Edit: 23 pastas, 89 modelos, 89 suportes e 19.191 peças visuais. Todos os modelos estão centrados por coluna, no mesmo plano Y=0, ancorados e sem colisão/toque/consulta. A galeria não contém scripts, remotes nem sons.
- A granada stun foi importada como `SpecialMesh` isolado e recebeu uma base invisível somente no preview. O trabalho é uma galeria de seleção; ainda não houve teste de renderização em Play nem integração com gameplay.
# FL-016 — status de seleção e candidatos de destruição — 2026-10-15

- Marquei 9 modelos listados pelo responsável com SelectionStatus=NAO_USAR e suportes vermelhos; marquei os outros 80 candidatos já existentes USAR. Isso registra a preferência da matriz e não integra assets ao mapa.
- Pesquisei e importei 5 modelos de destruição/ruínas/fumaça para ServerStorage.FL016_Quarantine, exibindo previews âmbar na linha 14_WAR_RUINS_FIRE como REVISAR. As linhas anteriores 14–23 foram deslocadas para 15–24 para preservar o agrupamento por classe.
- Auditoria: o asset 107520871793479 contém 1 script, desativado na quarentena e ausente do preview; os quatro outros candidatos não apresentaram scripts no inventário verificado. O asset 15973301983 tem 82 MeshParts e 79.620 triângulos segundo a página Creator Store.
- Studio Edit validado: 24 linhas, 94 modelos, 94 suportes e 19.580 peças visuais; modelos no plano Y=0, alinhados, sem colisão/toque/consulta e sem scripts/remotes/sons nos previews. Nenhum candidato novo foi aprovado e nenhum asset foi integrado ao mapa.
# FL-016 — tema costeiro de península, logística e usinas — 2026-10-15

- Organizei três classes antes da cidade: entrada costeira/palmeiras/cais (linha 15), contêineres e logística portuária (16), usinas/infraestrutura industrial (17). As classes existentes de prédios foram deslocadas para 18–27; o mapa não foi construído.
- Importeis 15 novos candidatos gratuitos para quarentena e revisão: 6 de costa/palmeiras, 5 de contêineres/logística e 4 de usinas. O item Coconut Tree está incluído. Um candidato com “Coconut” no título falhou com HTTP 404 e foi substituído por outro que importou corretamente.
- Os novos modelos seguem em REVISAR. Scripts encontrados nas fontes Tropical Palm Pack (1), Shipping Container Open Door (1) e Power Plant (2) foram desativados na quarentena e omitidos dos previews; quatro sons da fonte Power Plant também não aparecem no preview.
- Studio Edit: 27 linhas, 109 modelos, 109 suportes e 27.591 peças visuais. Status total: 80 USAR, 9 NÃO USAR, 20 REVISAR. Validação sem peças de preview fora do alinhamento, colisão ou código executável.
# FL-016 — atualização das decisões de assets — 2026-10-15

- O responsável marcou como NÃO USAR os assets 17_02_NuclearPowerPlant_2466887748, 17_04_PowerPlant_1636050870, 15_01_PalmTree_16921719191, 14_02_Ruins_ID1905076, 14_05_BurningBuilding_ID19520408 e 15_06_CoconutTree_138766745874748. O asset Burning Building estava repetido na mensagem; foram seis rejeições novas.
- Com os nove itens rejeitados anteriormente, a matriz agora registra 15 NÃO USAR e 94 USAR; nenhum item permanece em REVISAR. Os demais candidatos receberam USAR pela inferência que o responsável autorizou.
- Suportes foram atualizados no Studio: vermelho para NÃO USAR e cinza para USAR. Nenhum asset foi integrado ao mapa.
- Verificação Studio Edit: 27 linhas, 109 modelos e 109 suportes; alinhamento, piso e isolamento dos previews sem problemas. git diff --check passou.

# BR — desenho macro da península — 2026-10-15

- Após concordância do responsável, registrei um layout conceitual para o mapa BR: entrada norte, desembarque costeiro, porto/logística, bairro oeste, centro urbano, zona industrial, crista elevada e costa sul.
- O desenho define três rotas principais conectadas por caminhos secundários, alturas relativas e regras de leitura/rotação. Incluí esquema SVG em `docs/MAP_DESIGN/BR peninsula macro layout.svg` e especificação em `docs/MAP_DESIGN/BR_PENINSULA_MACRO_LAYOUT.md`.
- Nenhum asset foi movido para a arena e nenhum conteúdo foi alterado no Studio. A construção depende de auditar candidatos selecionados, preencher lacunas de terreno/relevo e cumprir os gates de prontidão. Os IDs rejeitados permanecem fora do layout.
- Não executei testes; esta entrega é somente documentação de design.

# BR — primeiro passe de terreno e assets no Studio — 2026-10-15

- Após o responsável escolher moldar o relevo, criei `Workspace.BR_Peninsula_Draft` no Roblox Studio Edit. A forma inclui costa de areia, terreno de grama, uma crista leste com morros separados por selas e três rotas de terreno em Asphalt; acrescentei um pequeno cruzamento para fechar um intervalo central observado por raycast.
- Posicionei 20 cópias dos previews sanitizados marcados `USAR` na matriz: cais/palmeiras, guindaste e contêineres, prédios urbanos e destruídos, armazém, torre de resfriamento, torre de comunicação e árvores. Os modelos estão organizados em pastas por região.
- Os previews permanecem ancorados e somente visuais, sem colisão/toque/consulta. A matriz continua intacta, os pacotes originais seguem em quarentena e nenhum asset rejeitado foi copiado. Nenhuma geometria de cenário foi criada com Parts.
- Evidência de inspeção no Studio Edit: 20 modelos no rascunho; zero scripts, remotes ou sons sob `BR_Peninsula_Draft`; raycasts confirmaram terreno e superfícies de rota. Capturas visuais foram feitas em vista superior e oblíqua durante a sessão.
- Ainda pendentes: ajustar conexão norte e limite do mapa, auditar/provar os originais, revisar encaixe/escala e colisões, adicionar spawns e validar rotas/interiores em Play. Este rascunho não foi integrado ao gameplay; não executei testes automatizados.

# BR — praia sudoeste em nível do mar — 2026-10-15

- Modelei uma faixa ampla de praia no Roblox Studio usando Terrain nativo, mantendo o restante do rascunho e os assets existentes.
- O trecho fica na costa sudoeste, com cerca de 200 studs ao longo da costa e 160 studs de largura para o interior; a areia começa em Y=3 junto à água e sobe gradualmente até aproximadamente Y=12. A rota costeira de Asphalt foi preservada.
- Captura oblíqua e raycasts no Studio Edit confirmaram o trecho de areia e a transição para o terreno. A praia ainda é um primeiro passe visual; não executei testes nem salvei o place.

# BR — referência visual da península — 2026-10-15

- Registrei a imagem enviada pelo responsável como referência principal de composição: península tropical verde, praia curva e larga na ponta, cidade costeira subindo pelo interior, vias sinuosas e porto/indústria em uma lateral.
- A direção mantém a identidade de batalha concentrando a destruição no complexo militar, porto e setores urbanos específicos. A praia sudoeste existente fica como primeiro trecho de terreno; a próxima passagem deve prolongá-la/ajustá-la para formar uma enseada contínua na ponta.

# BR — correção do relevo por comparação visual — 2026-10-15

- Comparei `tests/relevoatual.png` com `tests/relevoalvo.png` e confirmei o problema: a serra ficava separada por água, o extremo norte afunilava no centro e o miolo verde estava quase plano.
- Atualizei `scripts/studio/sculpt_br_terrain.luau` e apliquei a forma V5 no `Workspace.BR_Peninsula_Draft`: península contínua e mais larga no norte, cadeia montanhosa atravessando a borda de fundo, relevo verde distribuído no interior e dunas ao longo da curva sul.
- Studio Edit completou a geração em cinco faixas de Z. A versão anterior continua recuperável em `ServerStorage.BR_TerrainWorkshop.TerrainBeforeReferencePass`; o relevo intermediário está em `TerrainBeforeMountainWideningV4`. Os 20 modelos visuais seguem em `AssetsAwaitingTerrain`.
- Inspeção visual confirma que a cadeia agora está conectada e se espalha pelo fundo. Não iniciei Play, não salvei/publicei o place e não validei estradas, colisões ou rotas.

# BR — zonas e ruas de asfalto — 2026-10-15

- A câmera do Studio foi recentralizada programaticamente porque a navegação pelo botão direito do mouse estava falhando. A vista oblíqua deixa a península inteira visível para revisão.
- No rascunho separado `Workspace.BR_Peninsula_Draft`, registrei 10 zonas com rótulo, centro e limites aproximados: montanhas ao norte, militar a oeste, cidade central, indústria a leste, porto a sudeste, dunas e praia ao sul.
- Criei uma rede de 11 rotas sinuosas de entrada, acesso/perímetro militar, avenidas urbanas, ligação indústria–porto e arco costeiro sul. A superfície usa `Enum.Material.Asphalt` no Roblox Terrain. Uma primeira pintura foi desfeita após a inspeção visual mostrar falhas; a segunda passada nivelou as pistas em voxels de 4 studs, preservando snapshots V1/V2 antes das alterações.
- Studio Edit retornou 17.603 células superficiais de Asphalt, 5.491 células de terreno niveladas e 1.257 células sobre água ignoradas. A captura oblíqua mostra a rede conectada, embora as bordas permaneçam em degraus de voxel.
- O mapa não foi integrado à arena ativa, não entrou em Play e não foi salvo. Permanecem pendentes inspeção de percurso em nível próximo, ajuste de bordas/curvas e validação de colisão e dirigibilidade.

# BR — correção visual das vias para tráfego — 2026-10-15

- O responsável observou que o asfalto anterior parecia demarcação estreita. Restaurei o snapshot V2 e reconstruí a rede em um novo passe, mantendo somente Roblox Terrain.
- Alarguei as faixas principais para 42–48 studs e ruas secundárias para 30–34 studs, acrescentei acostamentos de concreto nivelados com 6 studs por lado e escureci a cor de Asphalt para carvão. O leito foi regradado em voxels de 4 studs; sem Parts de cenário.
- Studio Edit reportou 22.971 células de asfalto, 6.059 de acostamento, 9.407 células niveladas e 2.175 células de água ignoradas. Raycasts nas avenidas centrais retornaram `Enum.Material.Asphalt`.
- Snapshot anterior preservado em `ServerStorage.BR_TerrainWorkshop.TerrainBeforeRoadNetworkV3`. A pista agora se lê como pavimento largo no enquadramento próximo e funciona como superfície física do Terrain; ainda não executei condução em Play. Bordas de voxel precisam de polimento. O place segue não salvo.

# BR — busca de asset de ruas — 2026-10-15

- Pesquisei modelos gratuitos no Creator Store e comparei as miniaturas de kits de estrada. A primeira opção visual é `Wessel Realistic road pack` (ID `16088161488`): a miniatura mostra módulos retos, curva e travessia; a descrição pública não informa composição detalhada nem scripts. `Modular City Road Set` (ID `1415307242`) fica como alternativa, com trecho reto e cruzamento visíveis, mas descrição mínima.
- Registrei os dois como `DISCOVERED` em `assets/registry.csv` e documentei a triagem em `docs/ASSET_AUDITS/FL-016-assets.md`. Nenhum foi importado, auditado em Studio ou integrado ao rascunho; ambos exigem consentimento explícito para importação de item de outro criador, seguido de quarentena e auditoria.
- O rascunho continua com Terrain Asphalt V5 como referência provisória. Não executei testes, não entrei em Play e não salvei/publicei o place.

# FL-016 — auditoria inicial do kit de ruas e referência de cidade — 2026-10-15

- Após o responsável escolher o candidato recomendado, importei o Wessel Realistic Road Pack (ID `16088161488`) somente para `ServerStorage.BR_TerrainWorkshop.RoadAssetQuarantine`.
- Studio Edit encontrou 26 descendentes: 8 Parts ancoradas/colidíveis, 15 Textures e 3 Decals; nenhum Script, LocalScript, ModuleScript, Remote ou Sound. O importador marcou `sandboxed=false`, sem código executável presente. As imagens usadas pelo pack pertencem a Sir_Trolling (creator ID `30060913`), não ao autor do modelo (`Iamplayingrobloxwes`, ID `1265924414`); manter a procedência/permissão pendente antes de aprovação ou publicação.
- O responsável também forneceu o asset gratuito `Roblox Realistic City` (ID `15928729124`). A busca/miniatura identificam o autor Iamplayingrobloxwes e mostram um bloco denso de edifícios, mas a descrição está vazia; registrei como `DISCOVERED`, sem importar. A auditoria de conteúdo e desempenho segue pendente.
- O asset de ruas permanece na quarentena como fonte; preview de cópias locais continua pendente nesta etapa. Terrain Asphalt V5 continua como referência. Não executei Playtest, não salvei nem publiquei o place.

# FL-016 — estrada Wessel no rascunho e câmera do Studio — 2026-10-15

- Corrigi `scripts/studio/build_br_asset_roads_v7.luau`: os clones agora mantêm as imagens do asset e usam somente a marcação reta `2091416637`, em vez de remover decals/texturas ou alternar aleatoriamente curvas, cruzamentos e faixas de pedestres.
- No `Place1` em Edit, reapliquei a imagem reta aos 629 módulos existentes dentro de `Workspace.BR_Peninsula_Draft.Road_Assets_V7`. Uma captura de perto mostrou pista escura, marcação amarela e borda clara. Os módulos continuam ajustados a segmentos retos; curva/entroncamento, faixa de pedestres e travessia do rio ainda precisam de tratamento próprio.
- Removi os previews temporários. `Workspace.CurrentCamera.CameraType` estava `Scriptable`; restaurei para `Custom`. A captura do MCP redefine esse valor para `Scriptable`, portanto a configuração `Custom` foi reaplicada depois da última captura. A navegação física pelo botão direito ainda depende de confirmação manual do usuário no viewport.
- O asset segue `QUARANTINED`: a permissão das imagens referenciadas pertence a Sir_Trolling e permanece pendente. As cópias estão no rascunho local solicitado; não salvei nem publiquei o place.

# Roblox Studio — navegação da câmera — 2026-10-15

- O responsável relatou que o botão direito do mouse ainda não navega a viewport. Confirmei o Studio em Edit e capturei a vista da península; `Workspace.CurrentCamera.CameraType` estava `Scriptable`, mas isso sozinho não identifica a causa.
- A sessão do controle visual do Windows retornou `apps=[]` e `browsers=[]`; não havia uma janela de Studio disponível para inspecionar ou ajustar preferências pela interface. O MCP do Studio nesta sessão permite alterar o enquadramento/capturar, mas não expõe a configuração de entrada do editor. Não alterei preferências às cegas nem declaro o botão destravado.
- Atalhos oficiais de navegação permanecem disponíveis como alternativa enquanto a UI não pode ser controlada: W/A/S/D, Q/E, F para focar seleção, vírgula/ponto para girar e botão do meio + arraste para pan. Referência: documentação oficial de controles do viewport 3D.

# BR Peninsula — geração Terrain V6 — 2026-10-15

- Atualizei `scripts/studio/sculpt_br_terrain.luau` para ampliar a escala horizontal de 0.8 para 1.0, aprofundar a variação de altitude, adicionar cristas secundárias e mais rocha exposta, e esculpir um rio contínuo do norte pelo centro urbano até a costa leste.
- Reservei 11 footprints planos em `Workspace.BR_Peninsula_Draft.Buildable_Pads`, incluindo duas áreas de cidade separadas pelo rio, zona militar, indústria, porto, praia/dunas, crista natural, mirante e staging dos times. Pastas de metadados não acrescentam Parts ao cenário.
- Reapliquei o asfalto sobre o relevo V6. Evidência no Studio Edit: 23.610 células de asfalto e 6.272 de ombro; raycasts em cinco trechos do rio retornaram Water. A amostragem das áreas planas ficou dentro da tolerância de voxel/estradas (variações locais de até ~4 studs onde as rotas atravessam o footprint).
- Removi também o fallback dos spawns antigos do `ArenaBuilder`; arena versão 5 agora declara `EntryCount=0`. Em Play, `sabugorDemeninas` foi atribuído ao `Spawn_WestEntry` e apareceu no staging plano oeste em `(-700, 104.06, 400)`. Havia somente os dois spawns da ilha. Place1 voltou para Edit.
- Rollbacks: `TerrainBeforeIslandV6`, `TerrainBeforeIslandV6Refinement`, `TerrainBeforeRoadNetworkV6`, `TerrainBeforeRoadNetworkV6Refinement`. Draft segue sem salvar/publicar; travessias de veículos sobre o rio aguardam asset/solução de ponte e o teste de aceitação FL-016 continua pendente.
