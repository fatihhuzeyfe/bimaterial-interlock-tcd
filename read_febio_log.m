function B = read_febio_log(fname)
%READ_FEBIO_LOG  Parses an FEBio logfile (node_data / element_data).
%   B(k).time, B(k).names (cell), B(k).data = [id, v1, v2, ...]
txt = strrep(fileread(fname), ',', ' ');
L = regexp(txt, '\r?\n', 'split');
B = struct('time', {}, 'names', {}, 'data', {});
k = 0; t = NaN; names = {}; i = 1; n = numel(L);
while i <= n
    s = strtrim(L{i});
    if strncmp(s, '*Time', 5)
        t = sscanf(s(strfind(s,'=')+1:end), '%f');
    elseif strncmp(s, '*Data', 5)
        names = strtrim(strsplit(strtrim(s(strfind(s,'=')+1:end)), ';'));
        j = i + 1;
        while j <= n && ~isempty(strtrim(L{j})) && L{j}(1) ~= '*', j = j + 1; end
        v = sscanf(strjoin(L(i+1:j-1), ' '), '%f');
        nc = 1 + numel(names);
        k = k + 1;
        B(k).time = t; B(k).names = names;
        B(k).data = reshape(v, nc, []).';
        i = j - 1;
    end
    i = i + 1;
end
if k == 0, error('No data blocks found in %s', fname); end
end
