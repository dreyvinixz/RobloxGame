# Quarentena de assets

Esta pasta recebe cópias de modelos e dependências em avaliação. Conteúdo aqui é evidência de inspeção e não deve ser inserido na cena final nem executado.

Para cada asset candidato:

1. Registre ID/URL, autor e termos aplicáveis em `../registry.csv` com status `DISCOVERED`.
2. Confirme procedência e permissão de uso antes de baixar ou inserir.
3. Inspecione todos os descendentes e dependências; trate Scripts, LocalScripts e ModuleScripts como não confiáveis e não os execute durante a auditoria.
4. Registre hash, resultado da revisão de scripts e evidência de performance; avance o status somente após cada gate em `../../docs/ASSET_PIPELINE.md`.
5. Mova para uso final apenas após status `APPROVED` e revisão humana.

Estado em 2026-10-15: nenhum asset de terceiros foi importado; a quarentena está vazia. Este procedimento não substitui a inspeção concreta exigida pela FL-005.
