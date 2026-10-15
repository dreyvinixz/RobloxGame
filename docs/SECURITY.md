# Segurança

**Modelo de ameaça:** clientes maliciosos tentando forjar ações, downloads de modelos com scripts ocultos, permissões MCP excessivas e importação inadvertida de conteúdo sem direitos.

## Rede
- Servidor controla HP, inventário validado, tiros aceitos, placar, times e estado de veículos/cobertura.
- Clientes enviam intenções; validação e rate-limit por jogador/arma/evento; nunca confiar em posição/dano solicitado diretamente.
- Sem remotes genéricos que executem código Luau arbitrário; sem `loadstring` remoto.

## Ferramentas e credenciais
- Conectar MCP ao Studio **local** apenas; evitar execução de comandos desconhecidos no lugar principal.
- Não commitar segredos; não compartilhar cookies/token Roblox/GitHub em issues.
- Agentes precisam approval humano para publicar, comprar, deletar grandes conjuntos ou mudar configuração de segurança.

## Assets
- Modelos de terceiros podem conter backdoors; execute fluxo `docs/ASSET_PIPELINE.md` antes de publicar.
- Registrar licença/URL/autor/evidência; revisão de código importado é obrigatória.

## Dependências
Manter versão registrada dos CLIs e plugins no relatório da S0. Revisar atualizações antes de aplicá-las automaticamente.
