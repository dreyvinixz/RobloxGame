# Terreno 2 — V2: geometria 2D com evidência verificável

**Status: V2 experimental de análise de imagem. Não é DEM, não é mesh 3D, não possui câmera física calibrada.** O gerador procedural da ilha anterior não é importado.

## Objetivo / entradas obrigatórias

V2 complementa a V1, usando **as imagens originais**, que não estão comitadas no GitHub:

- `references/top_flat_semantic.jpg` (1264×842): pixels observados da máscara terra, faixa clara do corredor e linha central.
- `references/top_render.png` (1536×1024): evidências visuais de regiões rochosas e escarpas, extraídas da textura/sombreamento, NÃO alturas.
- `references/{front,back,left,right}_render.png` e `references/{front,back,left,right}_wireframe.png`: perfis da silhueta aparentes dos quatro eixos; coordenadas/pontos mantidos nas imagens.
- `--v1-report` opcional: confere SHA-256 da versão plana e renderizada contra a V1, e impede trocar as referências sem detecção.

Os binários originais continuam no ZIP entregue ao usuário na V1. O ZIP da V2 contém relatórios e análises sobre o conjunto real, mas os GitHub Actions **testam imagens sintéticas** porque os originais não estão no repositório. Não confundir testes aprovados com reconstrução fiel.

## Executar com os pixels originais

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_2_v2.reconstruct_v2 \
   --sources references \
   --v1-report output_v1/v1_report.json \
   --output terrain2-v2
python -m unittest discover -s tests -p 'test_terrain2_v2.py' -v
```

## Pipeline (limites incluídos)

1. **Traçar corredor contínuo norte–sul:** anotações manuais de 12 pontos no espaço do JPEG são apenas orientação. Entre elas, caminho mínimo pondera a distância aos pixels bege observados e o afastamento da direção do traçado, via `route_through_array`. Não preenche artificialmente as áreas não observadas: pixels incertos do caminho são expostos em `channel_unsupported_pixels.png`.
2. **Conservar massa costeira inteira:** máscaras de terra usam todos componentes relevantes, sem selecionar apenas o maior.
3. **Separar relevo visual:** detecção de textura escura/gradientes locais em `top_render.png` com uma escala de confiança. Píxeis de cristas próximos à costa são separados em `rock_coastal_uncertain_render.png`; isso também pode rejeitar falésias verdadeiras.
4. **Alinhamento inicial por proporção de pixels:** redimensionar a máscara de terra do render para comparar com a máscara limpa e calcular IoU **não é** estimar câmera, homografia verdadeira ou altitude.
5. **Oito perfis laterais:** separar render de wireframe, em frente/trás/esquerda/direita, e medir RMSE A-versus-B. Comparar frontal/posterior e esquerda/direita espelhados sem falsificar correspondências. Mar Z=0 em Y=465 da prancha é baseline em pixels, não escala métrica.
6. **Preservar toda incerteza:** não declarar que beige é água física nem que texturas rochosas são valores de altura.

## Valores observados nas imagens reais (execução local, 2026-10-16)

| Grandeza | Resultado |
|---|---:|
| Pontos no eixo do corredor | 478 |
| Linha central rasterizada em uma componente 8-conectada | Sim |
| Fração de pontos apoiados em pixels bege na imagem original | 93,72% |
| Pixels no traçado sem suporte direto de cor | 27 |
| Pixels no corredor bege candidato | 18.805 |
| Pixels de textura de rocha candidatos (total) | 305.566 |
| Pixels candidatos de rocha mais distantes do mar | 207.661 |
| Pixels de rochas ou costa com maior incerteza | 97.905 |
| IoU do terreno entre vistas superiores **por simples escala** (máscaras com tolerância) | 0,9304 |
| Frontal x posterior (espelho): RMSE | 1,23 px |
| Oeste x leste (espelho): RMSE | 34,33 px |
| Render x wireframe frontal | 4,95 px |
| Render x wireframe posterior | 5,06 px |
| Render x wireframe oeste | 5,11 px |
| Render x wireframe leste | 6,25 px |

**Importante:** métricas de suporte e IoU usam as próprias imagens que definiram os candidatos; não são estimativas independentes de precisão ou acerto topográfico. A grande divergência oeste/leste permanece em aberto, pois as ilustrações AI podem ter inconsistências de projeção.

## Arquivos úteis da execução original

- `v2_contact_sheet.jpg`: referência, corredor e rochas com as quatro comparações laterais.
- `channel_evidence_overlay.png`, `channel_polyline_source_pixels.json`, `channel_centerline_1px.png`, `channel_unsupported_pixels.png`.
- `rock_evidence_overlay.png`, `rock_likelihood.png`, `rock_interior_candidate_render.png`, `rock_coastal_uncertain_render.png`.
- `orthographic_profile_constraints.json`, `silhouette_views.png`, `land_components.json`, `v2_report.json` com SHA-256.

## Próximo gate V3

Revisar marcações reais das montanhas e do canal, resolver a orientação/calibração e inferir uma **hipótese** de altura regularizada com restrições por região. Validar sobrepondo renders 3D aos oito perfis e ao contorno original. Não integrar no Roblox Studio até haver comparações adequadas.

Esta branch abre PR apenas para `dev`, sem alterar o place e sem tocar em `main`.
