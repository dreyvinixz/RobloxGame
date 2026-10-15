#!/usr/bin/env python3
"""Validação offline do planejamento e layout Rojo (não substitui playtest)."""
from pathlib import Path
import csv
import json
import sys

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = {'id','sprint','priority','type','area','points','title','goal','implementation','acceptance','verification','dependencies','status'}
VALID_SPRINTS = {'S0','S1','S2','S3','S4','LATER'}
VALID_PRIORITIES = {'P0','P1','P2'}

def load():
    return json.loads((ROOT/'planning/backlog.json').read_text(encoding='utf-8'))

def validate():
    issues = load()
    errors=[]
    ids={i.get('id') for i in issues}
    if len(ids)!=len(issues): errors.append('Duplicated issue ID')
    for i in issues:
        key=i.get('id','<unknown>')
        for field in REQUIRED-set(i): errors.append(f'{key}: missing {field}')
        if i.get('sprint') not in VALID_SPRINTS:errors.append(f'{key}: invalid sprint')
        if i.get('priority') not in VALID_PRIORITIES:errors.append(f'{key}: invalid priority')
        if not isinstance(i.get('points'),int) or i.get('points',0)<1:errors.append(f'{key}: invalid points')
        if not i.get('acceptance'):errors.append(f'{key}: no acceptance criteria')
        md=ROOT/'planning/issues'/f'{key}.md'
        if not md.exists():errors.append(f'{key}: missing file {md.relative_to(ROOT)}')
        elif not md.read_text(encoding='utf-8').startswith(f'# {key} — '):errors.append(f'{key}: wrong issue header')
        for dep in i.get('dependencies',[]):
            if dep not in ids:errors.append(f'{key}: unknown dependency {dep}')
            if dep==key:errors.append(f'{key}: self dependency')
    graph={i['id']:i['dependencies'] for i in issues}
    visiting=set();done=set()
    def dfs(x):
        if x in done:return
        if x in visiting:errors.append(f'dependency cycle at {x}');return
        visiting.add(x)
        for dep in graph.get(x,[]):dfs(dep)
        visiting.discard(x);done.add(x)
    for k in graph:dfs(k)
    with (ROOT/'planning/backlog.csv').open(encoding='utf-8-sig',newline='') as f:
        csvrows=list(csv.DictReader(f))
    if {row['id'] for row in csvrows}!=ids:errors.append('CSV IDs disagree with JSON')
    rojo=json.loads((ROOT/'default.project.json').read_text(encoding='utf-8'))
    def walk(node):
        if isinstance(node,dict):
            if '$path' in node and not (ROOT/node['$path']).exists(): errors.append(f"Rojo path missing: {node['$path']}")
            for v in node.values():walk(v)
    walk(rojo)
    registry=ROOT/'assets/registry.csv'
    with registry.open(encoding='utf-8',newline='') as f:
        rows=list(csv.DictReader(f))
    needs={'asset_key','source','asset_id','author','license_terms','script_audit','status','issue'}
    if rows and not needs.issubset(rows[0]):errors.append('Asset registry columns missing')
    for row in rows:
        if row.get('status') in ('APPROVED','IN_USE'):
            for col in needs-{'status'}:
                if not row.get(col):errors.append(f"Approved asset {row.get('asset_key','?')}: missing {col}")
    for sprint in VALID_SPRINTS-{'LATER'}:
        if not (ROOT/'planning/sprints'/f'{sprint}.md').exists():errors.append(f'missing sprint file {sprint}')
    return errors

if __name__=='__main__':
    failures=validate()
    if failures:
        print('FAILED project validation:')
        for err in failures:print(' -',err)
        sys.exit(1)
    print(f'OK: {len(load())} issues, dependencies acyclic, Rojo paths, docs, assets registry.')
