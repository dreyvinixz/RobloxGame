# Segurança

**Modelo de ameaça:** clientes maliciosos tentando forjar ações, downloads de modelos com scripts ocultos, permissões MCP excessivas e importação inadvertida de conteúdo sem direitos.

## Rede
- Servidor controla HP, inventário validado, tiros aceitos, placar, times e estado de veículos/cobertura.
- Clientes enviam intenções; validação e rate-limit por jogador/arma/evento; nunca confiar em posição/dano solicitado diretamente.
- FL-009 define `ReplicatedStorage.Remotes.FireWeapon`: aceita somente `{ weaponId, origin, direction, targetPosition }`, obtém o jogador pelo argumento implícito de `OnServerEvent`, valida tipos, campos extras, arma, direção unitária, origem próxima ao personagem, alinhamento direção/alvo, alvo dentro do alcance de servidor e intervalo por jogador. O alcance é anexado à intenção validada com valor do servidor; dados de dano/HP enviados pelo cliente são recusados como payload inválido.
- Recusas são registradas no Output com motivo e limite de frequência por jogador/motivo. O sinal interno de tiro aceito é server-only; FL-009 não aplica dano. Raycast e aplicação autoritativa de dano entram na FL-010.
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
