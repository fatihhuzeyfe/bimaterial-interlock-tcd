function [pts, q, nv] = tcd_locus(poly, r, dom, xa, xb, H, cfg)
%TCD_LOCUS  Points of domain DOM whose Euclidean distance to the interface
%   polyline equals r (= L/2), restricted to the central wavelength [xa, xb].
%   For a re-entrant root this locus contains the classical Point-Method point
%   on the notch bisector; for smooth/flat interfaces it is the offset curve.
%   q  : nearest interface point of each locus point
%   nv : unit vector from q to the locus point (local interface normal)
ds = cfg.ds_locus;
P1 = poly(1:end-1,:);  P2 = poly(2:end,:);
keep = max(P1(:,1),P2(:,1)) >= xa - 2*r & min(P1(:,1),P2(:,1)) <= xb + 2*r;
P1 = P1(keep,:); P2 = P2(keep,:);
T = P2 - P1;  len = sqrt(sum(T.^2, 2));  tu = T ./ len;
nL = [-tu(:,2), tu(:,1)];                 % left normal -> points into the TOP domain
sg = 2*(dom == 2) - 1;                     % +1 top, -1 bottom

C = {};
for k = 1:size(P1,1)                       % offsets of every segment
    m = max(2, ceil(len(k)/ds) + 1);  u = linspace(0, 1, m).';
    C{end+1} = P1(k,:) + u*T(k,:) + r*sg*nL(k,:); %#ok<AGROW>
end
for k = 1:size(P1,1) - 1                   % arcs around corners
    if acosd(max(-1, min(1, dot(tu(k,:), tu(k+1,:))))) > cfg.corner_deg
        th = linspace(0, 2*pi, ceil(2*pi*r/ds) + 1).';
        C{end+1} = P2(k,:) + r*[cos(th), sin(th)]; %#ok<AGROW>
    end
end
pts = vertcat(C{:});
pts = pts(pts(:,1) >= xa & pts(:,1) <= xb, :);

% domain membership
topPoly = [poly; poly(end,1), H + 10; poly(1,1), H + 10];
inTop = inpolygon(pts(:,1), pts(:,2), topPoly(:,1), topPoly(:,2));
pts = pts((dom == 2) == inTop, :);

% exact distance to the interface; keep points whose distance is r
[d, q] = dist2poly(pts, P1, P2);
ok = d >= r*(1 - 1e-6);
pts = pts(ok,:); q = q(ok,:);
nv = (pts - q) ./ sqrt(sum((pts - q).^2, 2));
end

function [dmin, qmin] = dist2poly(p, P1, P2)
n = size(p,1); dmin = inf(n,1); qmin = zeros(n,2);
T = P2 - P1; l2 = sum(T.^2, 2).';
for a = 1:500:n
    b = min(n, a + 499); px = p(a:b,1); py = p(a:b,2);
    u = ((px - P1(:,1).').*T(:,1).' + (py - P1(:,2).').*T(:,2).') ./ l2;
    u = max(0, min(1, u));
    qx = P1(:,1).' + u.*T(:,1).';  qy = P1(:,2).' + u.*T(:,2).';
    dd = sqrt((px - qx).^2 + (py - qy).^2);
    [dm, im] = min(dd, [], 2);
    dmin(a:b) = dm;
    idx = sub2ind(size(dd), (1:numel(dm)).', im);
    qmin(a:b,:) = [qx(idx), qy(idx)];
end
end
