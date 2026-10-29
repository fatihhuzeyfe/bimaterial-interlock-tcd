function T = make_tied_mesh(M)
%MAKE_TIED_MESH  Same mesh as M, but the top-layer elements use duplicated interface
%   nodes, so that the constituents are connected only through a tied contact.
%   T.iface_bot / T.iface_top: interface edges [n1 n2] (2D ids) oriented counter-clockwise
%   with respect to their own element (outward facet normal in 3D).
T = M; Q = M.quads; d = M.dom; N2 = M.nNode2D;
nb = unique(Q(d == 1, :)); nt = unique(Q(d == 2, :));
iface = intersect(nb, nt);                         % nodes shared by both constituents
newId = zeros(N2, 1); newId(iface) = N2 + (1:numel(iface)).';
T.nodes = [M.nodes; M.nodes(iface, :)];
Qt = Q(d == 2, :); m = ismember(Qt, iface); Qt(m) = newId(Qt(m)); T.quads(d == 2, :) = Qt;
T.nNode2D = size(T.nodes, 1);
% interface edges: edges of bottom elements whose (original) node pair also bounds a top element
E = @(q) [q(:,[1 2]); q(:,[2 3]); q(:,[3 4]); q(:,[4 1])];
Eb = E(Q(d == 1, :)); Et = E(Q(d == 2, :));
kb = sort(Eb, 2); kt = sort(Et, 2);
[isb, ~] = ismember(kb, kt, 'rows'); [ist, ~] = ismember(kt, kb, 'rows');
T.iface_bot = Eb(isb, :);
Ett = Et(ist, :); T.iface_top = newId(Ett);       % top facets with duplicated ids
T.nIfaceNodes = numel(iface);
end
