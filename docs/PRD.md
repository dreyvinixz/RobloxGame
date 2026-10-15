# PRD — Project Frontline

**Produto:** experiência Roblox FPS militar multiplayer **independente**, inspirada em convenções amplas do gênero de shooters militares, sem utilizar marca, assets ou código proprietário da EA. Versão documento: 0.2. Escopo técnico aprovado pelo proprietário em 2026-10-15 por FL-004.

## Problema e proposta de valor
Criar uma experiência que transmita combate militar tático (posicionamento, balística simplificada, mobilidade, cobertura e cooperação), usando IA para acelerar implementação e assets prontos para eliminar modelagem manual obrigatória.

## Público e plataforma
Jogadores de Roblox em desktop no primeiro MVP, teclado/mouse. Dispositivos móveis e gamepad são pesquisas futuras e não promessa v0.1.

## Loop de jogo
Entrar → escolher/atribuir time → spawn → deslocar → mirar/atirar → obter feedback → vencer/perder troca → respawn → pontuar → encerrar rodada.

## MVP (gates até S3)
- 1 arena urbana pequena; layout validado antes de arte.
- 2 equipes com spawns, morte, respawn e placar.
- Rifle e pistola com disparo e dano **validados pelo servidor**.
- Câmera e movimentação FPS, munição/recarga, HUD mínimo.
- 1 cobertura destrutível com colisão e visual replicados.
- Combate e destruição validados no servidor; o cliente envia intenções e apresenta câmera, HUD e efeitos.
- Pelo menos 2 clientes no teste multiplayer; logs e vídeo.
- 100% dos assets em uso final identificados, autorizados e auditados.

## Fora do MVP
Mapa gigantesco, 64 jogadores, destruição total do cenário, física realista de veículos, bots avançados, publicação automática, extração de assets do BF6, conexão executável BF6↔Roblox, marketplace monetizado e suporte mobile completo.

## Métricas e limites (hipóteses, não resultados)
- **Funcionalidade:** todos os critérios P0 da S3 passam em sessão de teste controlada.
- **Performance:** estabelecer baseline S2 em hardware real; alvo inicial **60 FPS desktop**, a validar; não é promessa nem métrica já observada.
- **Rede:** medir divergência de HP, latência percebida e spam de remotes; zero exploração crítica reproduzível em QA.
- **Usabilidade:** jogador conclui loop entrar → atirar → respawn sem intervenção externa.

## Primeiro teste de combate aprovado
Em sessão controlada com pelo menos dois clientes, registrar o resultado de: (1) atribuição às duas equipes e respawn; (2) dano de rifle e pistola aplicado pelo servidor; (3) descarte de tiro acima da cadência permitida; (4) cobertura íntegra bloqueando tiro; (5) estado e colisão da cobertura destruída consistentes nos clientes. Coletar logs, resultado por cenário, divergência de HP e latência percebida. Estes são critérios planejados, não resultados já observados; alvos numéricos de desempenho dependem do benchmark S2.

## Restrições
- Sem modelagem manual obrigatória; textura/modelo só de fontes autorizadas ou geração própria.
- Licenças, custos e performance são critérios de seleção de assets.
- Equipe inicial: 1 desenvolvedor + agentes IA (hipótese operacional, ajustar se ampliar equipe).
- Nenhum agente compra ou publica sem revisão humana.

## Aceite do MVP
Aprovação humana do relatório de playtest S3, testes do plano executados, issues P0 resolvidas e registro de ativos completo. Se falhar qualquer gate, replanejar sprint ao invés de declarar sucesso.
