# Roadmap e gates

**Planejamento inicial:** 2026-10-14. Sprints de 2 semanas **propostas**, não compromissos de calendário; replanejar capacidade após S0. Não declarar Sprint concluída sem evidência do Studio.

| Sprint | Janela indicativa | Entrega | Gate de saída |
|---|---|---|---|
| S0 Fundação | 19–30 out 2026 | Git, Rojo, Codex MCP, PRD, pipeline de assets | Studio+Codex+Rojo demonstrados, backlog validado |
| S1 Vertical slice | 02–13 nov 2026 | greybox, FPS, rifle, dummy | loop jogável gravado, zero P0 aberto |
| S2 Arte | 16–27 nov 2026 | kit militar licenciado, rig, cenário, benchmark | assets auditados, visual coerente e benchmark real |
| S3 Multiplayer MVP | 30 nov–11 dez 2026 | 2 equipes, 2 armas, respawn, destruição | sessão multiplayer testada sem falhas bloqueadoras |
| S4 Alfa experimental | 14–25 dez 2026 | veículo, profiling e pacote alfa | aceite manual de release + audit trail |
| Later | sem data | bots, segundo mapa, efeitos, mobile, R&D REA | descoberta priorizada depois do MVP |

## Política de gates
1. **G0** (infra): Git de origem; Rojo e MCP comprovados em sessão local. Sem G0, não iniciar implementação em paralelo.
2. **G1** (vertical slice): movimento + rifle + dummy estáveis antes de comprar/inserir kit visual extenso.
3. **G2** (assets): procedência, licença, scripts auditados, escala e performance verificadas.
4. **G3** (MVP): 2+ clientes, servidor validando ações, UX mínima e testes de exploit não invasivos.
5. **G4** (alfa): review de IP, segurança, performance e classificação; publicação só manual.

## Gestão de mudanças
Adições ao backlog `LATER` não entram em sprint sem estimativa, dependências e aceite de replanejamento. Métrica primária é a **entrega funcional demonstrada**, não número de commits nem quantidade de assets.
