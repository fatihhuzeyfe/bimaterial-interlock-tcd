function [alpha, beta] = dundurs(E1, nu1, E2, nu2)
%DUNDURS  Plane-strain Dundurs parameters (material 1 = evaluated constituent).
mu1 = E1/(2*(1 + nu1)); mu2 = E2/(2*(1 + nu2)); k1 = 3 - 4*nu1; k2 = 3 - 4*nu2;
den = mu1*(k2 + 1) + mu2*(k1 + 1);
alpha = (mu1*(k2 + 1) - mu2*(k1 + 1))/den;
beta  = (mu1*(k2 - 1) - mu2*(k1 - 1))/den;
end
