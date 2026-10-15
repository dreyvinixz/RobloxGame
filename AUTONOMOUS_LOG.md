# Registro de trabalho autônomo

Atualizado em 2026-10-15. Este registro acompanha as issues abertas #13–#32. `Concluída` exige PR e critérios de aceite atendidos; documentação ou código sem playtest exigido permanece parcial.

| Issue | Estado | PR | Decisão e pendência principal |
|---|---|---|---|
| #13 FL-013 | Parcial | [#43](https://github.com/dreyvinixz/RobloxGame/pull/43) | Direção visual, guia, seleção e procedência registrados; validação estática, 3 testes Python e Rojo build passaram. PR aguarda revisão; assets seguem em quarentena para FL-014. |
| #14 FL-014 | Parcial | [#44](https://github.com/dreyvinixz/RobloxGame/pull/44), PR de aprovação pendente | Aprovados para prototipagem o rifle visual limpo, rig R15 e três props. Studio confirmou 4/31/10 conteúdos carregados; bus stop reposicionado em X=112 e percurso local sem bloqueio. Dependências fora desta experiência local e integração final ficam registradas como limites. |
| #15 FL-015 | Pendente | — | Viewmodel R15 depende do kit aprovado. |
| #16 FL-016 | Parcial | Pendente | Há branch com arena modular nativa; integrar os três props escolhidos sem sobreposição após FL-014. Fachada importada é condicional. |
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
- PR de follow-up usa feat/FL-014-approve-assets sobre a branch de dependência FL-014. A issue permanece aberta até integração na main; FL-016 ainda deve versionar as posições e colisões finais.
