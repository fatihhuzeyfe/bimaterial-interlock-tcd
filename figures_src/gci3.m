function G = gci3(h, f)
%GCI3  Grid convergence index (Roache 1994; Celik et al. 2008) from three meshes.
%   h = element sizes (any order), f = corresponding solution values.
[h, o] = sort(h(:)); f = f(o);                 % h(1) finest
r21 = h(2)/h(1); r32 = h(3)/h(2);
e21 = f(2) - f(1); e32 = f(3) - f(2);
s = sign(e32/e21);
p = abs(log(abs(e32/e21)))/log(r21);           % fixed-point iteration for non-constant r
for it = 1:50
    q = log((r21^p - s)/(r32^p - s)); p = abs(log(abs(e32/e21)) + q)/log(r21);
end
G.p = p;
G.f_ext = (r21^p*f(1) - f(2))/(r21^p - 1);     % Richardson extrapolation
G.e_a21 = abs((f(1) - f(2))/f(1));
G.GCI_fine = 1.25*G.e_a21/(r21^p - 1);
G.GCI_coarse = 1.25*abs((f(2) - f(3))/f(2))/(r32^p - 1);
G.asymptotic = G.GCI_coarse/(r21^p*G.GCI_fine);  % ~1 in the asymptotic range
G.monotonic = s > 0;
end
