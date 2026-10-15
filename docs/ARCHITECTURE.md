# Arquitetura v0.1

## Visão geral

```text
Codex / agente IA ── MCP oficial ── Roblox Studio (assets, inspeção, playtests)
         │                                      ▲
         ▼                                      │ sincronização
    GitHub + Git ── arquivos locais ── Rojo ──┘
         │
  src/client + src/server + src/shared
```

**Fonte de verdade:** Git para scripts, docs, IDs e manifests; Studio para lugar, terreno, objetos, experiências e provas visuais. Os assets/places binários não são duplicados automaticamente neste repo; registrar IDs, snapshots e exportações autorizadas quando for necessário.

## DataModel (Rojo)
- `ReplicatedStorage/Shared` ← `src/shared`: protocolos, configurações públicas.
- `ReplicatedStorage/Remotes`: pasta reservada a eventos; eventos específicos serão criados pelo código servidor nas issues de rede.
- `ServerScriptService/GameServer` ← `src/server`: autenticação implícita de jogador e regras autoritativas.
- `StarterPlayer/StarterPlayerScripts/GameClient` ← `src/client`: câmera, inputs, HUD, render FX.
- `Workspace`: mapa e assets autorados no Studio; a arena e seus módulos de pavimento, fachada e cobertura são gerados pelo servidor a partir de `src/server/ArenaBuilder.luau`. Os módulos decorativos não colidem nem participam de raycasts; os núcleos mantêm as colisões do layout. Não limpar o Workspace via Rojo.

## Rede e autoridade
Cliente envia intenção (`FireWeapon`, `RequestReload`, `EnterVehicle`); servidor valida player, cadência, arma, alcance, cooldown, estado, posição coerente e aplica dano. Servidor replica resultado e estados. Não confiar em campos de HP, kills ou velocidade informados pelo cliente.

## Domínios planejados
- PlayerController / camera: cliente
- WeaponService / DamageService / TeamService / DestructionService: servidor
- NetProtocol / WeaponConfig: shared
- Vehicles: servidor autoritativo para regras; suavização visual no cliente após S3
- AssetRegistry: arquivo versionado com ID, fonte, autor e revisão

## Decisões de infraestrutura
- Rojo como base de código; MCP para operações de Studio, nunca substituir Git por prompt-history.
- Sem API externa, banco, Supabase ou servidor dedicado no MVP (Roblox cuida do runtime).
- Servidor determina dano/placar; cliente interpola efeitos.
- No MVP, não compartilhar endpoint de telemetria fora do Roblox nem coletar dados pessoais.

## Riscos técnicos
1. Editar script simultaneamente via MCP/Rojo → drift: comparar antes de sincronizar.
2. Assets prontos com scripts ocultos → inspeção e quarentena antes do uso.
3. Modelos muito detalhados → FPS/tempo de carga; medir em S2.
4. Ferramentas MCP mudarem → capability smoke test S0, fallback manual documentado.
5. Física/destruição replicadas → protótipo autoritativo pequeno antes de generalizar.
