# Registro de trabalho autônomo

Atualizado em 2026-10-15. Este registro acompanha as issues abertas #13–#32. `Concluída` exige PR e critérios de aceite atendidos; documentação ou código sem playtest exigido permanece parcial.

| Issue | Estado | PR | Decisão e pendência principal |
|---|---|---|---|
| #13 FL-013 | Parcial | [#43](https://github.com/dreyvinixz/RobloxGame/pull/43) | Direção visual, guia, seleção e procedência registrados; validação estática, 3 testes Python e Rojo build passaram. PR #43 foi integrado à branch FL-012; a pilha ainda aguarda integração à `main`. |
| #14 FL-014 | Parcial | [#44](https://github.com/dreyvinixz/RobloxGame/pull/44), [#45](https://github.com/dreyvinixz/RobloxGame/pull/45) | Aprovados para prototipagem o rifle visual limpo, rig R15 e três props. Studio confirmou 4/31/10 conteúdos carregados; bus stop reposicionado em X=112 e percurso local sem bloqueio. PR #45 está aberto sobre a branch de dependência; integração final e permissões fora desta experiência local permanecem pendentes. |
| #15 FL-015 | Parcial | [#46](https://github.com/dreyvinixz/RobloxGame/pull/46) | Viewmodel local R15, rifle visual limpo, recuo/recarga client-side; validator, 3 testes e Rojo build passaram. Captura confirmou sightline em repouso. Inspeção de quadros de animação e confirmação inequívoca do respawn seguem pendentes. PR draft empilhado em #14. |
| #16 FL-016 | Parcial | [#47](https://github.com/dreyvinixz/RobloxGame/pull/47) | Gerador modular preserva três rotas e núcleos colidíveis; trio urbano aprovado foi integrado como visual ancorado, sem colisão. Studio Play confirmou 3 props, 3 marcadores, zero AABB overlaps com colisores e navegação pelas rotas. PR aberto sobre FL-015; revisão e integração da pilha pendentes. |
| #17 FL-017 | Pendente | — | Medir arena persistida em hardware-alvo. |
| #18 FL-018 | Pendente | — | Equipes, spawns e placar. |
| #19 FL-019 | Pendente | — | QA multiplayer e exploração de remotes. |
| #20 FL-020 | Pendente | — | Pistola e balanceamento inicial. |
| #21 FL-021 | Pendente | — | Cobertura destrutível com estado replicado. |
| #22 FL-022 | Pendente | — | HUD de equipe, munição e resultado. |
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
