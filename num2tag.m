function s = num2tag(v)
%NUM2TAG  0.5 -> '0p5' (file-name safe)
s = strrep(sprintf('%g', v), '.', 'p');
end
