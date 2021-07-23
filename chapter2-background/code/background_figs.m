% Generate a sample image of EIT on a human thorax image
f = figure(1);
set(gcf,'renderer','painters');
set(groot,'defaultAxesTickLabelInterpreter','latex');  
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
clf;
tiledlayout(1,3, 'Padding', 'none', 'TileSpacing', 'compact');
% A) plot the boundary of the lungs and the chest 
	% Fill to make it look a bit like a body
% get contours
thorax = shape_library('get','adult_male','boundary');
rlung  = shape_library('get','adult_male','right_lung');
llung  = shape_library('get','adult_male','left_lung');
thorax(end+1,:) = thorax(1,:);
thorax2 = thorax;
rlung(end+1,:) = rlung(1,:);
llung(end+1,:) = llung(1,:);
nexttile 
dat = thorax;
fill(dat(:,1),dat(:,2),[200,200,200]/255)
hold on 
dat = rlung;
fill(dat(:,1),dat(:,2),[145,191,219]/255)
dat = llung;
fill(dat(:,1),dat(:,2),[145,191,219]/255)
axis off
axis equal
xlim([-1 1.25])
ylim([-0.7 1])
set(get(gca, 'XLabel'), 'String', '(A)');
ax = gca;
ax.XLabel.Visible = 'on';
set(gca,'FontSize',20);
hold off
% B) Generate a model 
thorax(end,:) = [];
rlung(end,:) = [];
llung(end,:) = [];

shape = { 1,                      % height
          {thorax, rlung, llung}, % contours
          [4,50],                 % perform smoothing with 50 points
          0.04};                  % small maxh (fine mesh)

elec_pos = [ 16,                  % number of elecs per plane
             1,                   % equidistant spacing
             0.5]';               % a single z-plane
         
elec_shape = [0.05,               % radius
              0,                  % circular electrode
              0.01 ]';             % maxh (electrode refinement) 

fmdl = ng_mk_extruded_model(shape, elec_pos, elec_shape);
% Make lines for each electrode
nexttile
plot(thorax2(:,1),thorax2(:,2),'k','lineWidth',2)
hold on
% Plot the current injection 
for i=1:size(fmdl.electrode,2)
	elec_nodes = fmdl.electrode(i).nodes;
	elec_pts = fmdl.nodes(elec_nodes,1:2);
	if  i == 16
		elec_pt(1,:) = [mean(elec_pts(:,1)), mean(elec_pts(:,2))];
	elseif i == 5
		elec_pt(2,:) = [mean(elec_pts(:,1)), mean(elec_pts(:,2))];
	end
end
plot([elec_pt(1,1),elec_pt(1,1),elec_pt(1,1)+1.1],[elec_pt(1,2),elec_pt(1,2)+.15,elec_pt(1,2)+.15],'k','lineWidth',2)
plot([elec_pt(1,1)+1.35,elec_pt(1,1)+1.40,elec_pt(1,1)+1.40,elec_pt(2,1)], ...
     [elec_pt(1,2)+.15 ,elec_pt(1,2)+.15 ,elec_pt(2,2)     ,elec_pt(2,2)],'k','lineWidth',2)
xa = [elec_pt(1,1)+1.14,elec_pt(1,1)+1.31];
ya = [elec_pt(1,2)+.10,elec_pt(1,2)+.10];
% now you can use data units
a = annotation('arrow');
a.Parent = f.CurrentAxes;  % associate annotation with current axes
a.X = xa;
a.Y = ya;
a = annotation('ellipse');
a.Parent = f.CurrentAxes;  % associate annotation with current axes
a.Position = [elec_pt(1,1)+1.1,elec_pt(1,2)+0.025,0.25,0.25];
a.LineWidth = 2;
a = annotation('textbox','interpreter','latex');
a.FontSize = 18;
a.String = '\emph{I}';
a.LineStyle = 'none';
a.Parent = f.CurrentAxes;  % associate annotation with current axes
a.Position = [elec_pt(1,1)+1.17,elec_pt(1,2)+0.08,0.15,0.15];
%annotation('arrow',xa,ya);
% 
[stim,meas_sel] = mk_stim_patterns(16,1,[0,1],[0,1],{'no_meas_current'}, 1);
fmdl.stimulation = stim;
img=mk_image(fmdl,1);
img.elem_data(fmdl.mat_idx{2})= 0.3; % rlung
img.elem_data(fmdl.mat_idx{3})= 0.3; % llung
img_v = img;
% Stimulate between elecs 16 and 5 to get more interesting pattern
img_v.fwd_model.stimulation(1).stim_pattern = sparse([16;5],1,[1,-1],16,1);
img_v.fwd_solve.get_all_meas = 1;
vh = fwd_solve(img_v);
img_v.fwd_model.mdl_slice_mapper.npx = 1000;
img_v.fwd_model.mdl_slice_mapper.npy = 1000;
PLANE= [inf,inf,0.5];
img_v.fwd_model.mdl_slice_mapper.level = PLANE;

% Calculate at high resolution
q = show_current(img_v, vh.volt(:,1));

%pic = shape_library('get','adult_male','pic');
%imagesc(pic.X, pic.Y, pic.img);
% imgt= flipdim(imread('thorax-mdl.jpg'),1); imagesc(imgt);
%colormap(gray(256)); set(gca,'YDir','normal');
%hold on

sx = linspace(-.5,.5,15)';
sy = 0.05 + linspace(-.5,.5,15)';
hh=streamline(q.xp,q.yp, q.xc, q.yc,sx,sy); set(hh,'Linewidth',2, 'color',[43,131,186]/256);
hh=streamline(q.xp,q.yp,-q.xc,-q.yc,sx,sy); set(hh,'Linewidth',2, 'color',[43,131,186]/256);
for i=1:size(fmdl.electrode,2)
	elec_nodes = fmdl.electrode(i).nodes;
	elec_pts = fmdl.nodes(elec_nodes,1:2);
	plot(elec_pts(:,1),elec_pts(:,2),'lineWidth',5,'Color',[26,150,65]/256)
end
axis equal
xlim([-1 1.25])
ylim([-0.7 1])
set(get(gca, 'XLabel'), 'String', '(B)');
ax = gca;
ax.XLabel.Visible = 'on';
set(gca,'FontSize',20);
axis off

% D) Show the equipotential lines 
nexttile
plot(thorax2(:,1),thorax2(:,2),'k','lineWidth',2)
hold on
% Plot the current injection 
for i=1:size(fmdl.electrode,2)
	elec_nodes = fmdl.electrode(i).nodes;
	elec_pts = fmdl.nodes(elec_nodes,1:2);
	if  i == 16
		elec_pt(1,:) = [mean(elec_pts(:,1)), mean(elec_pts(:,2))];
	elseif i == 5
		elec_pt(2,:) = [mean(elec_pts(:,1)), mean(elec_pts(:,2))];
	end
end
plot([elec_pt(1,1),elec_pt(1,1),elec_pt(1,1)+1.1],[elec_pt(1,2),elec_pt(1,2)+.15,elec_pt(1,2)+.15],'k','lineWidth',2)
plot([elec_pt(1,1)+1.35,elec_pt(1,1)+1.40,elec_pt(1,1)+1.40,elec_pt(2,1)], ...
     [elec_pt(1,2)+.15 ,elec_pt(1,2)+.15 ,elec_pt(2,2)     ,elec_pt(2,2)],'k','lineWidth',2)
xa = [elec_pt(1,1)+1.14,elec_pt(1,1)+1.31];
ya = [elec_pt(1,2)+.10,elec_pt(1,2)+.10];
% now you can use data units
a = annotation('arrow');
a.Parent = f.CurrentAxes;  % associate annotation with current axes
a.X = xa;
a.Y = ya;
a = annotation('ellipse');
a.Parent = f.CurrentAxes;  % associate annotation with current axes
a.Position = [elec_pt(1,1)+1.1,elec_pt(1,2)+0.025,0.25,0.25];
a.LineWidth = 2;
a = annotation('textbox','interpreter','latex');
a.FontSize = 18;
a.String = '\emph{I}';
a.LineStyle = 'none';
a.Parent = f.CurrentAxes;  % associate annotation with current axes
a.Position = [elec_pt(1,1)+1.17,elec_pt(1,2)+0.08,0.15,0.15];
%annotation('arrow',xa,ya);
% 
[stim,meas_sel] = mk_stim_patterns(16,1,[0,1],[0,1],{'no_meas_current'}, 1);
fmdl.stimulation = stim;
img=mk_image(fmdl,1);
img.elem_data(fmdl.mat_idx{2})= 0.3; % rlung
img.elem_data(fmdl.mat_idx{3})= 0.3; % llung
img_v = img;
% Stimulate between elecs 16 and 5 to get more interesting pattern
img_v.fwd_model.stimulation(1).stim_pattern = sparse([16;5],1,[1,-1],16,1);
img_v.fwd_solve.get_all_meas = 1;
vh = fwd_solve(img_v);

img_v = rmfield(img, 'elem_data');
img_v.node_data = vh.volt(:,1);
img_v.calc_colours.npoints = 256;
imgs = calc_slices(img_v,PLANE);

pic = shape_library('get','adult_male','pic');

hh=streamline(q.xp,q.yp, q.xc, q.yc,sx,sy); set(hh,'Linewidth',2, 'color',[43,131,186]/256);
hh=streamline(q.xp,q.yp,-q.xc,-q.yc,sx,sy); set(hh,'Linewidth',2, 'color',[43,131,186]/256);

[x y] = meshgrid( linspace(pic.X(1), pic.X(2),size(imgs,1)), ...
                  linspace(pic.Y(2), pic.Y(1),size(imgs,2)));
colormap([215,25,28]/256); set(gca,'YDir','normal');
c = contour(x,y,imgs,31,'LineWidth',2);
hh= findobj('Type','patch'); set(hh,'LineWidth',2)

for i=1:size(fmdl.electrode,2)
	elec_nodes = fmdl.electrode(i).nodes;
	elec_pts = fmdl.nodes(elec_nodes,1:2);
	plot(elec_pts(:,1),elec_pts(:,2),'lineWidth',5,'Color',[26,150,65]/256)
end
axis equal
xlim([-1 1.25])
ylim([-0.7 1])
set(get(gca, 'XLabel'), 'String', '(C)');
ax = gca;
ax.XLabel.Visible = 'on';
set(gca,'FontSize',20);
axis off

set(gcf,'Position',[ 83         695        1839         627])

print('imgs/current_and_equipotential_lines', '-dsvg')
