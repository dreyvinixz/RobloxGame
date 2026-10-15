# Direção de arte — FL-013 (rascunho condicionado à FL-012)

**Estado:** pesquisa e comparação iniciadas; seleção final aguarda benchmark no Studio.

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
| [Realistic Urban City](https://create.roblox.com/store/asset/95798439683690/Realistic-Urban-City) | `@2XQUISITE_DESIGNS` | 23.119 triângulos, 45 MeshParts e 11 decals; a página não informa contagem de scripts | US$ 3,99 na consulta; Creator Store e termos aplicáveis. Compra não autorizada nem realizada | Melhor correspondência aparente com a direção e pacote pequeno, porém recente, com poucas avaliações e script count não publicado. Candidato condicionado a aprovação de compra, auditoria e teste. |

O Creator Store informa que a página do asset apresenta distribuidor, tipo, descrição e detalhes técnicos; assets podem conter scripts. A política da Roblox exige aderência aos Termos de Uso e recomenda auditoria antes de usar itens de terceiros. Os três itens ficam em `DISCOVERED`: nenhum foi inserido no jogo, auditado ou aprovado para uso.

## Qualidade e orçamento preliminares

Direção proposta: **realismo estilizado contido**. Manter formas, escala e desgaste reconhecíveis, simplificar pequenos detalhes para leitura em movimento e repetir módulos com variações de cor autorizadas.

| Classe | Triângulos estimados por asset | Geometria | Texturas propostas |
|---|---:|---:|---|
| Prop pequeno (cone, caixa, placa) | até 3.000 | até 2 MeshParts | atlas compartilhado até 512² |
| Módulo urbano reutilizável | até 10.000 | até 4 MeshParts | até 2 mapas 1024² compartilhados pelo kit |
| Elemento de destaque | até 25.000 | até 8 MeshParts | até 2 mapas 1024²; usar com parcimônia |
| Cena visível da arena inicial | alvo provisório até 250.000 no total | alvo provisório até 300 MeshParts | reusar atlas/material sempre que possível |

Estes números são **hipóteses de trabalho**, não limites finais nem resultados medidos. A FL-012 deve registrar FPS e memória na arena greybox primeiro. Rever o orçamento se o baseline não sustentar a meta hipotética de 60 FPS desktop indicada no PRD.

## Guia de materiais

- Concreto: `Concrete` ou superfície PBR moderada; variação sutil, sem ruído fino que prejudique a silhueta.
- Asfalto: cinza carvão fosco, marcação viária esparsa e contraste suficiente para leitura das rotas.
- Metal pintado: azul-aço/olive dessaturado, roughness alto e desgaste localizado.
- Vidro: uso limitado; evitar transparência e reflexos em fachadas sem função de gameplay.
- Sinalização: âmbar e branco apenas para navegação/interação; preservar o contraste entre equipes quando elas forem implementadas.

## Gate de seleção e ingestão

1. Concluir a FL-012 e substituir os orçamentos hipotéticos pelo baseline observado.
2. Confirmar preço, autor, permissões e termos atuais da coleção escolhida.
3. Para item pago, obter autorização explícita antes de comprar.
4. Importar o candidato para quarentena; auditar scripts, dependências, meshes, texturas, colisões e escala.
5. Registrar a evidência no `assets/registry.csv`; só marcar `APPROVED` após revisão e teste de performance.

## Fontes

- [Roblox Creator Store — documentação e segurança de assets](https://create.roblox.com/docs/production/creator-store)
- [Roblox — montagem de ambientes modulares](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments)
