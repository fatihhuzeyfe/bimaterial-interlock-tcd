function write_feb(fname, M, matTop, matBot, U, cfg, stressLog, reactLog)
%WRITE_FEB  FEBio 3.0 input file: 2.5D plane-strain hex8 slab, shared interface
%   nodes (perfect bonding), two load steps (0.5U and U) for the linearity check.
N2 = M.nNode2D;  t = cfg.t;
P  = [M.nodes, zeros(N2,1); M.nodes, t*ones(N2,1)];
Q  = M.quads(M.elemOrder, :);
H8 = [Q, Q + N2];
nb = M.nBottomElem;  ne = size(H8,1);

fid = fopen(fname, 'w');
if fid < 0, error('Cannot open %s', fname); end
c = onCleanup(@() fclose(fid));
v4 = ~isfield(cfg, 'feb_version') || strcmp(cfg.feb_version, '4.0');
if v4, spec = '4.0'; else, spec = '3.0'; end
fprintf(fid, '<?xml version="1.0" encoding="ISO-8859-1"?>\n<febio_spec version="%s">\n', spec);
fprintf(fid, '\t<Module type="solid"/>\n');

fprintf(fid, '\t<Control>\n\t\t<analysis>STATIC</analysis>\n');
fprintf(fid, '\t\t<time_steps>2</time_steps>\n\t\t<step_size>0.5</step_size>\n');
if v4
    fprintf(fid, '\t\t<solver type="solid">\n\t\t\t<max_refs>15</max_refs>\n');
    fprintf(fid, '\t\t\t<qn_method type="BFGS">\n\t\t\t\t<max_ups>0</max_ups>\n\t\t\t</qn_method>\n');
else
    fprintf(fid, '\t\t<solver>\n\t\t\t<max_refs>15</max_refs>\n\t\t\t<max_ups>0</max_ups>\n');
end
fprintf(fid, '\t\t\t<dtol>0.0001</dtol>\n\t\t\t<etol>0.001</etol>\n\t\t\t<rtol>0</rtol>\n\t\t\t<lstol>0.9</lstol>\n');
fprintf(fid, '\t\t</solver>\n\t</Control>\n');

fprintf(fid, '\t<Material>\n');
fprintf(fid, '\t\t<material id="1" name="Mat_Bottom" type="neo-Hookean">\n\t\t\t<density>1</density>\n\t\t\t<E>%.4f</E>\n\t\t\t<v>%.4f</v>\n\t\t</material>\n', matBot.E, matBot.nu);
fprintf(fid, '\t\t<material id="2" name="Mat_Top" type="neo-Hookean">\n\t\t\t<density>1</density>\n\t\t\t<E>%.4f</E>\n\t\t\t<v>%.4f</v>\n\t\t</material>\n', matTop.E, matTop.nu);
fprintf(fid, '\t</Material>\n');

fprintf(fid, '\t<Mesh>\n\t\t<Nodes name="All_Nodes">\n');
fprintf(fid, '\t\t\t<node id="%d">%.9f,%.9f,%.9f</node>\n', [(1:2*N2); P.']);
fprintf(fid, '\t\t</Nodes>\n');
fprintf(fid, '\t\t<Elements type="hex8" name="Bottom">\n');
fprintf(fid, '\t\t\t<elem id="%d">%d,%d,%d,%d,%d,%d,%d,%d</elem>\n', [(1:nb); H8(1:nb,:).']);
fprintf(fid, '\t\t</Elements>\n');
fprintf(fid, '\t\t<Elements type="hex8" name="Top">\n');
fprintf(fid, '\t\t\t<elem id="%d">%d,%d,%d,%d,%d,%d,%d,%d</elem>\n', [(nb+1:ne); H8(nb+1:ne,:).']);
fprintf(fid, '\t\t</Elements>\n');
write_nset(fid, 'FixedBase_Y',   [M.bottomNodes; M.bottomNodes + N2], v4);
write_nset(fid, 'FixedBase_X',   [M.centerNode;  M.centerNode + N2], v4);
write_nset(fid, 'TopPull',       [M.topNodes;    M.topNodes + N2], v4);
write_nset(fid, 'PlaneStrain_Z', (1:2*N2).', v4);
tied = isfield(M, 'iface_bot');
if tied
    fb = [M.iface_bot, M.iface_bot(:,[2 1]) + N2]; ft = [M.iface_top, M.iface_top(:,[2 1]) + N2];
    fprintf(fid, '\t\t<Surface name="Iface_Bottom">\n');
    fprintf(fid, '\t\t\t<quad4 id="%d">%d,%d,%d,%d</quad4>\n', [(1:size(fb,1)); fb.']);
    fprintf(fid, '\t\t</Surface>\n\t\t<Surface name="Iface_Top">\n');
    fprintf(fid, '\t\t\t<quad4 id="%d">%d,%d,%d,%d</quad4>\n', [(1:size(ft,1)); ft.']);
    fprintf(fid, '\t\t</Surface>\n\t\t<SurfacePair name="Tied_Interface">\n\t\t\t<primary>Iface_Bottom</primary>\n\t\t\t<secondary>Iface_Top</secondary>\n\t\t</SurfacePair>\n');
end
fprintf(fid, '\t</Mesh>\n');

fprintf(fid, '\t<MeshDomains>\n\t\t<SolidDomain name="Bottom" mat="Mat_Bottom"/>\n');
fprintf(fid, '\t\t<SolidDomain name="Top" mat="Mat_Top"/>\n\t</MeshDomains>\n');

fprintf(fid, '\t<Boundary>\n');
if v4
    zd = '\t\t<bc name="%s" node_set="%s" type="zero displacement">\n\t\t\t<x_dof>%d</x_dof>\n\t\t\t<y_dof>%d</y_dof>\n\t\t\t<z_dof>%d</z_dof>\n\t\t</bc>\n';
    fprintf(fid, zd, 'FixY', 'FixedBase_Y', 0, 1, 0);
    fprintf(fid, zd, 'FixX', 'FixedBase_X', 1, 0, 0);
    fprintf(fid, zd, 'FixZ', 'PlaneStrain_Z', 0, 0, 1);
    fprintf(fid, '\t\t<bc name="Pull" node_set="TopPull" type="prescribed displacement">\n\t\t\t<dof>y</dof>\n');
    fprintf(fid, '\t\t\t<value lc="1">%.8f</value>\n\t\t\t<relative>0</relative>\n\t\t</bc>\n', U);
else
    fprintf(fid, '\t\t<bc type="fix" node_set="FixedBase_Y">\n\t\t\t<dofs>y</dofs>\n\t\t</bc>\n');
    fprintf(fid, '\t\t<bc type="fix" node_set="FixedBase_X">\n\t\t\t<dofs>x</dofs>\n\t\t</bc>\n');
    fprintf(fid, '\t\t<bc type="fix" node_set="PlaneStrain_Z">\n\t\t\t<dofs>z</dofs>\n\t\t</bc>\n');
    fprintf(fid, '\t\t<bc type="prescribe" node_set="TopPull">\n\t\t\t<dof>y</dof>\n');
    fprintf(fid, '\t\t\t<scale lc="1">%.8f</scale>\n\t\t</bc>\n', U);
end
fprintf(fid, '\t</Boundary>\n');
if tied
    fprintf(fid, '\t<Contact>\n\t\t<contact type="tied-facet-on-facet" surface_pair="Tied_Interface">\n');
    fprintf(fid, '\t\t\t<laugon>0</laugon>\n\t\t\t<tolerance>0.2</tolerance>\n\t\t\t<penalty>%g</penalty>\n', cfg.tied_penalty);
    fprintf(fid, '\t\t</contact>\n\t</Contact>\n');
end

fprintf(fid, '\t<LoadData>\n\t\t<load_controller id="1" name="LC1" type="loadcurve">\n');
fprintf(fid, '\t\t\t<interpolate>LINEAR</interpolate>\n\t\t\t<extend>CONSTANT</extend>\n\t\t\t<points>\n');
if v4, pt = 'pt'; else, pt = 'point'; end
fprintf(fid, '\t\t\t\t<%s>0,0</%s>\n\t\t\t\t<%s>1,1</%s>\n', pt, pt, pt, pt);
fprintf(fid, '\t\t\t</points>\n\t\t</load_controller>\n\t</LoadData>\n');

fprintf(fid, '\t<Output>\n\t\t<plotfile type="febio">\n');
fprintf(fid, '\t\t\t<var type="displacement"/>\n\t\t\t<var type="stress"/>\n\t\t</plotfile>\n');
fprintf(fid, '\t\t<logfile>\n');
fprintf(fid, '\t\t\t<element_data data="sx;sy;sxy" file="%s"/>\n', stressLog);
fprintf(fid, '\t\t\t<node_data data="Ry" node_set="TopPull" file="%s"/>\n', reactLog);
fprintf(fid, '\t\t</logfile>\n\t</Output>\n</febio_spec>\n');
end

function write_nset(fid, name, ids, v4)
fprintf(fid, '\t\t<NodeSet name="%s">\n', name);
if v4
    for a = 1:16:numel(ids)
        b = min(numel(ids), a + 15);
        str = sprintf('%d,', ids(a:b));
        if b == numel(ids), str(end) = []; end
        fprintf(fid, '\t\t\t%s\n', str);
    end
else
    fprintf(fid, '\t\t\t<n id="%d"/>\n', ids);
end
fprintf(fid, '\t\t</NodeSet>\n');
end
