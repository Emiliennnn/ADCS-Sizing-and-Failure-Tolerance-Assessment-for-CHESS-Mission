output_folder_path = '../../results_pdf/';

% ================= Global Variables
run("../global_variables_load.m")

failed_rw = 4; % Failed Reaction Wheel ID
K_DGM_pyramidal = [sys.u  0 -sys.u  0; 0  sys.u  0 -sys.u; sys.v  sys.v  sys.v  sys.v ]; % 
K_DGM_orthogonal = eye(3);

% ================= Pre-computations
% Generate all combinations for remaining 3 wheels
Htilde_fail = dec2bin(0:7) - '0';
Htilde_fail(Htilde_fail == 0) = -1;
Htilde_fail = sys.h_sat * Htilde_fail';   % 3×8

% 2^4 = 16 combinations
Htilde4 = dec2bin(0:15) - '0';
Htilde4(Htilde4 == 0) = -1;
Htilde4 = sys.h_sat * Htilde4';

% 2^3 = 8 combinations
Htilde3 = dec2bin(0:7) - '0';
Htilde3(Htilde3 == 0) = -1;
Htilde3 = sys.h_sat * Htilde3';

H4 = K_DGM_pyramidal * Htilde4;
H3 = K_DGM_orthogonal * Htilde3;
Omega4_open = sys.J_open \ H4;

Htilde4_fail = zeros(4, size(Htilde_fail,2));
idx = setdiff(1:4, failed_rw);
Htilde4_fail(idx, :) = Htilde_fail;
H4_fail = K_DGM_pyramidal * Htilde4_fail;
Omega4_failure_open = sys.J_open \ H4_fail;

% ============================= Plotting
function plotCleanPolytope(data, titleStr, hmax, plot_sphere, export_file_name)
    % Create figure with defined size in pixels
    fig = figure('Color', 'w', 'Units', 'pixels', 'Position', 3/4 * [100 100 600 600]);
    hold on;
    
    if plot_sphere
        % Calculate inscribed sphere radius
        r = inscribed_sphere_radius(data);
        
        % Find center of the polytope (centroid)
        center = mean(data, 2);
        
        % Generate sphere coordinates
        [xs, ys, zs] = sphere(50);  % 50x50 sphere for smooth appearance
        
        % Scale and translate sphere
        xs = r * xs + center(1);
        ys = r * ys + center(2);
        zs = r * zs + center(3);
        
        % Plot the inscribed sphere in red
        surf(xs, ys, zs, ...
            'FaceColor', [1 0.2 0.2], ...  % Red color
            'EdgeColor', 'none', ...
            'FaceAlpha', 1, ...  % Semi-transparent
            'FaceLighting', 'gouraud', ...
            'AmbientStrength', 0.4, ...
            'DiffuseStrength', 0.7, ...
            'SpecularStrength', 0.4, ...
            'SpecularExponent', 10);
    end
    
    % Check if data forms a cube (8 vertices)
    if size(data, 2) == 8
        % Check if it's approximately a cube/box
        ranges = max(data, [], 2) - min(data, [], 2);
        if all(ranges > 0)  % It's a box-like shape
            % Use custom cube/box plotting with quadrilateral faces
            plotBox(data);
        else
            % Standard convhull approach
            K = convhull(data(1,:), data(2,:), data(3,:));
            patch('Faces', K, 'Vertices', data', ...
                'FaceColor', [0.7 0.8 0.95], ...
                'EdgeColor', 'none', ...
                'FaceAlpha', 0.7, ...
                'FaceLighting', 'gouraud', ...
                'AmbientStrength', 0.3, ...
                'DiffuseStrength', 0.8, ...
                'SpecularStrength', 0.5, ...
                'SpecularExponent', 10);
        end
    else
        % Standard convhull approach for non-cube polytopes
        K = convhull(data(1,:), data(2,:), data(3,:));
        patch('Faces', K, 'Vertices', data', ...
            'FaceColor', [0.7 0.8 0.95], ...
            'EdgeColor', 'none', ...
            'FaceAlpha', 0.7, ...
            'FaceLighting', 'gouraud', ...
            'AmbientStrength', 0.3, ...
            'DiffuseStrength', 0.8, ...
            'SpecularStrength', 0.5, ...
            'SpecularExponent', 10);
    end
    
    axis equal; grid on;
    xlabel('$h_x$', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('$h_y$', 'Interpreter', 'latex', 'FontSize', 12);
    zlabel('$h_z$', 'Interpreter', 'latex', 'FontSize', 12);
    title(titleStr, 'Interpreter', 'latex', 'FontSize', 14);
    view([1 1 1]);
    
    lighting gouraud;
    camlight('headlight');
    camlight('right');
    light('Position', [-1 -1 -1], 'Style', 'infinite');
    
    xlim([-hmax(1), hmax(1)])
    ylim([-hmax(2), hmax(2)])
    zlim([-hmax(3), hmax(3)])
    
    set(gca, 'FontSize', 10, 'LineWidth', 1);
    
    if nargin == 5
        % Minimal margins
        ax = gca;
        ax.Units = 'normalized';
        ti = ax.TightInset;
        ax.Position = [ti(1), ti(2), 1-ti(1)-ti(3), 1-ti(2)-ti(4)];
        
        % Force rendering
        drawnow;
        
        % Export settings
        set(fig, 'Renderer', 'opengl');
        set(fig, 'InvertHardcopy', 'off');
        
        exportgraphics(fig, export_file_name, ...
            'ContentType', 'image', ...
            'Resolution', 600, ...
            'BackgroundColor', 'white');
        
        fprintf('Exported to: %s\n', export_file_name);
    end
end

function plotBox(data)
    % Custom function to plot a box with proper quadrilateral faces
    xmin = min(data(1,:)); xmax = max(data(1,:));
    ymin = min(data(2,:)); ymax = max(data(2,:));
    zmin = min(data(3,:)); zmax = max(data(3,:));
    
    vertices = [
        xmin ymin zmin;  % 1
        xmax ymin zmin;  % 2
        xmin ymax zmin;  % 3
        xmax ymax zmin;  % 4
        xmin ymin zmax;  % 5
        xmax ymin zmax;  % 6
        xmin ymax zmax;  % 7
        xmax ymax zmax   % 8
    ];
    
    % Face definitions with correct counter-clockwise ordering (viewed from outside)
    faces = [
        1 2 4 3;  % bottom (z=zmin, normal=-z): viewed from below
        1 5 6 2;  % front (y=ymin, normal=-y): viewed from front
        1 3 7 5;  % left (x=xmin, normal=-x): viewed from left
        5 7 8 6;  % top (z=zmax, normal=+z): viewed from above
        2 6 8 4   % right (x=xmax, normal=+x): viewed from right
        3 4 8 7;  % back (y=ymax, normal=+y): viewed from back
    ];
    
    patch('Faces', faces, 'Vertices', vertices, ...
        'FaceColor', [0.7 0.8 0.95], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.7, ...
        'FaceLighting', 'gouraud', ...
        'AmbientStrength', 0.3, ...
        'DiffuseStrength', 0.8, ...
        'SpecularStrength', 0.5, ...
        'SpecularExponent', 10);
end

% Generate all plots
plotCleanPolytope(H4, 'Angular Momentum Envelope -- 4 RWs Pyramid', 2*[sys.h_sat, sys.h_sat, sys.h_sat]', 0, strcat(output_folder_path, 'ang_momentum_env_4RW.pdf'));
plotCleanPolytope(H3, 'Angular Momentum Envelope -- 3 Orthogonal RWs', 2*[sys.h_sat, sys.h_sat, sys.h_sat]', 0, strcat(output_folder_path, 'ang_momentum_env_3RW.pdf'));
plotCleanPolytope(Omega4_open, 'Angular Speed Envelope -- 4 RWs Pyramid (open)', 2 * (sys.J_open \ [sys.h_sat, sys.h_sat, sys.h_sat]'), 1, strcat(output_folder_path, 'ang_speed_env_4RW.pdf'));
plotCleanPolytope(Omega4_failure_open, 'Angular Speed Envelope -- 4 RWs Pyramid with 1 RW failure', 2 * (sys.J_open \ [sys.h_sat, sys.h_sat, sys.h_sat]'), 1, strcat(output_folder_path, 'ang_speed_env_4RW_failure.pdf'));

% ========================================================= Slew rate
r_Omega_open = rad2deg(inscribed_sphere_radius(Omega4_open))
r_Omega_open_failure = rad2deg(inscribed_sphere_radius(Omega4_failure_open))
