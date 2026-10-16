# FL-016 — fila de seleção de assets

**Objetivo desta etapa:** apresentar candidatos para decisão visual do responsável. **Não é o mapa.** Nenhum item desta lista está aprovado para composição ou gameplay. Os links e miniaturas vêm do Creator Store; anúncios grátis não equivalem a auditoria de scripts, dependências, colisão ou licença.

## Grade no Roblox Studio

A fila visual em Workspace.FL016_AssetSelectionQueue tem 27 linhas e 109 candidatos, agrupados por classe. As colunas A–E usam X=4700/4820/4940/5060/5180; a linha de entrada costeira usa também F em X=5300. As linhas avançam 150 studs em Z; todos os modelos estão centrados por coluna e apoiados no plano Y=0. A galeria contém previews estáticos, sem colisão, toque, consulta, scripts, remotes ou sons; originais ficam em ServerStorage.FL016_Quarantine. Consulte a seção final para status e ordem atual.

### Prédios urbanos adicionados para identificação

Os seis prédios urbanos estão agora nas linhas 18 e 19, após a inclusão das classes de costa, contêineres e usinas.

| Linha/coluna | Candidato | ID Creator Store | Geometria importada | Observações de triagem |
|---|---|---:|---:|---|
| 11/A | Russian House Concrete Building | 88039488925510 | 132 Parts | O pacote importado contém scripts, remotes e sons; foram removidos da cópia visual e os scripts na quarentena foram desativados. |
| 11/B | 6 Story Tall Building | 10119766796 | 48 Parts | Importado como Folder; a cópia visual foi agrupada em Model. |
| 11/C | Russian Panel House | 1861426455 | 157 Parts | Construção urbana 3D. |
| 11/D | Apartment Complex | 4602943220 | 110 Parts | Construção urbana 3D. |
| 12/A | 9 Floor Panel House | 85499820929309 | 841 Parts | Construção urbana 3D de grande porte, reduzida para a visualização. |
| 12/B | Ruined Apartment Building | 140469134856396 | 966 Parts | O pacote importado contém scripts, remotes e sons; foram removidos da cópia visual e os scripts na quarentena foram desativados. |

Esses candidatos são prédios com geometria 3D visível, ao contrário da fachada `101776749239326`, que permanece identificada somente como limite/fundo. A visualização não comprova portas, interior, colisão pronta para gameplay, licença ou segurança dos pacotes originais. Nenhum prédio foi integrado à arena ou aprovado para uso.

### Hangar, prédios com interior e fluxo FPS — 2026-10-15

Quatro fileiras adicionais foram inseridas para aproximar a avaliação do combate em espaços internos, com corredores, cobertura e entrada. Cada cópia está alinhada no mesmo piso da matriz; os originais seguem na quarentena. A listagem do Creator Store foi usada para encontrar candidatos grátis, mas o nome do asset não comprova acesso, navegação ou colisão. Para afirmar que um jogador consegue entrar e combater, ainda será necessário testar o original em Play depois da seleção.

| Linha/coluna | Candidato | ID | Evidência inicial | Observações |
|---|---|---:|---|---|
| 13/A | Hangar | 6015472062 | 1679 Parts; pacote sem scripts/remotes/sons encontrados | Hangar amplo, reduzido na grade para caber no suporte. |
| 13/B | Hangar Militar | 14842712615 | 16 Parts; sem scripts/remotes/sons encontrados | O criador o descreve como tentativa de hangar militar. |
| 13/C | Military Garage Army Base Hangar | 76113270011762 | 29 Parts; 1 script | Script desativado na quarentena e omitido da cópia visual. |
| 13/D | Hangar and SR-74 Blackbird | 3250623014 | 1970 Parts; 34 scripts, 2 remotes, 29 sons | Código e áudio removidos da cópia visual; script desativado na quarentena. Inclui aeronave no pacote, não aprovada para jogo. |
| 14/A | Apartment Building With Interior | 13642086765 | 1490 Parts; sem scripts/remotes/sons encontrados | Candidato de prédio alto com interior indicado pelo título. A circulação ainda não foi testada. |
| 14/B | Destroyed Apartment Building Interior | 125279267672905 | 887 Parts; 3 scripts, 4 sons | Scripts desativados na quarentena; scripts e sons omitidos da cópia visual. |
| 14/C | Warehouse + Interior | 14663659526 | 156 Parts; sem scripts/remotes/sons encontrados | O criador afirma que construiu o modelo para o próprio jogo; testar passagens e colisão antes de aprovar. |
| 14/D | Paintball Arena FPS Layout — referência | 72990217 | 304 Parts; 8 scripts, 4 sons | Somente referência de fluxo FPS; scripts desativados e scripts/sons omitidos da cópia visual. A estética pode não combinar com o mapa de guerra. |

Os oito modelos estão agora em 20_HANGARS_GARAGES (Z=2850) e 21_ENTERABLE_INTERIORS_FPS (Z=3000). O preview é estático e sem colisão para comparar as formas com segurança; ele não é um playtest. Ainda não foi escolhido um edifício para o mapa.

### Pontes, rapel, radar e comunicação — 2026-10-15

Quatro novas fileiras, com quatro candidatos cada, respondem à solicitação de infraestrutura e travessia. Todos foram encontrados como grátis no Creator Store e permanecem sem aprovação para uso no mapa.

| Linha/coluna | Candidato | ID | Inventário importado | Triagem |
|---|---|---:|---|---|
| 15/A | Earthquake Disaster Bridge | 129024855766897 | 2805 Parts, 1 som | Sem scripts; modelo muito grande e foi reduzido para a grade. |
| 15/B | Freeway Bridge Defense Gun Tower Post | 98380349367763 | 1105 Parts, 18 scripts, 16 sons | Scripts desativados na quarentena; código e áudio omitidos do preview. |
| 15/C | Bridge | 13215638477 | 313 Parts | Sem scripts/remotes/sons encontrados. |
| 15/D | Rope Bridge Metal Bridge Long Pack | 98094663411092 | 1 Part, 1 script | Script desativado na quarentena e omitido do preview. |
| 16/A | Shadow Company Rappelling | 4613367475 | 602 Parts, 56 scripts, 66 remotes, 42 sons | Conteúdo executável e áudio removidos do preview; scripts desativados. Requer auditoria cuidadosa antes de qualquer uso. |
| 16/B | Military Watch Tower Sniper Guard Lookout Base | 130354815851056 | 48 Parts, 2 scripts, 1 remote, 1 som | Script desativado; script, remote e som omitidos do preview. |
| 16/C | Military Tower Barracks Base | 97201215024929 | 167 Parts, 1 script | Script desativado e omitido do preview. |
| 16/D | Military Tower Training Base | 100553654243180 | 167 Parts, 1 script | Script desativado e omitido do preview. |
| 17/A | SN-75 Radar | 2970964501 | 3 Parts | Sem scripts/remotes/sons encontrados. |
| 17/B | Radar 3.0 | 775402107 | 150 Parts, 3 scripts | Scripts desativados e omitidos; descrição do autor afirma que o radar gira. |
| 17/C | Warzone 2100 Radar Pole | 31283981 | 34 Parts, 111 scripts | Scripts desativados e omitidos; contagem alta de scripts exige cautela. |
| 17/D | Radar | 11780164349 | 42 Parts, 6 scripts | Scripts desativados e omitidos do preview. |
| 18/A | Radio Tower Signal Broadcast Communication Antenna | 101494976675821 | 240 Parts, 1 script | Script desativado e omitido do preview. |
| 18/B | Radio Tower Antenna Communication Broadcast | 130963030570923 | 1 Part, 1 script | Script desativado e omitido do preview. |
| 18/C | Radio Antenna | 3544844428 | 1 Part | Sem scripts/remotes/sons encontrados. |
| 18/D | Radio Tower | 4890063517 | 46 Parts | Sem scripts/remotes/sons encontrados. |

As fileiras estão agora em 22_BRIDGES (Z=3150), 23_RAPEL_VERTICAL_ACCESS (Z=3300), 24_RADAR_SURVEILLANCE (Z=3450) e 25_COMMUNICATION_ANTENNAS (Z=3600). Árvores e vegetação estão nas linhas 26 e 27. A fila de rapel não implementa a mecânica, e nenhum modelo foi testado com personagem ou travessia. O preview completo tem 27.591 peças visuais e não contém scripts, remotes ou sons.

Marque cada candidato como **USAR**, **NÃO USAR** ou **REVISAR**. A tabela abaixo registra nomes e fontes usados na pesquisa; para localizar itens no Studio, use o índice atual da matriz, documentado na atualização ao final deste arquivo.

| Categoria | A | B | C | D | Decisão |
|---|---|---|---|---|---|
| Prédios e ruínas | [![Casa destruída](https://thumbnails.roblox.com/v1/assets?assetIds=108330797499958&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/108330797499958) **Casa destruída** · 108330797499958 · Nugisafa62 · anúncio diz 110 Parts/26 meshes, sem scripts | [![Hotel destruído](https://thumbnails.roblox.com/v1/assets?assetIds=12645160489&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/12645160489) **Hotel destruído** · 12645160489 · Sherm_boi10alt · descrição menciona debris/rain | [![Destroyed Building](https://thumbnails.roblox.com/v1/assets?assetIds=101776749239326&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/101776749239326) **Ruined Building** · 101776749239326 · Roblox · 1 MeshPart; apenas limite/fundo, não prédio interativo | **Outposts existentes** · WW2 Map em quarentena · três cópias 3D no rascunho; pequenos, não substituem edifícios urbanos | — |
| Canhões / artilharia | [![Howitzer M3](https://thumbnails.roblox.com/v1/assets?assetIds=77886891095419&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/77886891095419) **105 mm Howitzer M3** · 77886891095419 · lospakos · 3 variantes segundo anúncio | [![Denian cannon](https://thumbnails.roblox.com/v1/assets?assetIds=110566587&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/110566587) **Artillery Cannon** · 110566587 · DenianWriter | [![Soviet artillery](https://thumbnails.roblox.com/v1/assets?assetIds=112246470593728&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/112246470593728) **Soviet 122 mm** · 112246470593728 · Roblox · anúncio indica scripts/sounds | [![RDA artillery](https://thumbnails.roblox.com/v1/assets?assetIds=117111940812317&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/117111940812317) **RDA Cannon** · 117111940812317 · Roblox · anúncio indica scripts/sounds | — |
| Jatos | [![Military Fighter Jet](https://thumbnails.roblox.com/v1/assets?assetIds=269851726&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/269851726) **Military Fighter Jet** · 269851726 · CanadianTwister | [![F18](https://thumbnails.roblox.com/v1/assets?assetIds=104402725931120&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/104402725931120) **F/A-18E Super Hornet** · 104402725931120 · socoolcool54 | [![F16](https://thumbnails.roblox.com/v1/assets?assetIds=84781556749139&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/84781556749139) **F-16C Falcon** · 84781556749139 · XzPixelatedvhEchoXth | [![Su57](https://thumbnails.roblox.com/v1/assets?assetIds=140181341523480&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/140181341523480) **Russian fighter** · 140181341523480 · Keen_Tiger05977 | — |
| Aviões / helicópteros | [![Military plane](https://thumbnails.roblox.com/v1/assets?assetIds=96519172760929&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/96519172760929) **Military Plane Mission Combat** · 96519172760929 · XxAlphaRiftxX | [![Helicopter](https://thumbnails.roblox.com/v1/assets?assetIds=92603397203677&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/92603397203677) **Military Helicopter** · 92603397203677 · gyasfarasd · anunciado como pilotável | [![Rescue helicopter](https://thumbnails.roblox.com/v1/assets?assetIds=276809993&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/276809993) **Rescue Helicopter** · 276809993 · Z.R.S. | [![Crashed heli](https://thumbnails.roblox.com/v1/assets?assetIds=33200186&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/33200186) **Crashed Heli** · 33200186 · march900 | — |
| Armas | [![M24](https://thumbnails.roblox.com/v1/assets?assetIds=77862801167785&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/77862801167785) **M24 Sniper Rifle** · 77862801167785 · NightNOFlameSOCyber1 | [![SIG MCX](https://thumbnails.roblox.com/v1/assets?assetIds=102940291795125&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/102940291795125) **SIG MCX Virtus** · 102940291795125 · SnarerpGlitchPpNebul | [![Working assault rifle](https://thumbnails.roblox.com/v1/assets?assetIds=96118849856247&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/96118849856247) **Working Assault Rifle** · 96118849856247 · Starry20SkyB94 · funcionalidade não avaliada | **Rifle visual FL-014** · protótipo já auditado no Studio; conferir `docs/ASSET_AUDITS/FL-014-kit.md` | — |
| Foguetes / lançadores | [![RPG](https://thumbnails.roblox.com/v1/assets?assetIds=101038708623103&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/101038708623103) **RPG-7** · 101038708623103 · Roblox · anúncio indica 19 meshes, sem scripts | [![RPG-7](https://thumbnails.roblox.com/v1/assets?assetIds=125738401418633&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/125738401418633) **RPG-7 low-part** · 125738401418633 · Roblox · anúncio indica 2 meshes, sem scripts | [![Missile truck](https://thumbnails.roblox.com/v1/assets?assetIds=113323794179360&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/113323794179360) **Missile Truck** · 113323794179360 · NeonylGhostHlNightfa | [![Bunker buster](https://thumbnails.roblox.com/v1/assets?assetIds=103861481921692&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/103861481921692) **Bunker Buster Launcher** · 103861481921692 · StarryNvVantaL1032 | — |
| Tanques / blindados | [![Tank destroyer](https://thumbnails.roblox.com/v1/assets?assetIds=71082594740090&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/71082594740090) **Tank Destroyer** · 71082594740090 · Knighti3PrismL | [![CV9030](https://thumbnails.roblox.com/v1/assets?assetIds=105349406009848&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/105349406009848) **CV9030 Tank** · 105349406009848 · Skat3r3gD3ltaa | [![APC](https://thumbnails.roblox.com/v1/assets?assetIds=117171827582588&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/117171827582588) **Armored APC** · 117171827582588 · DriftvSCyberH | [![War tank](https://thumbnails.roblox.com/v1/assets?assetIds=85180833247608&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/85180833247608) **War Tank Base C** · 85180833247608 · AshenIoMirage2183127 | — |
| Navios | [![HMS Jervis](https://thumbnails.roblox.com/v1/assets?assetIds=9421369489&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/9421369489) **HMS Jervis** · 9421369489 · creepercatchanel | [![ORS Thebe](https://thumbnails.roblox.com/v1/assets?assetIds=74585287273804&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/74585287273804) **ORS Thebe DD-20** · 74585287273804 · R0B0XINB0Y_23 | [![IJN Aoba](https://thumbnails.roblox.com/v1/assets?assetIds=2975863462&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/2975863462) **IJN Aoba** · 2975863462 · creepercatchanel | [![Speedboat](https://thumbnails.roblox.com/v1/assets?assetIds=71895427855605&returnPolicy=PlaceHolder&size=150x150&format=Png)](https://create.roblox.com/store/asset/71895427855605) **Military Speedboat** · 71895427855605 · Xz_Z3robGN3bulakGHun | — |
| Terreno, árvores e props já auditados | **Silver Firs PBR** · 18475173887 · cópia visual `PineGrove_*` no rascunho; fonte sem scripts, textura/licença/performance pendentes | **Base de grama WW2 Map** · origem 959903202 · base achatada só no rascunho; pacote completo em quarentena | **Props Military Map** · 8741869283 · torre, barracas, barreiras, crates, cercas e props; pacote completo em quarentena | **Hill_NorthWest / PineCluster_NE** · rejeitados pelo responsável; removidos da cópia de trabalho | — |

## Tema costeiro e decisão de uso — 2026-10-15

O responsável rejeitou seis novos itens (Burning Building apareceu repetido na mensagem): Palm Tree 16921719191, Coconut Tree 138766745874748, Ruins 1905076, Burning Building 19520408, Nuclear Power Plant All 2466887748 e Power Plant 1636050870. Somados aos nove rejeitados antes, são 15 candidatos com suportes vermelhos e SelectionStatus=NAO_USAR. Pela regra de inferência dada pelo responsável, os demais 94 candidatos da matriz estão como USAR. Nenhum asset foi incorporado à arena.

A sequência de classes segue entrada de costa/palmeiras, porto e contêineres, infraestrutura de usina, depois cidade e prédios. Isso só organiza a galeria; ainda não construí o mapa. Os suportes cinza indicam USAR e os vermelhos indicam NAO_USAR.

| Linha e coluna | Candidato / ID Creator Store | Triagem do preview | Decisão |
|---|---|---|
| 15/A | Palm Tree · 16921719191 | 2 BaseParts; sem scripts encontrados | NÃO USAR |
| 15/B | Tropical Palm Trees Island Vegetation Resort · 102868561472384 | 791 BaseParts; 1 script desativado na quarentena e omitido do preview | USAR |
| 15/C | Palm Tree Classic · 15075396 | Modelo clássico; sem scripts encontrados | USAR |
| 15/D | Dock · 8489328915 | 36 BaseParts; sem scripts encontrados | USAR |
| 15/E | Old Broken Dock · 10851133793 | 54 BaseParts; sem scripts encontrados; opção de cais danificado | USAR |
| 15/F | Coconut Tree · 138766745874748 | 32 BaseParts; sem scripts encontrados | NÃO USAR |
| 16/A | Shipping Container · 8473839456 | 2 BaseParts; candidato de contêiner de carga | USAR |
| 16/B | Shipping Container Open Door · 2669026559 | 86 BaseParts; 1 script desativado na quarentena e omitido do preview | USAR |
| 16/C | Shipping Container Inv Textured · 431041039 | 1 MeshPart | USAR |
| 16/D | Garrys Mod cargo container · 11585373151 | 1 MeshPart | USAR |
| 16/E | Port crane · 16293957030 | Guindaste portuário; 275 BaseParts | USAR |
| 17/A | Natural Draft Cooling Tower · 8482186290 | Torre de resfriamento; 110 BaseParts | USAR |
| 17/B | Nuclear Power Plant All · 2466887748 | 2.910 BaseParts; complexo amplo para comparação de escala | NÃO USAR |
| 17/C | Trójmost Power Plant · 14661239504 | 3.629 BaseParts e 113.945 triângulos conforme Creator Store | USAR |
| 17/D | Power Plant · 1636050870 | 68 BaseParts; 2 scripts e 4 sons na fonte, scripts desativados e áudio omitido do preview | NÃO USAR |

O Creator Store apresenta essas páginas com a opção Get Model; isso não substitui auditoria de licença e dependências. O modelo com Coconut no título 18363394399 retornou erro 404 e não está na matriz. Os 20 candidatos adicionados nas três últimas rodadas agora estão decididos; o nome escolhido pelo responsável é mantido como fonte para registrar a seleção.

### Ordem atual da matriz no Studio

| Linha | Classe | Candidatos |
|---|---|---|
| 01 LIGHT_WEAPONS_A | Armas existentes | M24, SIG MCX, Assault Rifle |
| 02 LIGHT_WEAPONS_B | Armas adicionais | AK-47, M4A1, QBZ-191, Grau |
| 03 THROWABLES_GRENADES_SMOKE | Granadas e fumaça | Grenade Pack, F1, M18 Smoke, Stun Grenade |
| 04 ARTILLERY | Artilharia | 4 candidatos |
| 05 ROCKETS | Foguetes e lançadores | 4 candidatos |
| 06 TANKS_ARMORED | Tanques e blindados | 4 candidatos |
| 07 JETS | Jatos | 4 candidatos |
| 08 AIRCRAFT | Aviões e helicópteros | 4 candidatos |
| 09 NAVAL | Navios e barcos | 4 candidatos |
| 10 AIRDROPS | Caixas de airdrop | COD MW, PUBG, Modern Warfare, Military Supply Drop |
| 11 LOOT_SUPPLY | Loot e suprimentos | Military Crates, Ammo Crate Pack |
| 12 DEFENSE_FORTIFICATIONS | Defesa e fortificações | Barreiras, arame farpado, barraca |
| 13 BUILDINGS_EXISTING | Prédios e ruínas existentes | 4 candidatos |
| 14 WAR_RUINS_FIRE | Destruição e incêndio | 3 USAR, 2 NÃO USAR |
| 15 PENINSULA_COAST_ENTRY | Entrada costeira da península | 4 USAR, 2 NÃO USAR; A–F |
| 16 CONTAINERS_PORT_LOGISTICS | Contêineres e logística portuária | 5 USAR |
| 17 POWERPLANTS_INDUSTRIAL | Usinas e infraestrutura industrial | 2 USAR, 2 NÃO USAR |
| 18 URBAN_BUILDINGS_A | Prédios urbanos 3D | 4 candidatos |
| 19 DAMAGED_STRUCTURES_B | Prédios danificados | 2 candidatos |
| 20 HANGARS_GARAGES | Hangares e garagens | 4 candidatos |
| 21 ENTERABLE_INTERIORS_FPS | Interiores e fluxo FPS | 4 candidatos |
| 22 BRIDGES | Pontes | 4 candidatos |
| 23 RAPEL_VERTICAL_ACCESS | Rapel e torres | 5 candidatos |
| 24 RADAR_SURVEILLANCE | Radares | 4 candidatos |
| 25 COMMUNICATION_ANTENNAS | Antenas de comunicação | 4 candidatos |
| 26 TREES | Árvores | Silver Firs PBR, Oak, Ash (NÃO USAR), Birch, Willow |
| 27 GRASS_SHRUBS | Grama e vegetação baixa | Grass Field, Long Grass (NÃO USAR), Grass Meadow, Grass Meshes PBR, Shrubs Pack |

Validação em Studio Edit: 27 linhas, 109 modelos e 109 suportes. Todos os modelos estão centralizados em sua coluna, com o fundo em Y=0, ancorados e sem colisão, toque ou consulta. Os previews não contêm scripts, remotes ou sons. Status agregado: 94 USAR, 15 NÃO USAR e 0 REVISAR. A linha costeira usa seis colunas A–F; as outras linhas usam até cinco. Suportes vermelhos indicam NÃO USAR e cinza indica USAR.
## Como usar a fila

- A lista de novos modelos foi pesquisada como gratuita no Creator Store em 15/10/2026. Isso só confirma que a busca os retornou com preço zero naquele momento; não confirma qualidade, segurança, licença ou adequação visual.
- Os candidatos externos desta fila foram importados somente para quarentena. Scripts executáveis encontrados nos pacotes estão desativados; os objetos exibidos na grade são cópias de geometria e propriedades visuais, sem scripts, remotes ou sons. Os modelos originais ainda precisam de auditoria de dependências, licença, colisão e adequação. Nada foi integrado à arena.
- Itens anunciados com scripts (ex.: os dois canhões Roblox/RDA) podem ser recusados já na triagem, ou mantidos apenas para extrair geometria estática se isso for escolhido e tecnicamente seguro.
- O rascunho antigo `Workspace.FL016_ArenaAssetDraft_TEMPORARY` não é a fila e não será ampliado. Avalie os modelos em `Workspace.FL016_AssetSelectionQueue`; esta fila passa a ser o foco da FL-016.
