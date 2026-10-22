import struct, sys, numpy as np
class R:
    def __init__(s,b): s.b=b; s.p=0
    def u16(s): v=struct.unpack_from('<H',s.b,s.p)[0]; s.p+=2; return v
    def u32(s): v=struct.unpack_from('<I',s.b,s.p)[0]; s.p+=4; return v
    def f(s,n): v=struct.unpack_from('<%df'%n,s.b,s.p); s.p+=4*n; return v
    def bool(s): v=s.b[s.p]!=0; s.p+=1; return v
    def str(s): e=s.b.index(b'\n',s.p); v=s.b[s.p:e].decode(); s.p=e+1; return v
    def hdr(s):
        if s.p+6>len(s.b): return None,None
        i=s.u16(); l=s.u32(); return i,l
def geometry(r,end):
    n=r.u32(); elems=[]; bufs={}
    while r.p<end:
        st=r.p; cid,l=r.hdr()
        if cid==0x5100:
            ee=st+l
            while r.p<ee:
                s2=r.p; c2,l2=r.hdr()
                if c2!=0x5110: r.p=s2; break
                elems.append((r.u16(),r.u16(),r.u16(),r.u16(),r.u16()))
            r.p=ee
        elif cid==0x5200:
            bi=r.u16(); vs=r.u16(); s2=r.p; c2,l2=r.hdr(); assert c2==0x5210
            bufs[bi]=(vs,r.b[r.p:r.p+n*vs]); r.p=st+l
        else: r.p=st; break
    return n,elems,bufs
def load_mesh(path):
    b=open(path,'rb').read(); r=R(b); assert r.u16()==0x1000; print(r.str())
    out={'subs':[],'shared':None,'bw':[]}
    cid,l=r.hdr(); assert cid==0x3000; end=r.p-6+l; out['anim']=r.bool()
    while r.p<len(b)-6:
        st=r.p; cid,l=r.hdr()
        if cid==0x5000: out['shared']=geometry(r,st+l); r.p=st+l
        elif cid==0x4000:
            mat=r.str(); sh=r.bool(); ic=r.u32(); i32=r.bool()
            idx=np.frombuffer(r.b,dtype='<u4' if i32 else '<u2',count=ic,offset=r.p); r.p+=ic*(4 if i32 else 2)
            sub={'mat':mat,'shared':sh,'idx':idx,'bw':[]}
            if not sh:
                s2=r.p; c2,l2=r.hdr(); assert c2==0x5000; sub['geom']=geometry(r,s2+l2); r.p=s2+l2
            while r.p<len(b)-6:
                s2=r.p; c2,l2=r.hdr()
                if c2==0x4010: r.p=s2+l2
                elif c2==0x4100:
                    sub['bw'].append((r.u32(),r.u16(),r.f(1)[0])); r.p=s2+l2
                elif c2==0x4200: r.p=s2+l2
                else: r.p=s2; break
            out['subs'].append(sub)
        elif cid==0x6000: out['skel']=r.str(); r.p=st+l
        elif cid==0x7000: out['bw'].append((r.u32(),r.u16(),r.f(1)[0])); r.p=st+l
        else:
            print('chunk %x len %d'%(cid,l)); r.p=st+l
    return out
def attrs(g):
    n,elems,bufs=g; res={}
    for src,typ,sem,off,ix in elems:
        vs,data=bufs[src]; cnt={0:1,1:2,2:3,3:4}.get(typ)
        if cnt is None: print('skip type',typ,sem); continue
        a=np.ndarray((n,cnt),dtype='<f4',buffer=data,offset=off,strides=(vs,4)).copy()
        res[(sem,ix)]=a
    return res
def load_skel(path):
    b=open(path,'rb').read(); r=R(b); assert r.u16()==0x1000; print(r.str()); bones={}; parent={}
    while r.p<len(b)-6:
        st=r.p; cid,l=r.hdr()
        if cid==0x2000:
            name=r.str(); h=r.u16(); pos=r.f(3); q=r.f(4); sc=r.f(3) if l>=48 else (1,1,1)
            bones[h]=dict(name=name,pos=pos,q=q,scale=sc); continue
        elif cid==0x3000: c=r.u16(); p=r.u16(); parent[c]=p; continue
        else: print('skel chunk',hex(cid),l); r.p=st+l
    return bones,parent
if __name__=='__main__':
    m=load_mesh(sys.argv[1]); print('anim',m['anim'],'skel',m.get('skel'))
    if m['shared']: print('shared verts',m['shared'][0],m['shared'][1])
    for s in m['subs']:
        print(s['mat'],s['shared'],len(s['idx'])//3,'tris', 'bw',len(s['bw']), s.get('geom',[None,None])[:2])
    print('mesh bw',len(m['bw']))
    bones,parent=load_skel(sys.argv[2])
    for h,bn in sorted(bones.items()): print(h,bn['name'],parent.get(h),['%.3f'%v for v in bn['pos']],['%.3f'%v for v in bn['q']])
