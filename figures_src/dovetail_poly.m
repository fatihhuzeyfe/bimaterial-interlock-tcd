function P = dovetail_poly(nw, lam, A, theta)
%DOVETAIL_POLY  Vertices of an nw-period trapezoidal dovetail interface on [0, nw*lam].
d = 2*A*tand(theta); wt = lam/2 + d; wb = lam/2 - d; P = [0, -A];
for p = 1:nw
    c = (p - 0.5)*lam;
    P = [P; c - wb/2, -A; c - wt/2, A; c + wt/2, A; c + wb/2, -A; p*lam, -A]; %#ok<AGROW>
end
end
