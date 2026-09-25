#!/usr/bin/env python3
"""Prepara un OBJ per Godot: lo gira col muso verso -Z, lo scala alla
misura del gioco e gli mette l'origine a terra al centro."""
import numpy as np, os, re, sys

def read_obj(path):
    V=[]; VN=[]; VT=[]; faces=[]; cur=None
    for line in open(path, errors='ignore'):
        p=line.split()
        if not p: continue
        if p[0]=='v': V.append([float(x) for x in p[1:4]])
        elif p[0]=='vn': VN.append([float(x) for x in p[1:4]])
        elif p[0]=='vt': VT.append([float(x) for x in p[1:3]])
        elif p[0]=='usemtl': cur=line.split(None,1)[1].strip()
        elif p[0]=='f': faces.append((cur, p[1:]))
    return np.array(V,dtype=float), np.array(VN,dtype=float), np.array(VT,dtype=float), faces

def rot_y(P, deg):
    """Rotazione attorno a Y con la convenzione di Godot (rotation.y = deg)."""
    t=np.radians(deg); c,s=np.cos(t),np.sin(t)
    Q=np.empty_like(P)
    Q[:,0]= c*P[:,0]+s*P[:,2]
    Q[:,1]= P[:,1]
    Q[:,2]=-s*P[:,0]+c*P[:,2]
    return Q

def bake(src, dst, yaw, drop=(), target=None, mtl_overrides=None, mtl_src=None):
    V,VN,VT,faces = read_obj(src)
    faces=[(m,f) for m,f in faces if m not in drop]
    # raggruppa per materiale: un usemtl per gruppo invece di decine
    # alternati, altrimenti Godot crea una superficie (e una draw call)
    # ogni volta che il materiale cambia.
    import collections as _c
    _g=_c.OrderedDict()
    for m,f in faces: _g.setdefault(m,[]).append(f)
    faces=[(m,f) for m,fl in _g.items() for f in fl]
    used=set()
    for m,f in faces:
        for tok in f:
            i=int(tok.split('/')[0]); used.add(i-1 if i>0 else len(V)+i)
    used=sorted(used)

    V2 = rot_y(V, yaw)
    N2 = rot_y(VN, yaw) if len(VN) else VN
    sub = V2[used]
    w = sub[:,0].max()-sub[:,0].min()
    l = sub[:,2].max()-sub[:,2].min()
    h = sub[:,1].max()-sub[:,1].min()

    factor = 1.0
    if target:
        opts=[]
        if target.get('w'): opts.append(target['w']/w)
        if target.get('l'): opts.append(target['l']/l)
        if target.get('h'): opts.append(target['h']/h)
        factor = min(opts)
    V2 = V2*factor
    sub = V2[used]
    # origine: centro in X/Z, appoggiato a terra in Y
    off = np.array([(sub[:,0].min()+sub[:,0].max())/2.0, sub[:,1].min(),
                    (sub[:,2].min()+sub[:,2].max())/2.0])
    V2 = V2 - off
    sub = V2[used]

    name=os.path.splitext(os.path.basename(dst))[0]
    mtl_name=name+".mtl"
    with open(dst,'w') as f:
        f.write("# generato per Parcheggiatore Abusivo Simulator\n")
        f.write("mtllib %s\n" % mtl_name)
        for v in V2: f.write("v %.5f %.5f %.5f\n" % tuple(v))
        for t in VT: f.write("vt %.5f %.5f\n" % tuple(t))
        for n in N2: f.write("vn %.5f %.5f %.5f\n" % tuple(n))
        cur=None
        for m,ff in faces:
            if m!=cur:
                f.write("usemtl %s\n" % (m if m else "default")); cur=m
            f.write("f "+" ".join(ff)+"\n")

    # MTL: copia quello originale, con eventuali colori sostituiti
    if mtl_src and os.path.exists(mtl_src):
        out=[]; curm=None
        for line in open(mtl_src, errors='ignore'):
            if line.startswith('newmtl'):
                curm=line.split(None,1)[1].strip()
            if line.startswith('Kd ') and mtl_overrides and curm in mtl_overrides:
                c=mtl_overrides[curm]
                out.append("Kd %.4f %.4f %.4f\n" % c); continue
            if line.startswith('map_'):  # niente texture esterne: non ci sono
                continue
            out.append(line)
        open(os.path.join(os.path.dirname(dst), mtl_name),'w').writelines(out)

    print("%-22s yaw=%6.1f  scala=%.5f  ->  L=%.2f  W=%.2f  H=%.2f  (%d facce)" %
          (os.path.basename(dst), yaw, factor,
           sub[:,2].max()-sub[:,2].min(), sub[:,0].max()-sub[:,0].min(),
           sub[:,1].max()-sub[:,1].min(), len(faces)))

OUT="/home/claude/parcheggiatore-abusivo/assets/models"
os.makedirs(OUT, exist_ok=True)

C1="car1/Car-Model/Car.obj";  C1M="car1/Car-Model/Car.mtl"
C2="car2/Low-Poly-Racing-Car.obj"; C2M="car2/Low-Poly-Racing-Car.mtl"
SC="scooter/scooter.obj"; SCM="scooter/scooter.mtl"

# car1: i fari stanno a +Z, quindi va girata di 180°
bake(C1, OUT+"/car_berlina.obj", 180.0, target={'w':1.70,'l':3.80},
     mtl_src=C1M, mtl_overrides={"Body":(0.15,0.26,0.55)})
bake(C1, OUT+"/car_lusso.obj", 180.0, target={'w':1.80,'l':4.20},
     mtl_src=C1M, mtl_overrides={"Body":(0.07,0.07,0.09)})
# car2: nel file è girata di traverso; 23.6° la rimette col muso a -Z
bake(C2, OUT+"/car_economica.obj", 23.6, drop=("Platform",),
     target={'w':1.55,'l':3.10}, mtl_src=C2M,
     mtl_overrides={"car body":(0.80,0.78,0.72)})
# scooter: già col muso a -Z
bake(SC, OUT+"/motorino.obj", 0.0, target={'l':1.85}, mtl_src=SCM)
