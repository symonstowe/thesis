% Generate a sample image of EIT on a human thorax image
tiledlayout(1,4, 'Padding', 'none', 'TileSpacing', 'compact'); 
% A) plot the boundary of the lungs and the chest 
	% Fill to make it look a bit like a body
% get contours
thorax = shape_library('get','adult_male','boundary');
rlung  = shape_library('get','adult_male','right_lung');
llung  = shape_library('get','adult_male','left_lung');
thorax(end+1,:) = thorax(1,:);
rlung(end+1,:) = rlung(1,:);
llung(end+1,:) = llung(1,:);
nexttile 
dat = thorax;
fill(dat(:,1),dat(:,2),[252,141,89]/255)
hold on 
dat = rlung;
fill(dat(:,1),dat(:,2),[145,191,219]/255)
dat = llung;
fill(dat(:,1),dat(:,2),[145,191,219]/255)
axis equal 
axis off
hold off
% B) Generate a model 
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

% C) show the current injection lines
% D) Show the equipotential lines 