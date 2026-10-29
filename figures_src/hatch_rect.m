function hatch_rect(x0, x1, y0, y1, ang, sp, col)
%HATCH_RECT  Parallel hatch lines at angle ANG (deg) clipped to [x0,x1]x[y0,y1].
t = tand(ang); span = (x1 - x0)*abs(t);
for c = (y0 - span - abs(t)*abs(x0) - abs(t)*abs(x1)):sp:(y1 + span + abs(t)*abs(x0) + abs(t)*abs(x1))
    xs = [x0, x1, (y0 - c)/t, (y1 - c)/t]; ys = t*xs + c;
    ok = xs >= x0 - 1e-9 & xs <= x1 + 1e-9 & ys >= y0 - 1e-9 & ys <= y1 + 1e-9;
    xs = xs(ok); ys = ys(ok);
    if numel(xs) >= 2
        [xs, o] = sort(xs); ys = ys(o);
        plot(xs([1 end]), ys([1 end]), '-', 'Color', col, 'LineWidth', 0.4);
    end
end
end
