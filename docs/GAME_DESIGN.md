# Game Design Document — primeira versão

## Fantasia de jogo
Combate militar moderno em ambiente urbano compacto com mobilidade, cobertura, gerenciamento de munição e cooperação.

## Loop e ritmo
Infiltrar rota → ocupar cobertura → combater → reposicionar → respawn ou pontuar. Map design começa em greybox, sem efeito de rede massivo.

## Inputs inicialmente planejados
Mouse: olhar/mirar/atirar. WASD: mover. Shift: sprint. R: recarregar. 1/2: equipamento. Valores exatos e controles podem mudar após playtest.

## Armas
- AR: hitscan MVP, cadência e dano definidos em configuração compartilhada; servidor valida alcance e cooldown.
- Pistola: tiro secundário e recarga independente; diferenciar precisão/cadência.
- Recuo/efeitos de cliente não mudam autoridade de dano no servidor.

## Nível
Mapa urbano pequeno com 2 spawns distintos, 3 rotas de aproximação e coberturas; blueprint final será medido/desenhado no Studio.

## Destruição
Uma cobertura de teste com estados discretos (inteira, danificada, destruída) e replicação autoritativa, não física de todos os voxels.

## Veículos
Um tanque ou veículo terrestre como protótipo S4, usando um modelo/chassi licenciado e controladores revisados; não faz parte do MVP S3.
