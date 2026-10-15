#!/usr/bin/env python3
"""Criar labels, milestones e issues GitHub. Sem --apply: apenas dry-run.

Requer: gh instalado, gh auth login, repositório já criado. Não modifica Roblox Studio.
"""
import argparse
import json
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MILESTONES={
    'S0':('Sprint 0 — Fundação','2026-10-30'),
    'S1':('Sprint 1 — Vertical slice','2026-11-13'),
    'S2':('Sprint 2 — Arte e integração','2026-11-27'),
    'S3':('Sprint 3 — Multiplayer MVP','2026-12-11'),
    'S4':('Sprint 4 — Veículo e alfa','2026-12-25'),
}
COLORS={'P0':'B60205','P1':'D93F0B','P2':'FBCA04'}

def gh(*args, check=True):
    p=subprocess.run(['gh',*args],capture_output=True,text=True,encoding='utf-8',check=False)
    if check and p.returncode:
        raise RuntimeError(f"gh {' '.join(args)} failed: {p.stderr.strip()}")
    return p.stdout.strip()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--repo',required=True,help='owner/repo')
    mode=ap.add_mutually_exclusive_group()
    mode.add_argument('--apply',action='store_true',help='Realmente criar labels/milestones/issues')
    mode.add_argument('--dry-run',action='store_true',help='Somente mostrar o que faria (padrão)')
    args=ap.parse_args()
    issues=json.loads((ROOT/'planning/backlog.json').read_text(encoding='utf-8'))
    if not args.apply:
        print(f'DRY RUN: repo={args.repo}; {len(issues)} issues; {len(MILESTONES)} milestones; sem escrita')
        for item in issues:print(f"{item['id']} [{item['sprint']}] {item['title']}")
        return
    gh('repo','view',args.repo,'--json','nameWithOwner')
    # gh issue list --state all pode incluir issues fechadas; paginar por numero suficiente para esta fase.
    existing=json.loads(gh('issue','list','--repo',args.repo,'--state','all','--limit','500','--json','title'))
    titles={x['title'] for x in existing}
    types={f"type:{i['type']}" for i in issues}|{'type:bug'}
    areas={f"area:{i['area']}" for i in issues}
    labels={**{k:'0366D6' for k in types},**{k:'5319E7' for k in areas},
            **{f'priority:{k}':v for k,v in COLORS.items()},
            **{f'sprint:{k}':'0E8A16' for k in ('S0','S1','S2','S3','S4','LATER')}}
    for name,color in labels.items():
        gh('label','create',name,'--repo',args.repo,'--color',color,'--force')
    ms=json.loads(gh('api',f'repos/{args.repo}/milestones','--paginate','-f','state=all','--method','GET'))
    names={m['title'] for m in ms}
    for title,due in MILESTONES.values():
        if title not in names:
            gh('api',f'repos/{args.repo}/milestones','--method','POST',
               '-f',f'title={title}','-f',f'due_on={due}T23:59:59Z',
               '-f','description=Milestone com datas indicativas; revisar em Planning')
            print('MILESTONE:',title)
    for i in issues:
        title=f"[{i['id']}] {i['title']}"
        if title in titles:
            print('SKIP:',title);continue
        cmd=['issue','create','--repo',args.repo,'--title',title,
             '--body-file',str(ROOT/'planning/issues'/f"{i['id']}.md")]
        for label in (f"type:{i['type']}",f"area:{i['area']}",f"priority:{i['priority']}",f"sprint:{i['sprint']}"):
            cmd.extend(['--label',label])
        if i['sprint'] in MILESTONES: cmd.extend(['--milestone',MILESTONES[i['sprint']][0]])
        print('CREATED:',title,gh(*cmd))
    print('Import concluído. Configure GitHub Projects/branch protection manualmente, conforme CONTRIBUTING.md.')

if __name__=='__main__':main()
