# Direção de arte — FL-013

**Estado:** direção aprovada pelo proprietário; dois assets gratuitos importados para quarentena no Studio. A auditoria estática e um benchmark exploratório com cópias temporárias foram feitos. O percurso inicial foi validado pelo proprietário após corrigir sobreposições; a composição final e as permissões das dependências ainda precisam de validação.

**Data da consulta ao Creator Store:** 2026-10-15.
**Objetivo aprovado:** FPS militar urbano contemporâneo, original, legível e compatível com a escala Roblox. Sem reproduzir marcas, mapas, uniformes ou trade dress identificável de Battlefield.

## Moodboard próprio

Conceito: rua urbana compacta vista ao nível do jogador, fachadas modulares de concreto e metal pintado, asfalto gasto, cobertura de leitura clara e sinalização funcional. Luz diurna nublada, contraste controlado e saturação baixa; pontos de interação usam âmbar discreto. Silhuetas de personagens e alvos permanecem distintas do fundo.

![Moodboard original de Project Frontline](art_direction_moodboard.svg)

Paleta inicial: concreto `#77766F`, asfalto `#373B3E`, aço escuro `#46535B`, olive `#60634D`, poeira `#A79572` e sinalização âmbar `#C28B49`. São amostras próprias para o protótipo, não cores extraídas de outra franquia.

## Comparação de coleções

Contagens são as mostradas nas páginas públicas do Creator Store na data acima. São metadados dos pacotes inteiros, não previsão de desempenho do subconjunto que poderia entrar no mapa.

| Coleção | Autor/listagem | Dados publicados | Licença/preço observado | Avaliação para Frontline |
|---|---|---|---|---|
| [Modular Building Kit — Modern City](https://create.roblox.com/store/asset/13168370735/Modular-Building-Kit-Modern-City) | `@Roblox` | 796.055 triângulos, 3.025 MeshParts, 36 decals, 4 áudios e 8 scripts | Get Model no Creator Store; seguir os termos vigentes e conferir dependências | Modular e útil como referência, mas o pacote inteiro excede o orçamento preliminar e os scripts exigem auditoria; não selecionar completo. |
| [Synty City Pack](https://create.roblox.com/store/asset/6933556508/Synty-City-Pack) | `@Roblox` | 256.709 triângulos e 332 MeshParts | Get Model no Creator Store; descrição informa licença da versão Roblox para uso em jogos Roblox; confirmar dependências e termos no momento da ingestão | Escala moderada, conteúdo modular e estilo low-poly consistente; destoa da direção de realismo estilizado contemporâneo. Manter como alternativa estilizada, sem aprovação. |
| [New York City Corner Apartment Building](https://create.roblox.com/store/asset/14243660153/New-York-City-Corner-Apartment-Building) | `@Lihtsameelseke` | A listagem não expõe contagem de triângulos, MeshParts ou scripts | Get Model gratuito; Creator Store ToU aplicam-se; confirmar permissões das dependências na ingestão | **Escolhido pelo proprietário para inspeção.** Fachada urbana compatível com a direção; a auditoria e o teste exploratório no Studio estão registrados abaixo. Candidato a um único setor, condicionado à otimização e ao gate de assets. |
| [City Props Pack](https://create.roblox.com/store/asset/6370681139) | `@Roblox` | 66.318 triângulos, 94 MeshParts e 2 scripts; inclui props urbanos e materiais PBR | Get Model gratuito; Creator Store ToU aplicam-se; confirmar permissões das dependências na ingestão | **Escolhido pelo proprietário para inspeção.** Três props sem scripts foram escolhidos para o primeiro lote; os scripts do pacote permanecem desativados. |
| [Realistic Urban City](https://create.roblox.com/store/asset/95798439683690/Realistic-Urban-City) | `@2XQUISITE_DESIGNS` | 23.119 triângulos, 45 MeshParts e 11 decals; a página não informa contagem de scripts | US$ 3,99 na consulta; não cabe no orçamento disponível | Descartado pelo proprietário por ser pago. Não comprar nem usar. |

O Creator Store informa distribuidor, tipo, descrição e dados técnicos quando disponíveis; alguns modelos incluem scripts. A política da Roblox exige aderência aos Termos de Uso e recomenda auditoria antes do uso.

## Auditoria inicial no Studio — 2026-10-15

Os dois itens escolhidos pelo proprietário foram inseridos em `ServerStorage.FL013_Quarantine`; nenhum foi colocado na arena final. O Studio inseriu o apartamento com scripts sandboxed (não havia scripts) e o pacote de props sem sandbox. Os dois scripts do pacote de props foram lidos, desativados e mantidos sem execução na quarentena.

| Asset | Estrutura observada no Studio | Código/dependências | Resultado até aqui |
|---|---|---|---|
| New York City Corner Apartment Building (14243660153) | 10.427 descendentes; 2.568 `BasePart`, 59 `UnionOperation`; zero `MeshPart`; todas as 2.568 peças estavam `Anchored=false` e `CanCollide=true`. | Zero Script, LocalScript ou ModuleScript. | Quarentena mantida. Uma cópia ancorada foi testada na arena, com percurso inicial validado após ajustes; ancoragem/colisão da versão definitiva e teste em hardware-alvo permanecem pendentes. A complexidade de instâncias é alta para uma fachada única. |
| City Props Pack (6370681139) | 219 descendentes; 100 `BasePart` (94 `MeshPart`, 1 UnionOperation); 56 peças com colisão; 98 ancoradas e 2 não ancoradas. | Dois Scripts `LightStateChanger`; leitura estática não encontrou `require`, HTTP, `loadstring`, DataStore, InsertService, MarketplaceService ou remotes. Usam filhos/atributos locais. Podem falhar se `PrimaryPart` ou `LightChanged` não existir. Ambos desativados; não executados. | Quarentena mantida. Cópia temporária ancorada e sem colisão foi usada apenas no benchmark e removida depois. Escolher props individuais e validar colisão antes de uso. |

### Benchmark exploratório

Playtest de cliente no Studio, 1 jogador, amostras de 5 segundos, mesma máquina/sessão. Base sem a cópia temporária: 118,2 FPS médios, 26.560 triângulos visíveis (13.304 opacos + 13.256 sombras), 24 draw calls e 1.845 MB reportados pelo `Stats`. Com a cópia do City Props Pack: 116,0 FPS médios, 35.984 triângulos visíveis (16.884 opacos + 192 UI + 18.908 sombras), 40 draw calls e 1.799 MB reportados. Os números de memória oscilaram entre amostras e não demonstram economia; esta medição curta é exploratória e não representa dispositivos mais fracos nem o apartamento.

Depois, os assets foram preparados na `GreyboxArena` gerada pelo bootstrap: a fachada ancorada substituiu o bloco norte-oeste e seis props sem scripts foram posicionados nas rotas. Cópias de teste somente. Em outra amostra de 5 segundos: 118,6 FPS médios e 1.922 MB reportados; `SceneAnalysisService` registrou 202.610 triângulos/113 draws incluindo sombras, dos quais 29.058 triângulos opacos/19 draws são geometria visível sob controle do criador. A medição ficou próxima do limite de 120 FPS desta sessão, mas não prova desempenho em hardware mais fraco. O proprietário validou o percurso inicial e apontou sobreposições, corrigidas na sessão de teste descrita abaixo.

Na inspeção do proprietário, três props apareciam sobrepostos aos blocos/cobertura. Na cópia de teste, o ponto de ônibus e o quiosque foram deslocados de X=92 para X=112, e a lixeira de X=12 para X=8. Uma verificação AABB de peças colidíveis encontrou zero sobreposições entre os seis assets e blocos, coberturas ou paredes de entrada; também encontrou zero interseções entre assets distintos. Essas posições foram alteradas no runtime do playtest e precisam ser reaplicadas na implementação de FL-016; não tratar a sessão temporária como conteúdo persistido do mapa.

O usuário relatou anteriormente 60 FPS e 1,6 GB no greybox, mas a cena/método não é comparável diretamente com este teste. Não se conclui que o pacote inteiro passou no orçamento. O Output não mostrou erros de scripts do projeto; houve avisos do CorePackages/Roblox UI (`FoundationProvider not found`), repetidos durante a inicialização.

Os dois assets permanecem `QUARANTINED`, não aprovados para a arena. A documentação do Creator Store permite usar itens adquiridos em projetos Roblox, mas dependências restritas podem exigir permissão própria; conferir isso no Studio antes da promoção. Próximos gates: definir a colisão final da fachada, persistir posições na fonte, confirmar permissões incorporadas e medir a composição definitiva em hardware-alvo.

## Seleção proposta para o primeiro lote da arena

Primeiro lote escolhido: três props do pacote urbano. A fachada é um quarto candidato, para **um único setor** após otimização e aprovação no gate FL-014. Não espalhar o pacote inteiro pelo mapa:

| Seleção inicial | Função na arena | Regras de posicionamento |
|---|---|---|
| `StreetLightPole_01_A` | Silhueta e escala de rua | Um exemplar na borda norte; conferir folga para o jogador e linha de tiro. |
| `Bus_Stop_01_A` | Referência urbana visível | Um exemplar no passeio leste, fora da caixa do bloco e da cobertura; usar X=112 apenas como ponto de partida do teste anterior, sujeito a conferência no layout atual. |
| `FireHydrant_01_A` | Detalhe urbano pequeno | Um exemplar em canto de rua, fora das três rotas e das duas entradas. |
| `New York City Corner Apartment Building` (condicional, um exemplar) | Marco visual do setor noroeste | Substituir a aparência do setor `Building_-76_-66`, nunca empilhar com a fachada modular existente; ancorar e simplificar colisões antes de promover. |

Deixar banco, lixeira, quiosque, postes elétricos e demais variações para uma segunda revisão de densidade visual. Excluir `Traffic_Light_01/02` do primeiro lote: têm scripts que continuam desativados e não são necessários para o fluxo da arena.

## Etapas sugeridas para FL-016

1. Na branch da FL-016, partir da arena modular já implementada: registrar a posição, tamanho e caixa de colisão de `Building_-76_-66` e um baseline de desempenho.
2. Após o gate FL-014, adicionar primeiro apenas poste, ponto de ônibus e hidrante. Posicionar cada exemplar fora de `BuildingCore`, `CoverModules`, rotas e entradas; guardar posição e orientação em fonte versionada, sem depender de uma cópia temporária no Play.
3. Para a fachada candidata, remover **somente os módulos visuais** do setor noroeste antes de posicionar o apartamento. Manter o núcleo colidível até definir uma colisão equivalente; não deixar peças importadas colidindo sobre o núcleo ou criar barreiras invisíveis fora da fachada.
4. Comparar as três rotas e duas entradas antes/depois. Verificar passagens, raycasts, colisões e interseções com cobertura. Usar AABB como triagem, seguida de playtest, porque AABB não detecta toda colisão percebida pelo jogador.
5. Conferir scripts desativados, permissões de malhas/texturas e orçamento de instâncias. Se a fachada não passar, manter os módulos nativos da FL-016 e adiar só esse exemplar, sem bloquear os três props.
6. Capturar vista antes/depois e executar FL-017 com a arena persistida para medir FPS, memória, triângulos e draw calls em hardware-alvo.

## Qualidade e orçamento preliminares

Direção proposta: **realismo estilizado contido**. Manter formas, escala e desgaste reconhecíveis, simplificar pequenos detalhes para leitura em movimento e repetir módulos com variações de cor autorizadas.

| Classe | Triângulos estimados por asset | Geometria | Texturas propostas |
|---|---:|---:|---|
| Prop pequeno (cone, caixa, placa) | até 3.000 | até 2 MeshParts | atlas compartilhado até 512² |
| Módulo urbano reutilizável | até 10.000 | até 4 MeshParts | até 2 mapas 1024² compartilhados pelo kit |
| Elemento de destaque | até 25.000 | até 8 MeshParts | até 2 mapas 1024²; usar com parcimônia |
| Cena visível da arena inicial | alvo provisório até 250.000 no total | alvo provisório até 300 MeshParts | reusar atlas/material sempre que possível |

Os limites por asset continuam **hipóteses de trabalho**, não resultados medidos. No baseline de greybox informado pelo proprietário para a FL-012 foram observados 60 FPS e 1,6 GB de memória; isso não mede o impacto dos novos assets. Comparar novamente no Studio após inserir os itens em quarentena e remover qualquer peça/scripts desnecessários. A meta de 60 FPS desktop é inicial e deve ser avaliada em hardware semelhante ao do playtest.

## Guia de materiais

- Concreto: `Concrete` ou superfície PBR moderada; variação sutil, sem ruído fino que prejudique a silhueta.
- Asfalto: cinza carvão fosco, marcação viária esparsa e contraste suficiente para leitura das rotas.
- Metal pintado: azul-aço/olive dessaturado, roughness alto e desgaste localizado.
- Vidro: uso limitado; evitar transparência e reflexos em fachadas sem função de gameplay.
- Sinalização: âmbar e branco apenas para navegação/interação; preservar o contraste entre equipes quando elas forem implementadas.

## Gate de seleção e ingestão

1. Registrar o baseline greybox da FL-012: 60 FPS e 1,6 GB, conforme relato do proprietário; comparar após a auditoria no Studio.
2. Conferir na inserção o autor, Get Model, permissões e termos vigentes dos dois assets escolhidos.
3. Inserir somente em um lugar/cena de quarentena; inspecionar descendentes, scripts, dependências, meshes, texturas, colisões e escala antes de habilitar código.
4. Harmonizar os props selecionados com a paleta e os materiais da direção visual.
5. Registrar evidência no `assets/registry.csv`; só marcar `APPROVED` depois da revisão e do teste de desempenho. O pacote pago está descartado por falta de orçamento.

## Fontes

- [Roblox Creator Store — documentação e segurança de assets](https://create.roblox.com/docs/production/creator-store)
- [Roblox — montagem de ambientes modulares](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments)
- [New York City Corner Apartment Building — Creator Store](https://create.roblox.com/store/asset/14243660153/New-York-City-Corner-Apartment-Building)
- [City Props Pack — Creator Store](https://create.roblox.com/store/asset/6370681139)

## Primeira arena de batalha — FrontlineArena

A próxima composição substitui o greybox por um distrito urbano compacto sob cerco: três corredores de combate conectados por cruzamentos, fachadas parcialmente abertas para combate e flanqueio, barricadas nas rotas, destroços junto às entradas e fumaça apenas no horizonte. A geometria de colisão fica explícita e separada dos detalhes visuais; spawns continuam nas extremidades opostas.

O ambiente usa formas, paleta e disposição originais do Project Frontline. A referência geral de atmosfera é a variedade de cenários urbanos danificados e campos de batalha descrita na [página de mapas de Battlefield 6](https://www.ea.com/pt-br/games/battlefield/battlefield-6/features/maps); nenhum mapa, nome, layout, asset ou marca da EA é reutilizado. A arena é composta por geometria própria em escala de distrito: quatro estruturas de ruína com interior e brechas jogáveis, três corredores conectados, linhas de defesa, posto avançado, crateramento, barricadas, veículos destruídos e fumaça de horizonte. O trio `StreetLightPole_01_A`, `Bus_Stop_01_A` e `FireHydrant_01_A` funciona como detalhe ambiental dentro dessa composição, não como substituto do mapa. Os mapas completos recém-descobertos permanecem fora da arena até revisão de scripts, desempenho e direitos.
