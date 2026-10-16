# Terreno 2 — V1 (novo conjunto, apenas evidências 2D)

**Escopo:** nova ilha AI-gerada, completamente separada das V1–V5 da ilha anterior. Este pipeline exige pixels reais como entrada e **não gera montanhas procedurais, malha 3D ou um heightmap inventado**.

## Fontes

As 16 imagens originais fornecidas pelo usuário foram reunidas em um **ZIP de referências separado**, com `reference_manifest.json` (nomes e SHA-256). A pasta binária `references/` não está publicada no GitHub: o Codex/CI somente pode processá-las após recebê-las explicitamente. Os scripts esperam nomes estáveis:

- `top_flat_semantic.jpg`: máscara estilizada/limpa, fonte principal para o contorno, costa e corredor claro central.
- `top_sparse_mesh.jpg` e `top_render.png`: futuras restrições da topologia e do relevo.
- `front_render.png`, `back_render.png`, `left_render.png`, `right_render.png`: perfis laterais aparentes de 129 pontos. Suas medidas são em **pixels**, não altitudes físicas.
- O ZIP inclui também vistas wireframe front/back/left/right, isométricas, atlas e inferior.

## Executar com as imagens reais

Após extrair a pasta `references/` do ZIP:

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_2_v1.extract_v1 --sources references --output terrain-2-v1-output
```

Para executar os testes sintéticos no repositório:

```bash
python -m unittest discover -s tests -p 'test_terrain_2_v1.py' -v
```

## Artefatos produzidos

- `coastline_pixels.json`: contorno da massa principal em coordenadas de pixels da imagem original de 1264×842. Extrai-se o contorno real detectado, sem inventar polígonos.
- `land_all_mask.png`, `mainland_mask.png`, `ocean_observed_mask.png`, `beige_observed_mask.png`.
- `river_corridor_candidates.png` e `river_corridor_guide.json`: pixels claros observados dentro de uma região-guia desenhada manualmente. **Não é confirmação de um canal hidrográfico navegável.**
- `orthographic_profiles.json` e `four_views_silhouettes.jpg`: 129 amostras por vista, com sentido horizontal documentado.
- `reference_segmentation_overlay.png`, `v1_contact_sheet.jpg` e `v1_report.json`: evidência e proveniência SHA-256.

## Resultado local no novo conjunto real (2026-10-16)

- **2.102** pontos no contorno bruto principal em pixels.
- **20.769** pixels claros associados ao corredor candidato central.
- Diferença RMS **frontal vs posterior espelhada**: **1,23 px** de altura aparente.
- Diferença RMS **leste vs oeste espelhada**: **34,33 px**, evidenciando inconsistência relativa entre as vistas AI-geradas e/ou orientação convencionada incorretamente.
- O horizonte anotado `Z=0` em y≈465 px serve como baseline de comparação **apenas visual**. A barra “500 u” não é calibração métrica verificada.

Esses resultados são **diagnósticos do raster**, não métricas de precisão 3D. A segmentação foi adaptada às cores desta imagem e depende de revisão manual, especialmente na separação de praias do canal central. As vistas podem ser contraditórias porque foram produzidas por IA.

## Etapa V2 proposta

Revisão e ajuste das máscaras, conexão norte–sul do canal com evidência pixel-a-pixel, marcação dos maciços e alinhamento rigoroso de projeções. Somente depois da validação gerar DEM/heightmap inicial com incerteza por região.

**Integração:** draft PR exclusivamente para `dev`, sem alterações no `Place1` ou na `main`. A CI GitHub Actions testa somente **imagens sintéticas**, pois as imagens originais estão no ZIP do usuário e não no repositório.
