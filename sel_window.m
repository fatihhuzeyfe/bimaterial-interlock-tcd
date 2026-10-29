function sel = sel_window(Q, V, w, yl)
%SEL_WINDOW  Elements with at least one node inside [w(1) w(2)] x [yl(1) yl(2)].
%   Avoids the jagged, unfilled margins that a centroid-based selection leaves near the
%   plot limits where the far-field elements are large. Q: quads (node ids), V: node coordinates.
in = V(:,1) >= w(1) & V(:,1) <= w(2) & V(:,2) >= yl(1) & V(:,2) <= yl(2);
sel = any(in(Q), 2);
end
