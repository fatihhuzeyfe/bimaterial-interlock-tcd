"""Independent linear plane-strain solver (bilinear Q4 elements, 2x2 Gauss points)
used for solution verification of the FEBio results and for testing the MATLAB
post-processing chain without FEBio. It reads the meshes written by
generate_models.m and writes logfiles in the FEBio format (same file names).
Requirements: Python 3.9+, numpy, scipy.
Usage: python3 independent_solver.py <febio_models_dir> [filter_substring]
"""
import sys, os, time, numpy as np, scipy.io as sio, scipy.sparse as sp, scipy.sparse.linalg as spla

folder = sys.argv[1]; filt = sys.argv[2] if len(sys.argv) > 2 else ''
cf = 'ml_cases.mat' if os.path.exists(os.path.join(folder, 'ml_cases.mat')) else 'cases.mat'
C = sio.loadmat(os.path.join(folder, cf), squeeze_me=True, struct_as_record=False)
cases = np.atleast_1d(C['cases']); cfg = C['cfg']; mats = np.atleast_1d(cfg.mat); t = float(cfg.t)
g = np.array([-1, 1]) / np.sqrt(3.0)
GP = [(a, b) for a in g for b in g]

def dN(xi, eta):
    return 0.25*np.array([[-(1-eta), (1-eta), (1+eta), -(1+eta)],
                          [-(1-xi), -(1+xi), (1+xi), (1-xi)]])

def Dmat(E, nu):
    c = E/((1+nu)*(1-2*nu))
    return c*np.array([[1-nu, nu, 0], [nu, 1-nu, 0], [0, 0, (1-2*nu)/2]])

cache = {}
for cs in cases:
    if filt not in cs.base: continue
    tag = getattr(cs, 'tag', cs.base)
    if tag not in cache:
        cache = {tag: sio.loadmat(os.path.join(folder, f'mesh_{tag}.mat'), squeeze_me=True, struct_as_record=False)['M']}
    M = cache[tag]
    t0 = time.time()
    P = M.nodes; Q = M.quads.astype(int) - 1; dom = M.dom.astype(int)
    nn = P.shape[0]; ne = Q.shape[0]
    if hasattr(cs, 'Eratio'):
        Eb = float(cfg.ml.E_ref); Ds = {1: Dmat(Eb, cs.nuB), 2: Dmat(cs.Eratio*Eb, cs.nuT)}
    else:
        Ds = {1: Dmat(mats[int(cs.iBot)-1].E, mats[int(cs.iBot)-1].nu), 2: Dmat(mats[int(cs.iTop)-1].E, mats[int(cs.iTop)-1].nu)}
    X = P[Q]                                   # ne x 4 x 2
    Ke = np.zeros((ne, 8, 8)); Bs = []
    for (xi, eta) in GP:
        dn = dN(xi, eta)                        # 2x4
        J = np.einsum('ik,ekj->eij', dn, X)     # ne x 2 x 2
        detJ = J[:, 0, 0]*J[:, 1, 1] - J[:, 0, 1]*J[:, 1, 0]
        Jinv = np.stack([np.stack([J[:, 1, 1], -J[:, 0, 1]], -1), np.stack([-J[:, 1, 0], J[:, 0, 0]], -1)], 1)/detJ[:, None, None]
        dNx = np.einsum('eij,jk->eik', Jinv, dn) # ne x 2 x 4
        B = np.zeros((ne, 3, 8))
        B[:, 0, 0::2] = dNx[:, 0]; B[:, 1, 1::2] = dNx[:, 1]
        B[:, 2, 0::2] = dNx[:, 1]; B[:, 2, 1::2] = dNx[:, 0]
        Bs.append(B)
        for d in (1, 2):
            m = dom == d
            Ke[m] += np.einsum('eji,jk,ekl->eil', B[m], Ds[d], B[m]) * detJ[m, None, None]
    dofs = np.zeros((ne, 8), int); dofs[:, 0::2] = 2*Q; dofs[:, 1::2] = 2*Q + 1
    rows = np.repeat(dofs, 8, 1).ravel(); cols = np.tile(dofs, (1, 8)).ravel()
    K = sp.csr_matrix((Ke.ravel(), (rows, cols)), shape=(2*nn, 2*nn))
    bot = M.bottomNodes.astype(int) - 1; top = M.topNodes.astype(int) - 1; cen = int(M.centerNode) - 1
    fixed = np.r_[2*bot+1, 2*top+1, 2*cen]
    u = np.zeros(2*nn); U = float(cs.U); u[2*top+1] = U
    free = np.setdiff1d(np.arange(2*nn), fixed)
    rhs = -K[free][:, fixed] @ u[fixed]
    u[free] = spla.spsolve(K[free][:, free].tocsc(), rhs)
    Rf = K @ u
    ue = u[dofs]
    sig = np.zeros((ne, 3))
    for B in Bs:
        eps = np.einsum('eij,ej->ei', B, ue)
        for d in (1, 2):
            m = dom == d; sig[m] += eps[m] @ Ds[d].T
    sig /= 4.0
    order = M.elemOrder.astype(int) - 1
    Ry = Rf[2*top+1]                            # per unit thickness
    with open(os.path.join(folder, cs.stressLog), 'w') as f:
        f.write('*Title = surrogate\n')
        for step, fac in ((1, 0.5), (2, 1.0)):
            f.write(f'*Step  = {step}\n*Time  = {fac}\n*Data  = sx;sy;sxy\n')
            s = sig[order]*fac
            np.savetxt(f, np.c_[np.arange(1, ne+1), s], fmt='%d %.6e %.6e %.6e')
    with open(os.path.join(folder, cs.reactLog), 'w') as f:
        for step, fac in ((1, 0.5), (2, 1.0)):
            f.write(f'*Step  = {step}\n*Time  = {fac}\n*Data  = Ry\n')
            r3 = np.r_[Ry, Ry]*t/2*fac
            np.savetxt(f, np.c_[np.arange(1, r3.size+1), r3], fmt='%d %.6e')
    print(f'{cs.base:45s} ne={ne:6d}  P={Ry.sum():9.4f} N/mm  {time.time()-t0:5.1f}s', flush=True)
