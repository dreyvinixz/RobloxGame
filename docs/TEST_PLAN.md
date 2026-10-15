# Plano de testes — evidência acima de suposições

## Camadas
- **Static:** `scripts/validate_project.py` + testes Python em CI. Valida documentação/backlog/paths; **não** prova funcionamento Luau.
- **Luau lint/format:** Selene e StyLua após instalação/configuração em FL-006; não reportar executado se ausente.
- **Studio smoke:** iniciar/encerrar play, ler console, validar hierarchy via MCP.
- **Gameplay:** manual com evidência, vídeo e cenários aceitos.
- **Multiplayer:** execução de 2+ clientes no Studio, replicação e ataques inválidos simulados localmente.

## Casos que bloqueiam MVP
| Caso | Passos | Esperado |
|---|---|---|
| QA-01 | Conectar 2 jogadores | Spawns de equipes válidos e estáveis |
| QA-02 | Disparar rifle em dummy | Dano correto no servidor |
| QA-03 | Disparar através de cobertura íntegra | Sem dano ilegal no outro lado |
| QA-04 | Disparar acima da cadência | Requisição inválida descartada |
| QA-05 | Enviar dano/HP inventado | Servidor ignora |
| QA-06 | Trocar rifle/pistola | Configs e munição independentes |
| QA-07 | Morrer/respawn | HP e interface consistentes |
| QA-08 | Destruir cobertura | Estado/colisão consistentes em 2 clientes |
| QA-09 | Reconectar após destruição | Novo cliente vê estado real |
| QA-10 | Jogar sessão de 10 min | Sem bloqueador ou erros críticos repetidos |
| QA-11 | Eliminar `TrainingDummy` e pressionar `T` | Servidor recria o alvo com 100 HP e atualiza o indicador |

## Evidência mínima por tarefa
Data, hash commit/PR, versão Studio/Rojo, ambiente/hardware, passos, resultado, console relevante, captura/vídeo e issue. Guardar relatórios em `docs/TEST_REPORTS/` e arquivos de mídia em anexo do PR/Issue.

## Limiares
Critério FPS inicial 60 desktop é **hipótese**; medir antes de travar meta. No MVP, qualquer exploit reproduzível com alteração não autorizada de HP ou pontuação é bloqueador P0.
