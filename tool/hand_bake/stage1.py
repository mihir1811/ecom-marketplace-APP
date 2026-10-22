# Load scan, skeleton world joints, mirror into hand frame (left hand: x thumb-ward, y fingers, z dorsal).
import numpy as np, ogre
def qmat(q):
    x,y,z,w=q
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
def load():
    m=ogre.load_mesh('../libhand/hand.mesh'); a=ogre.attrs(m['shared'])
    P=a[(1,0)].astype(np.float64); UV=a[(7,0)].astype(np.float64)
    F=m['subs'][0]['idx'].reshape(-1,3).astype(np.int64)
    Fc=m['subs'][1]['idx'].reshape(-1,3).astype(np.int64)
    bones,parent=ogre.load_skel('../libhand/hand.skeleton')
    nb=len(bones); W=np.zeros((len(P),nb))
    for vi,b,w in m['bw']: W[vi,b]+=w
    W/=np.maximum(W.sum(1,keepdims=True),1e-9)
    world={}
    def wt(h):
        if h in world: return world[h]
        bn=bones[h]; L=np.eye(4); L[:3,:3]=qmat(bn['q'])*np.array(bn['scale']); L[:3,3]=bn['pos']
        world[h]=(wt(parent[h])@L) if h in parent else L
        return world[h]
    for h in bones: wt(h)
    names={bones[h]['name']:h for h in bones}
    return P,UV,F,Fc,W,world,names
M=np.array([[0,-1,0],[-1,0,0],[0,0,1.0]])  # mirror: right scan -> left hand
if __name__=='__main__':
    P,UV,F,Fc,W,world,names=load()
    for n,h in sorted(names.items(),key=lambda t:t[1]):
        j=world[h][:3,3]; print('%-14s'%n, np.round(M@j,3), 'verts>0.5:',int((W[:,h]>0.5).sum()))
    Q=P@M.T; print('hand frame bounds',Q.min(0),Q.max(0))
