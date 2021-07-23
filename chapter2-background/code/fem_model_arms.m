function [img,vv] = fem_model_arms( pp )
  pp = set_parameters( pp);

  yctr = ',-0.1,';
  vci = ['cylinder(-0.013',yctr,'0.5;-0.013',yctr,'0.7;0.01)'];
  vciv= ['cylinder(-0.013',yctr,'0.5;-0.013',yctr,'0.7;0.02)'];
  vci1 = 'plane(0,0,0.3;0,0,-1)';
  vci2 = 'plane(0,0,0.7;0,0, 1)';
 extra={'heart_','tissue'};
 [extra, whichels, elstr] = add_electrodes(extra, pp);
 extra{end+1} = 'arms';
 extra{end+1} = 'CUT';
 extra{end+1} = sprintf([ ...
    'solid CUT= orthobrick(-.25,-.28,%f;.25',yctr,'1);' ...
    'solid top= plane(0,0.1,1.0;0,0,1);' ...
    'solid nCUT= (not CUT) and top;' ...
    'solid vciv = ',vciv,' and ',vci1,' and ',vci2,';' ... 
    'solid heartt=sphere(0.05',yctr,'0.5;0.1)  or sphere(0.15',yctr,'0.5;0.05);' ...
    'solid heartb=sphere(0.05',yctr,'0.5;0.08) or sphere(0.15',yctr,'0.5;0.03);' ...
    'solid vci_= ',vci,' and ',vci1,' and ',vci2,';' ...
    'solid ballo= heartt or vciv and nCUT ;' ...
    'solid heart= heartb  -maxh=%f;' ...
    elstr, ...
    'solid heart_= nCUT and (heart  or vci_ ) and notels;' ...
    'solid tissue= nCUT and ' ...
         '( (ballo and notels and not( heart or ( vci_ )  )));' ...
    'solid rarm = cylinder(-0.35,0,.83;-0.40,0,0.78;.12);' ...
    'solid larm = cylinder( 0.35,0,.83; 0.40,0,0.78;.12);' ...
    'solid arms = nCUT and (rarm or larm) and orthobrick(-.5,-1,-1;.5,1,0.9);' ...
     ],pp.zCUT,pp.maxh);
  epos =[180,0.5;     0,0.5;
          90,0.5;   270,0.5;
         180,0.3;     0,0.7];
  fmdl= ng_mk_ellip_models([0.9,0.4,0.3],epos,[0.15,0.15,0.01],extra); 
  fmdl.nodes = fmdl.nodes/2;
  if pp.fShrink < 1; 
     fmdl = fem_shrink(fmdl, pp);
  end
  fmdl.mat_idx_to_electrode.nodes_electrode= true;
  if ~isempty(whichels)
  fmdl = mat_idx_to_electrode(fmdl,whichels);
  end

  mi = fmdl.mat_idx;
  img = mk_image(fmdl,pp.z_backgnd);
  img.elem_data(mi{2}) = pp.z_blood;
  img.elem_data(mi{3}) = pp.z_tissue;
  img.calc_colours.ref_level = pp.z_backgnd;

  img.fwd_solve.get_all_meas = true;

  if pp.zCUT<1 
     idx = false(1,num_elems(fmdl));
     idx(mi{end}) = true;
     img.fwd_model.elems(idx,:) = [];
     img.elem_data(idx) = [];
     img.fwd_model = remove_unused_nodes(img.fwd_model);
     for i=1:num_elecs(fmdl);
        img.fwd_model.electrode(i).nodes( img.fwd_model.electrode(i).nodes == 0) = [];
     end
  end


  if isfield(pp,'SSMM');
     img.fwd_model.stimulation = stim_meas_list(pp.SSMM,num_elecs(fmdl));
     vv = fwd_solve(img);
  else
     vv= [];
  end

function [extra, whichels, elstr] = add_electrodes(extra, pp);
   if isfield(pp,'extra_elec_xyzr');
      [extra, whichels, elstr] = spherical_elecs(extra, pp);
   elseif isfield(pp,'extra_cyl_elec');
      [extra, whichels, elstr] = cylindrical_elecs(extra, pp);
   else
      whichels={}; elstr = [];
      elstr= 'solid notels = plane(0,0,-1000;0,0,-1);'; % Far Far away
   end
    
function [extra, whichels, elstr] = cylindrical_elecs(extra, pp);
   whichels={}; elstr = [];
   pp = pp.extra_cyl_elec;
   p0 = pp.p0;
   nv = pp.nv/norm(pp.nv);
   rad= pp.rad;
   pl = {}; for i=1:length(pp.cut);
     pl{i} = sprintf('plane(%f,%f,%f;%f,%f,%f)',p0+pp.cut(i)*nv,-nv);
   end

   elstr= sprintf('solid elcyl= cylinder(%f,%f,%f;%f,%f,%f;%f) -maxh=%f;',p0,p0+nv,rad,pp.maxh);

   elstr=[ elstr, ...
     sprintf('solid notels = not (elcyl and %s and not(%s));',pl{1},pl{end}) ...
     ];

   for i=1:length(pl)-1
     elstr=[ elstr, ...
        sprintf('solid el%d= elcyl and %s and not( %s);', i,pl{i},pl{i+1}) ...
        sprintf('solid el%d_=  nCUT and el%d;',i,i) ...
     ];
     extra{end+1} = sprintf('el%d_',i);
     if rem(i,2); whichels{end+1} = length(extra)+1; end
   end

function [extra, whichels, elstr] = spherical_elecs(extra, pp);
   whichels={}; elstr = [];
   notels = [];
   for i=1:size(pp.extra_elec_xyzr,1)
      elstr = [elstr,  sprintf([ ...
        'solid el%d=   sphere(%f,%f,%f;%f);' ...
        'solid el%d_=  nCUT and el%d;' ...
              ], i,pp.extra_elec_xyzr(i,:), i,i)];
      extra{end+1} = sprintf('el%d_',i);
      whichels{end+1} = length(extra)+1;
      notels = [notels, sprintf('el%d or ',i)];
   end
   elstr = [elstr,  ...
      'solid notels = not (',notels(1:end-3),');'];

function pp = set_parameters( pp) ;
  if ~isfield(pp,'z_tissue');  pp.z_tissue = 0.2; end
  if ~isfield(pp,'z_blood');   pp.z_blood  = 0.7; end
  if ~isfield(pp,'z_backgnd'); pp.z_backgnd= 0.4; end
  if ~isfield(pp,'maxh');      pp.maxh=      0.007; end
  if ~isfield(pp,'zCUT');      pp.zCUT=      1.95; end
  if ~isfield(pp,'fShrink');  pp.fShrink =  1.0;  end
  if ~isfield(pp,'cShrink');  pp.cShrink =  [0.05,0.05,0.5]/2; end
