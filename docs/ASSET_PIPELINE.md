# Política e pipeline de assets (sem modelagem manual)

## Fontes permitidas
1. **Roblox Creator Store:** modelos, meshes, animações, sons sob os termos aplicáveis e revisados.
2. **Geração própria por IA no Studio:** `generate_mesh`, `generate_material` e `generate_procedural_model` quando presentes no MCP atual.
3. **Terceiros com licença verificável** (por ex. lojas de assets): conferir compatibilidade com redistribuição/publicação no Roblox. Comprar só com aprovação explícita.

**Nunca** presumir que modelo 'grátis' pode ser redistribuído irrestritamente. Não extrair arquivos do BF6 nem replicar branding/logotipos da EA.

## Ingestão obrigatória (asset gate)
`DISCOVERED` → `LICENSE_VERIFIED` → `QUARANTINED` → `SCRIPT_AUDITED` → `PERFORMANCE_TESTED` → `APPROVED` → `IN_USE`.

1. Pesquise pelo MCP ou Toolbox; capture ID + URL + autor + termos.
2. Insira em lugar de quarentena/experiência local de teste, **não** no mapa final.
3. Inspecione todos os descendentes incluindo Scripts, LocalScripts, ModuleScripts, remotes, require(assetId), HTTP, scripts ofuscados e dependências dinâmicas. Remova código dispensável. Considere SandboxedInstance/Capabilities conforme suporte na instalação.
4. Verifique licenças de mesh/textura/áudio incorporados e efeitos de publicação.
5. Verifique escala, colisões, origem, animação, geometria, texturas e benchmark com hardware real.
6. Atualize `assets/registry.csv` com status `APPROVED` e evidência da issue; só então mover para cena final.

## Critérios de qualidade visual
- Direção: militar contemporâneo realista **original**; não copiar trade dress específico do BF6.
- Asset permite escala em studs e colisão coerente.
- Reduzir repetição com variações autorizadas; priorizar módulos urbanos e cobertura.
- Medir orçamento de performance antes de definir números máximos por peça.

## Reversão
Se houver suspeita de backdoor, remover do projeto, revogar permissões relevantes e auditar dependências. Não executar código não revisado em experiência publicada.

Referências oficiais:
- https://create.roblox.com/docs/production/creator-store
- https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities
- https://create.roblox.com/docs/production/publishing/ip-guidelines
