# Performance — baseline local S2

**Medição:** 2026-10-15 · Roblox Studio Play local · mapa gerado por FL-016 · um cliente em idle após carregamento.

**Interpretação:** baseline observada nesta máquina de desenvolvimento; ainda não confirmada como hardware mínimo/alvo do jogo. Não estabelecer orçamento nem extrapolar para multiplayer a partir desta única sessão.

## Hardware e configuração

| Item | Medição/identificação |
|---|---|
| CPU | Intel Core i5-11400H, 6 cores / 12 threads, 2.70 GHz nominal |
| RAM instalada | 15.71 GiB reportados pelo Windows |
| GPUs disponíveis | Intel UHD Graphics; NVIDIA GeForce GTX 1650 with Max-Q Design (GPU ativa para este processo não confirmada) |
| Tela do Windows | 1920×1080 |
| Viewport Roblox Studio | 1218×841 |
| Roblox Studio | `0.743.0.7431133` |
| Graphics quality | Automática (`SavedQualityLevel=Automatic`; média interna observada 15.2) |
| Conteúdo | Greybox FL-016 + três props urbanos aprovados; um cliente local |

## Resultado

| Métrica | Resultado observado | Método |
|---|---:|---|
| Start → `game:IsLoaded()` + arena/3 props prontos | 3.612 s | Cronômetro de parede no chamador Studio MCP; inclui a latência da ferramenta e não é medida pura de carregamento de experiência |
| FPS médio por frame | 120.03 | 3,588 deltas de `RenderStepped` em 30.008 s |
| FPS mediano | 120.60 | Distribuição dos mesmos frames |
| FPS p1 | 100.94 | Percentil inferior de 1% dos frames |
| FPS do frame mais lento | 33.03 | Um frame; não representa duração sustentada |
| FPS do frame mais rápido | 138.39 | Um frame; temporização variável durante chamada Studio |
| Scene draw calls | 29 | `Stats.SceneDrawcallCount`, constante no sample |
| Scene triangles | 46,779 | `Stats.SceneTriangleCount`, constante no sample |
| Primitives | 2,853 | `Stats.PrimitivesCount` |
| Instâncias no processo | 59,884 | `Stats.InstanceCount`; inclui instâncias de runtime/Core, não apenas o mapa |
| Memória total do processo | média 2,104.39 MB; faixa 2,098.61–2,110.66 MB | `Stats:GetTotalMemoryUsageMb()`, média/amostras a cada 10 frames |
| Render CPU frame time | média 7.17 ms; faixa 6.11–9.15 ms | `Stats.RenderCPUFrameTime` (segundos convertidos para ms) |
| Render GPU frame time | média 2.49 ms; faixa 2.28–3.25 ms | `Stats.RenderGPUFrameTime` (segundos convertidos para ms) |
| Envio de rede | média 0.498 kbit/s; faixa 0.392–0.615 | `Stats.DataSendKbps`, amostrado em idle |
| Recebimento de rede | 0 kbit/s | `Stats.DataReceiveKbps`, amostrado em idle |
| Ping de rede / data ping | snapshot 1.11 ms / 23.04 ms; outra leitura no mesmo período 1.44 ms / 17.78 ms | Stats do cliente local conectado ao servidor Studio local; não representa Internet/live |

## Classificação

- **Render/CPU — observar:** o render CPU observado (7.17 ms) foi maior que o GPU (2.49 ms), e o p1 caiu para 100.94 FPS contra média de 120.03. Um frame isolado chegou a 33.03 FPS. Isso classifica possíveis picos de CPU/render ou escalonamento do Studio como a próxima área de profiling; não identifica causa sem MicroProfiler e cenário repetível em cliente publicado.
- **GPU/geometria — sem sinal de pressão nesta amostra:** 29 draw calls e 46,779 triângulos são baixos nesta cena e hardware; a GPU reportou 2.49 ms médios. Não extrapolar para mapa final, qualidade manual máxima ou outros dispositivos.
- **Memória — contexto necessário:** 2,104.39 MB é memória total do processo cliente/Studio reportada pelo sistema, não somente memória do lugar. Esta captura não separa custo do editor, assets e experiência.
- **Rede — apenas idle local:** cerca de 0.5 kB/s de envio e nenhum recebimento durante idle; ping foi medido contra o servidor local do Studio. Nenhum dos valores serve como baseline multiplayer/Internet.
- **Carregamento — proxy:** 3.612 s é tempo de parede entre iniciar Play pelo MCP e observar `game:IsLoaded()` com a arena e props presentes; inclui overhead de controle e não mede join remoto nem download de assets publicado.

## Reprodutibilidade e limitações

Amostra única de 30.008 s, câmera/parada após o load, sem movimento, combate ou dois clientes. O FPS foi calculado com `1/dt` por frame; p1 e mínimo são sensíveis a uma amostra curta. Studio pode distorcer FPS em relação ao cliente standalone. GPU em uso e configuração de qualidade manual máxima não foram confirmadas. Não comparar diretamente com sessões FL-013/FL-014 de duração/cena distintas. Repetir em cliente publicado, percurso ativo, máquina-alvo definida e sessão multiplayer antes de fixar metas.

Relatório e evidência de execução: [FL-017](TEST_REPORTS/FL-017.md). O Roblox expõe essas métricas por meio do [Stats API](https://create.roblox.com/docs/reference/engine/classes/Stats); a orientação oficial sobre FPS em Studio e load-time está em [Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify). Os campos vêm de leituras ao vivo; nenhum valor foi estimado para preencher lacunas.

## Comparação FL-026 (S2 → S4)

| Métrica | S2, 2026-10-15 | S4, FL-025 | Comparabilidade |
|---|---:|---:|---|
| FPS médio / p1 | 120.03 / 100.94 | Não medido | Sem captura com branch atual sincronizada |
| Render CPU / GPU | 7.17 / 2.49 ms | Não medido | Não atribuir mudança |
| Draw calls / triângulos | 29 / 46,779 | Não medido | Cena S4 inclui novos sistemas/veículo |
| Memória total cliente Studio | 2,104.39 MB média | Não medido | S2 inclui editor e Core |
| Warnings e conexões ao longo do tempo | Não coletados | Não coletados | Sem conclusão de leak/warning |

### Revisão estática e próximo ciclo

- `VehicleService` cria uma conexão Heartbeat e conexões de eventos de jogador durante `Start`, que é idempotente. `PlayerRemoving` limpa tabelas por jogador. O reset substitui o model/seat; o sinal do prompt antigo deixa de ter instância ativa. Isso é revisão de fonte, não evidência de coleta de memória ou contagem estável de conexões em runtime.
- O movimento só faz os três raycasts de obstáculo enquanto existe motorista e intenção. Não há perfil que indique que essa seja a maior despesa, então nenhum aumento de complexidade/otimização foi feito sem medir.
- Repetir a cena S2 em Studio com a branch S4 carregada, modo gráfico e viewport iguais, coletar 30 s idle e 30 s no percurso/combate, e registrar FPS p50/p1, RenderCPU/GPU, draw calls, triângulos e memória a cada 10 frames. Usar MicroProfiler nos piores picos; observar Output e contagem de conexões/instâncias após cinco ciclos enter/drive/exit/destroy/reset. Fazer a comparação em cliente standalone antes de definir regressão crítica.
- O shell não tem `rojo`, Selene ou StyLua disponíveis nesta sessão. Não houve build Luau nem execução deste branch em Studio; não se reivindica resultado S4.
