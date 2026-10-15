# PRD — Project Frontline

**Produto:** experiência Roblox FPS militar multiplayer **independente**, inspirada no ritmo e nas mecânicas amplas de shooters de grande escala, sem utilizar marca, assets ou código proprietário da EA. Versão documento: 0.1. Responsável pela aprovação do produto: proprietário do projeto.

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
- Pelo menos 2 clientes no teste multiplayer; logs e vídeo.
- 100% dos assets em uso final identificados, autorizados e auditados.

## Fora do MVP
Mapa gigantesco, 64 jogadores, destruição total do cenário, física realista de veículos, bots avançados, publicação automática, extração de assets do BF6, conexão executável BF6↔Roblox, marketplace monetizado e suporte mobile completo.

## Métricas e limites (hipóteses, não resultados)
- **Funcionalidade:** todos os critérios P0 da S3 passam em sessão de teste controlada.
- **Performance:** estabelecer baseline S2 em hardware real; alvo inicial **60 FPS desktop**, a validar; não é promessa nem métrica já observada.
- **Rede:** medir divergência de HP, latência percebida e spam de remotes; zero exploração crítica reproduzível em QA.
- **Usabilidade:** jogador conclui loop entrar → atirar → respawn sem intervenção externa.

## Restrições
- Sem modelagem manual obrigatória; textura/modelo só de fontes autorizadas ou geração própria.
- Licenças, custos e performance são critérios de seleção de assets.
- Equipe inicial: 1 desenvolvedor + agentes IA (hipótese operacional, ajustar se ampliar equipe).
- Nenhum agente compra ou publica sem revisão humana.

## Aceite do MVP
Aprovação humana do relatório de playtest S3, testes do plano executados, issues P0 resolvidas e registro de ativos completo. Se falhar qualquer gate, replanejar sprint ao invés de declarar sucesso.
