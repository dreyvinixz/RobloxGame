# Registro de trabalho autônomo

Atualizado em 2026-10-15. Este registro acompanha as issues abertas #13–#32. `Concluída` exige PR e critérios de aceite atendidos; documentação ou código sem playtest exigido permanece parcial.

| Issue | Estado | PR | Decisão e pendência principal |
|---|---|---|---|
| #13 FL-013 | Parcial | [#43](https://github.com/dreyvinixz/RobloxGame/pull/43) | Direção visual, guia, seleção e procedência registrados; validação estática, 3 testes Python e Rojo build passaram. PR #43 foi integrado à branch FL-012; a pilha ainda aguarda integração à `main`. |
| #14 FL-014 | Parcial | [#44](https://github.com/dreyvinixz/RobloxGame/pull/44), [#45](https://github.com/dreyvinixz/RobloxGame/pull/45) | Aprovados para prototipagem o rifle visual limpo, rig R15 e três props. Studio confirmou 4/31/10 conteúdos carregados; bus stop reposicionado em X=112 e percurso local sem bloqueio. PR #45 está aberto sobre a branch de dependência; integração final e permissões fora desta experiência local permanecem pendentes. |
| #15 FL-015 | Parcial | [#46](https://github.com/dreyvinixz/RobloxGame/pull/46) | Viewmodel local R15, rifle visual limpo, recuo/recarga client-side; validator, 3 testes e Rojo build passaram. Captura confirmou sightline em repouso. Inspeção de quadros de animação e confirmação inequívoca do respawn seguem pendentes. PR draft empilhado em #14. |
| #16 FL-016 | Parcial | [#47](https://github.com/dreyvinixz/RobloxGame/pull/47) | Gerador modular preserva três rotas e núcleos colidíveis; trio urbano aprovado foi integrado como visual ancorado, sem colisão. Studio Play confirmou 3 props, 3 marcadores, zero AABB overlaps com colisores e navegação pelas rotas. PR aberto sobre FL-015; revisão e integração da pilha pendentes. |
| #17 FL-017 | Parcial | [#48](https://github.com/dreyvinixz/RobloxGame/pull/48) | Baseline Studio local medida em host identificado (i5-11400H, GTX 1650 Max-Q disponível, 16 GB). FPS/memória/render/geom./rede/load documentados sem extrapolar. PR draft; confirmar que este é hardware-alvo e repetir no cliente standalone antes de definir orçamento. |
| #18 FL-018 | Parcial | [#49](https://github.com/dreyvinixz/RobloxGame/pull/49) | Dois clientes simulados validaram FireWeapon→DamageService→MatchService, equipes, placar, respawn e proteção. Transição por tempo/score-win não foi acelerada no teste; revisão e integração empilhada pendentes. |
| #19 FL-019 | Parcial | [#50](https://github.com/dreyvinixz/RobloxGame/pull/50) | Dois clientes confirmaram dano válido, score inalterado em hit não letal e 2 respostas a 50 pedidos de reload. Isolamento runtime de HP e comparação simultânea entre clientes pendentes. |
| #20 FL-020 | Parcial | [#51](https://github.com/dreyvinixz/RobloxGame/pull/51) | Rifle/pistola, troca validada, munição por arma e falloff implementados; validator, 3 testes e Rojo build passaram. TTK é aritmético; teste Studio de equip/munição/falloff e comparação de tempos ainda pendente devido a sync desconectado. |
| #21 FL-021 | Parcial | [#52](https://github.com/dreyvinixz/RobloxGame/pull/52) | Estado Intact/Damaged/Destroyed, 100 HP, dano somente por tiro validado server-side, visibilidade/colisão em estado quebrado implementados. Validator, 3 testes e Rojo build passaram. Multiplayer, tentativa de destruição client-side e late join ainda sem evidência Studio. |
| #22 FL-022 | Parcial | [#53](https://github.com/dreyvinixz/RobloxGame/pull/53) | Capturas Studio Device Simulator em iPhone 17 Pro (874×402) e iPhone 7 (667×375) mostram HP, placar, estado e munição no estado Waiting. Corrigi status de rodada truncado e sobreposição da munição com pulo touch; posições confirmadas sem overlap no viewport 666×374. Contagem ativa e painel de resultado ainda sem captura. Validator, 3 testes e Rojo build passam. |
| #23 FL-023 | Pendente | — | Aceite do MVP com dois clientes. |
| #24 FL-024 | Pendente | — | Protótipo de veículo após MVP. |
| #25 FL-025 | Pendente | — | Dano e regra de veículo. |
| #26 FL-026 | Pendente | — | Profiling posterior aos cenários e veículos. |
| #27 FL-027 | Pendente | — | Checklist alpha; publicação Roblox requer autorização humana. |
| #28 FL-028 | Pendente | — | Pesquisa de extensões oficiais. |
| #29 FL-029 | Pendente | — | Bots depois do MVP. |
| #30 FL-030 | Pendente | — | Segundo mapa após alpha. |
| #31 FL-031 | Pendente | — | Áudio e efeitos após alpha. |
| #32 FL-032 | Pendente | — | Controles mobile e teste em aparelho real. |

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

- Revisão de `FireWeapon`: chaves exatas, vetores finitos, arma permitida, direção unitária e coerente com alvo, alcance, origem próxima à cabeça, cooldown e rejeição de argumentos extras. Dano permanece calculado por configuração do servidor.
- Teste Studio sincronizado com servidor e dois clientes: `PASS | fire validation, valid damage and reload spam throttle | reload responses=2`. Dano válido aplicado, score não alterado em hit não letal; 50 pedidos de reload geraram duas respostas WeaponState.
- O teste não capturou HP entre requisições inválidas e o tiro válido nem comparou HP simultaneamente entre clientes. A simulação não variou latência real.
- Tentativas posteriores com snapshot de HP foram excluídas: Rojo desconectou e Studio executou o harness anterior. Scripts temporários foram removidos do root e não estão no branch.
- `DamageService` limita reload a um pedido por 0.25 s/jogador e limpa o relógio ao sair. Critérios pendentes e limites em `docs/TEST_REPORTS/FL-019.md`. PR draft #50 empilhado sobre FL-018.

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

## Implementação parcial da FL-020 — 2026-10-15

- `WeaponConfig` agora tem rifle e pistola com dano, cadência, munição, reload, alcance, multiplicador de headshot e falloff linear. `DamageService` aplica a queda por distância real do raycast, e cada arma mantém pente/reload próprio no servidor.
- O cliente solicita troca em 1/2. `CombatRequestService` permite apenas IDs configurados, exige arma selecionada e limita frequência de tiro/troca no servidor.
- Números e TTK calculados em `docs/WEAPONS.md`; relatório `docs/TEST_REPORTS/FL-020.md` distingue cálculo de medição.
- Validator, 3 testes Python, Rojo build e diff check passaram. Falta teste Studio de equip, munição, falloff e TTK medido com dois clientes; nenhum resultado de gameplay é alegado.
- PR draft #51 empilhado sobre FL-019.
