function M = build_mesh(topo, A, lam, h, cfg)
%BUILD_MESH  Interface-conforming structured quad mesh of a bi-material strip.
%   Both constituents share the interface nodes (perfect bonding, no contact).
%   Sinusoidal / Triangle : single-valued interfaces -> interface-following columns
%   Dovetail              : re-entrant trapezoid -> sheared columns inside the
%                           band |y| <= A so that the flanks are grid lines.
%   Domain labels: 1 = bottom (substrate), 2 = top layer.

nw = cfg.n_wave;  W = nw*lam;  H = max(cfg.H_min, cfg.H_over_lambda*lam);
ic = (nw + 1)/2;  g = cfg.growth;
delta = 2*A*tand(cfg.dovetail_undercut_deg);
wt = lam/2 + delta;  wb = lam/2 - delta;         % dovetail: bottom tooth top/base widths
if strcmp(topo,'Dovetail') && (wb <= 0 || wt >= lam)
    error('Dovetail geometry infeasible for A=%g, lambda=%g', A, lam);
end

%% ---- lateral node distributions (top: y=+A side, bottom: y=-A side) ----
Xt = 0; Xb = 0; lab = [];
for p = 1:nw
    x0 = (p - 1)*lam;
    if abs(p - ic) <= 1, h0 = h;        hmax = cfg.hmax_factor*h;
    else,                h0 = 3*h;      hmax = max(cfg.hmax_factor*h, lam/25); end
    switch topo
        case 'Sinusoidal'
            bt = [0 .25 .75 1]*lam; bb = bt; cl = [0 1; 1 1; 1 0]; lb = [2 2 2];
        case 'Triangle'
            bt = [0 .5 1]*lam;      bb = bt; cl = [1 1; 1 1];      lb = [2 2];
        case 'Dovetail'
            bt = [0, lam/2 - wt/2, lam/2 + wt/2, lam];
            bb = [0, lam/2 - wb/2, lam/2 + wb/2, lam];
            cl = [0 1; 1 1; 1 0];  lb = [2 1 2];
        otherwise, error('Unknown topology %s', topo);
    end
    for k = 1:numel(bt) - 1
        [~, nT] = graded_nodes(x0+bt(k), x0+bt(k+1), cl(k,:), h0, hmax, g);
        [~, nB] = graded_nodes(x0+bb(k), x0+bb(k+1), cl(k,:), h0, hmax, g);
        N = max(nT, nB);
        xt = graded_nodes(x0+bt(k), x0+bt(k+1), cl(k,:), h0, hmax, g, N);
        xb = graded_nodes(x0+bb(k), x0+bb(k+1), cl(k,:), h0, hmax, g, N);
        Xt = [Xt, xt(2:end)]; Xb = [Xb, xb(2:end)]; lab = [lab, lb(k)*ones(1,N)]; %#ok<AGROW>
    end
end
nc = numel(Xt) - 1;

%% ---- node coordinates ----
if ~strcmp(topo,'Dovetail')
    X = Xt;  yi = yint_fun(topo, X, A, lam);
    dd = graded_depth(H, h, cfg);  nB = numel(dd) - 1;
    rows_b = zeros(nB+1, nc+1);
    for k = 1:nB+1
        d = dd(nB + 2 - k);  rows_b(k,:) = yi - d*(H + yi)/H;
    end
    rows_t = zeros(nB, nc+1);
    for m = 1:nB
        rows_t(m,:) = yi + dd(m+1)*(H - yi)/H;
    end
    Yn = [rows_b; rows_t];  Xn = repmat(X, size(Yn,1), 1);
    nr = size(Yn,1) - 1;
    dom = [ones(nB, nc); 2*ones(nB, nc)];
else
    dO = graded_depth(H - A, h, cfg);
    yb = graded_nodes(-A, A, [1 1], h, cfg.hmid_factor*h, g);
    yrow = [-A - fliplr(dO), yb(2:end), A + dO(2:end)].';
    nr = numel(yrow) - 1;
    Yn = repmat(yrow, 1, nc+1);  Xn = zeros(size(Yn));
    tol = 1e-12;
    for j = 1:nr+1
        y = yrow(j);
        if y <= -A + tol,      Xn(j,:) = Xb;
        elseif y >= A - tol,   Xn(j,:) = Xt;
        else,                  Xn(j,:) = Xb + (Xt - Xb)*(y + A)/(2*A);
        end
    end
    dom = zeros(nr, nc);
    for j = 1:nr
        if yrow(j+1) <= -A + tol,  dom(j,:) = 1;
        elseif yrow(j) >= A - tol, dom(j,:) = 2;
        else,                      dom(j,:) = lab;
        end
    end
end

%% ---- connectivity ----
[I, J] = meshgrid(1:nc, 1:nr);          % J rows, I columns
n1 = (J(:) - 1)*(nc + 1) + I(:);
Q  = [n1, n1 + 1, n1 + nc + 2, n1 + nc + 1];
dm = dom(sub2ind([nr nc], J(:), I(:)));
nodes = [reshape(Xn.', [], 1), reshape(Yn.', [], 1)];

%% ---- quality check (convexity / positive Jacobian at every corner) ----
xq = reshape(nodes(Q,1), [], 4);  yq = reshape(nodes(Q,2), [], 4);
cr = zeros(size(xq));
for c = 1:4
    nx_ = mod(c, 4) + 1;  pv = mod(c - 2, 4) + 1;
    ax = xq(:,nx_) - xq(:,c); ay = yq(:,nx_) - yq(:,c);
    bx = xq(:,pv)  - xq(:,c); by = yq(:,pv)  - yq(:,c);
    cr(:,c) = ax.*by - ay.*bx;
end
if any(cr(:) <= 0), error('Mesh has inverted/non-convex quads (%s, A=%g)', topo, A); end
ex = sqrt(diff(xq(:,[1 2 3 4 1]),1,2).^2 + diff(yq(:,[1 2 3 4 1]),1,2).^2);
M.quality.max_aspect = max(max(ex,[],2)./min(ex,[],2));
M.quality.min_jac_ratio = min(min(cr,[],2)./max(cr,[],2));

%% ---- interface polyline ----
switch topo
    case 'Sinusoidal'
        xs = unique([0:h/2:W, W]); poly = [xs(:), yint_fun(topo, xs(:), A, lam)];
    case 'Triangle'
        xs = (0:lam/2:W).'; poly = [xs, yint_fun(topo, xs, A, lam)];
    case 'Dovetail'
        poly = [0, -A];
        for p = 1:nw
            c = (p - 0.5)*lam;
            poly = [poly; c - wb/2, -A; c - wt/2, A; c + wt/2, A; c + wb/2, -A; p*lam, -A]; %#ok<AGROW>
        end
end

%% ---- element ordering (FEBio ids: bottom first, then top) ----
elemOrder = [find(dm == 1); find(dm == 2)];

%% ---- output struct ----
M.topo = topo; M.A = A; M.lambda = lam; M.h = h; M.W = W; M.H = H;
M.nodes = nodes; M.quads = Q; M.dom = dm; M.elemOrder = elemOrder;
M.nBottomElem = sum(dm == 1);
M.centroid = [mean(xq,2), mean(yq,2)];
M.poly = poly;
M.xa = (ic - 1)*lam; M.xb = ic*lam;               % central (assessed) wavelength
M.bottomNodes = find(abs(nodes(:,2) + H) < 1e-9);
M.topNodes    = find(abs(nodes(:,2) - H) < 1e-9);
[~, k] = min(abs(nodes(M.bottomNodes,1) - W/2));  M.centerNode = M.bottomNodes(k);
M.delta = delta; M.wt = wt; M.wb = wb;
M.nElem = size(Q,1); M.nNode2D = size(nodes,1);
end

function y = yint_fun(topo, x, A, lam)
switch topo
    case 'Sinusoidal', y = A*sin(2*pi*x/lam);
    case 'Triangle',   y = A*(4*abs(mod(x/lam, 1) - 0.5) - 1);
end
end
