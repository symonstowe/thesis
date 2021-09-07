%run C:\Users\symon\Documents\eidors-v3.10-ng\eidors-v3.10-ng\eidors\startup
figure(1)
clf;
imdl= mk_common_model('d2d1c',16);
% Create an homogeneous image
img_1 = mk_image(imdl);

show_fem(img_1);
axis off
print_convert('basic_mesh.png');

mdl = mk_library_model('adult_male_16el');
clf;
show_fem(mdl)
view([0 90])
axis off 
print_convert('human_mesh_empty.png');


mdl = mk_library_model('adult_male_16el_lungs');
img_1 = mk_image(mdl, 0.25); % background conductivity
img_1.elem_data([mdl.mat_idx{2};mdl.mat_idx{3}]) = 0.05; % lungs

clf;
show_fem(img_1)
view([0 90])
axis off
print_convert('human_mesh_lungs.png');

% Reconstruct some stuff
% start with file 4...

fmdl2 = load('C:\Users\symon\Dropbox\projects\CT_2_MESH\segment_editor\code\PTS4_fmdl.mat');
fmdl2 = fmdl2.fmdl;
% Move electrodes
renumber= [9,8,7,6,5,4,3,2,1,16,15,14,13,12,11,10];
fmdl2.fwd_model.electrode= fmdl2.fwd_model.electrode(renumber(:));
%keyboard


[vv, ~, ~]= eidors_readdata( 'C:\Users\symon\Dropbox\projects\CT_2_MESH\EIT-CT\2020_03_23\2432000_xueliu__0-12pep\2432000_xueliu__peep_12_001.eit', 'DRAEGER-EIT');
[stim,msel] = mk_stim_patterns(16,1,[0,1],[0,1],{'no_meas_current'},1);
vv = real(vv);
plot(sum(vv))
%keyboard
img = mk_image(fmdl2, 0.25); % background conductivity
img.elem_data([fmdl2.fwd_model.mat_idx{2};fmdl2.fwd_model.mat_idx{3}]) = 0.5; % lungs
figure(2)
subplot(121)
show_fem(img_1, [0 1.04])
subplot(122)
show_fem(img  , [0 1.04])
figure(1)
%keyboard
img.fwd_model.stimulation = stim;
img.fwd_model = mdl_normalize(img.fwd_model, 1);
opt.imgsz = [32 32];
opt.distr = 3; % non-random, uniform
opt.Nsim = 500; % 500 hundred targets to train on, seems enough
opt.target_size = 0.03; %small targets
opt.target_offset = 0;
opt.noise_figure = .5; % this is key!
opt.square_pixels = 1;
imdl=mk_GREIT_model(img, 0.25, [], opt);
imdl.fwd_model.meas_select = msel;

img_a= inv_solve(imdl, vv(:,58), vv(:,77));
img_b= inv_solve(imdl, vv(:,480), vv(:,511));
img_c= inv_solve(imdl, vv(:,1197), vv(:,1216));

breaths_1 = img_a;
temp = cat(3,img_a.elem_data,img_b.elem_data,img_c.elem_data);
breaths_1.elem_data = mean(temp,3);
show_fem(breaths_1)
axis off
print_convert('new_fem.png');


% Generic model
figure(1)
%keyboard
img_1.fwd_model.stimulation = stim;
img_1.fwd_model = mdl_normalize(img_1.fwd_model, 1);
opt.imgsz = [32 32];
opt.distr = 3; % non-random, uniform
opt.Nsim = 500; % 500 hundred targets to train on, seems enough
opt.target_size = 0.03; %small targets
opt.target_offset = 0;
opt.noise_figure = .5; % this is key!
opt.square_pixels = 1;
imdl=mk_GREIT_model(img_1, 0.25, [], opt);
imdl.fwd_model.meas_select = msel;

img_a= inv_solve(imdl, vv(:,58), vv(:,77));
img_b= inv_solve(imdl, vv(:,480), vv(:,511));
img_c= inv_solve(imdl, vv(:,1197), vv(:,1216));

breaths_1 = img_a;
temp = cat(3,img_a.elem_data,img_b.elem_data,img_c.elem_data);
breaths_1.elem_data = mean(temp,3);
show_fem(breaths_1)
axis off
print_convert('generic_fem.png');



% TODO 
% a) select all breaths 
% b) select all beats 
% c) plot average breath 
% d) plot average beat
% e) compare C and D with two different models



