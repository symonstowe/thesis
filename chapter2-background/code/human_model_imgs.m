% Human model with the equipotential lines and maybe some lungs
mp = struct;
pp.extra_elec_xyzr= 1/50*[ ...
    5    5  23    0.05
    5.4  5  22.6  0.05];                                  

opt.edge.width=0;
opt.edge.significant.viewpoint_dependent.callback = false;
xl = [-20,20];zl=[0,45];
CMAP = abs(linspace(-1,1,254)'); CMAP(CMAP<0.1)=1;
CMAP = [0*CMAP+1,CMAP,CMAP];
for fn = [5,9]; do_imgc = false;
   elcut = []; axlim= [];
   switch fn;
   case 1; pp.zCUT = 1.5;
           SSMM = [3,4,3,4];
           contours = linspace(-0.1,0.1,99);
           x_pts = linspace(-5,10,301); y_pts = linspace(20,30,201);
   case 2; pp.zCUT = 1.5;
           SSMM = [5,6,5,6];
           contours = linspace(-0.1,0.1,99);
           x_pts = linspace(-5,10,151); y_pts = linspace(20,30,101);
   case 3; pp.zCUT = 1.5;
           SSMM = [3,8,3,8];
           contours = linspace(-0.7,0.7,41); contours=sign(contours).*abs(contours).^1.4;
           x_pts = linspace(-5,10,301); y_pts = linspace(20,30,201);
   case 4; pp.zCUT = 1.5;
           SSMM = [8,7,8,7];
           contours = linspace(-1.0,1.0,99);
           x_pts = linspace(-5,10,151); y_pts = linspace(20,30,101);
   case 5; do_imgc =-0.1; contours = linspace(-0.1,0.1,99);
           opt.viewpoint = struct('el', 11, 'az',-11);
           pp.zCUT = 1.5; SSMM = [3,4,3,4];
           x_pts = linspace(-12.5,12.5,151); y_pts = linspace(0,55,331);

   case 6; do_imgc =-0.1; contours = linspace(-0.1,0.1,99);
           opt.viewpoint = struct('el', 11, 'az',-11);

           pp.zCUT = 1.5; SSMM = [5,6,5,6];
           x_pts = linspace(-12.5,12.5,151); y_pts = linspace(0,55,331);

   case 7; do_imgc =-0.1; contours = linspace(-0.1,0.1,99);
           opt.viewpoint = struct('el', 11, 'az',-11);
           elcut = [3:6]; axlim= [-6,10,15,35];
           pp.zCUT = 1.5; SSMM = [3,4,3,4];
           x_pts = linspace(-12.5,12.5,151); y_pts = linspace(0,55,331);

   case 8; do_imgc =-0.1; contours = linspace(-0.3,0.3,29);
           opt.viewpoint = struct('el',  0, 'az',  0);
           elcut = [1:6]; axlim= [-2,8,20,30];
           pp.zCUT = 1.5; SSMM = [1,8,1,8];
           x_pts = linspace(-12.5,12.5,151); y_pts = linspace(0,55,331);
   case 9; do_imgc = 1.5; contours = linspace(-0.1,0.1,99);
           opt.viewpoint = struct('el', 11, 'az',-11);
           pp.zCUT = 1.5; SSMM = [3,4,3,4];
           x_pts = linspace(-12.5,12.5,151); y_pts = linspace(0,55,331);
           elcut = []; axlim= NaN;

   otherwise; break
   end
   msm = struct('level',[inf,5,inf], 'x_pts', x_pts, 'y_pts', y_pts);

   img = fem_model_arms( pp) ;
   img.fwd_model.nodes = img.fwd_model.nodes *100; % cm
   img.calc_colours.clim= 0.5;

   img.fwd_model.stimulation = stim_meas_list(SSMM,num_elecs(img));
   img.fwd_solve.get_all_nodes = true;
   vh = fwd_solve(img);
   imgr = rmfield(img,'elem_data');
   imgr.node_data = vh.volt;
   imgr.fwd_model.mdl_slice_mapper = msm;
%  Filt = ones(3)/9; Filt = conv2(Filt,Filt);
%  imgr.calc_slices.filter = Filt;
   imgr = calc_slices(imgr);

   f = figure(fn);
   set(f,'renderer','painters');
   if do_imgc ~= 0
       pp.zCUT = do_imgc; cm = -12;
       imgc= fem_model_arms(pp);
       if elcut; imgc.fwd_model.electrode(elcut) = []; end
       if all(isnan(axlim)) && ~isempty(axlim)
           imgc.elem_data(:) = imgc.calc_colours.ref_level;
       else
           imgc = crop_model(imgc,@(x,y,z) y<cm/100);
       end
       imgc.fwd_model.nodes =  100*imgc.fwd_model.nodes;
       imgc.fwd_model.nodes(:,2) = imgc.fwd_model.nodes(:,2) - 5;
       imgc.calc_colours.clim = .5;
       imgc.calc_colours.cmap_type = CMAP;
       show_fem_enhanced(imgc,opt)
       if all(isnan(axlim)) && ~isempty(axlim)
       else
           if any(axlim); xlim(axlim(1:2)); zlim(axlim(3:4)); end
           hold on
           clear FakeVol; for fi=1:2; % Horrible to fight matlab 
               FakeVol(fi,:,:) = permute(imgr,[3,2,1]);
           end
           hh=contourslice(x_pts, [-15,15],y_pts, FakeVol, ...
                [],-10.5,[], contours);
           for hi = hh;
               set(hh,'EdgeColor', .5*[1,1,1],'LineWidth',1);
           end
           hold off
       end
   else
       img.fwd_model.mdl_slice_mapper = msm;
       img.show_slices.axes_msm= true;
       img.calc_colours.cmap_type = CMAP;
       show_slices(img);
       hold on
       contour(x_pts, y_pts, imgr, contours,'Color',.5*[1,1,1],'LineWidth',1);
       hold off
   end
   axis off
end
PrOpt.resolution = 150;