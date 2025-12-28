% Global Variables and Parameters
PLOTTING_BOOL = 1;
phi = deg2rad(26.56); % Tilt Angle
u = cos(phi);
v = sin(phi);
failed_rw = 4; % Failed Reaction Wheel ID
hmax = 6.995e-4; % Slew-rate boundary w/o failure = 3.5025e-4

J_open = [7.18e-2 0 0; 0 7.17e-2 0; 0 0 4.15e-2]; % Satellite Inertia with Solar Panels deployed

K_DGM_pyramidal = [u  0 -u  0; 0  u  0 -u; v  v  v  v ]; % 
K_DGM_orthogonal = eye(3);

% Generate all combinations for remaining 3 wheels
Htilde_fail = dec2bin(0:7) - '0';
Htilde_fail(Htilde_fail == 0) = -1;
Htilde_fail = hmax * Htilde_fail';   % 3×8

% 2^4 = 16 combinations
Htilde4 = dec2bin(0:15) - '0';
Htilde4(Htilde4 == 0) = -1;
Htilde4 = hmax * Htilde4';

% 2^3 = 8 combinations
Htilde3 = dec2bin(0:7) - '0';
Htilde3(Htilde3 == 0) = -1;
Htilde3 = hmax * Htilde3';

H4 = K_DGM_pyramidal * Htilde4;
H3 = K_DGM_orthogonal * Htilde3;
Omega4_open = J_open \ H4;

Htilde4_fail = zeros(4, size(Htilde_fail,2));
idx = setdiff(1:4, failed_rw);
Htilde4_fail(idx, :) = Htilde_fail;
H4_fail = K_DGM_pyramidal * Htilde4_fail;
Omega4_failure_open = J_open \ H4_fail;

% ============================= Plotting
function plotCleanPolytope(data, titleStr, hmax, export_file_name)
    % Create figure with defined size
    fig = figure('Color', 'w', 'Units', 'inches', 'Position', [1 1 7 6]);
    
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
                'FaceAlpha', 0.85, ...
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
            'FaceAlpha', 0.85, ...
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
    view([1.5 0.75 1]);
    
    lighting gouraud;
    camlight('headlight');
    camlight('right');
    light('Position', [-1 -1 -1], 'Style', 'infinite');

    xlim([-hmax(1), hmax(1)])
    ylim([-hmax(2), hmax(2)])
    zlim([-hmax(3), hmax(3)])
    
    set(gca, 'FontSize', 10, 'LineWidth', 1);
    
    if nargin == 4
        % Paper setup for margins
        set(fig, 'PaperUnits', 'inches');
        set(fig, 'PaperSize', [7 6]);
        set(fig, 'PaperPosition', [0 0 7 6]);
        
        % Axes margins
        ax = gca;
        ax.Position = [0.18 0.15 0.72 0.75];
        
        % Use OpenGL renderer and high-res print for lighting preservation
        set(fig, 'Renderer', 'opengl');
        print(fig, export_file_name, '-dpdf', '-r600', '-opengl');
        
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
    
    % Corrected face definitions with outward-pointing normals
    faces = [
        1 3 4 2;  % bottom
        5 6 8 7;  % top
        1 2 6 5;  % front
        4 3 7 8;  % back
        1 5 7 3;  % left
        2 4 8 6   % right
    ];
    
    patch('Faces', faces, 'Vertices', vertices, ...
        'FaceColor', [0.7 0.8 0.95], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.85, ...
        'FaceLighting', 'gouraud', ...
        'AmbientStrength', 0.3, ...
        'DiffuseStrength', 0.8, ...
        'SpecularStrength', 0.5, ...
        'SpecularExponent', 10);
end

if PLOTTING_BOOL
    % Generate all plots
    plotCleanPolytope(H4, 'Angular Momentum Envelope -- 4 RWs Pyramid', 2*[hmax, hmax, hmax]', 'ang_momentum_env_4RW.pdf');
    plotCleanPolytope(H3, 'Angular Momentum Envelope -- 3 Orthogonal RWs', 2*[hmax, hmax, hmax]', 'ang_momentum_env_3RW.pdf');
    plotCleanPolytope(Omega4_open, 'Angular Speed Envelope -- 4 RWs Pyramid (open)', 2 * (J_open \ [hmax, hmax, hmax]'), 'ang_speed_env_4RW.pdf');
    plotCleanPolytope(Omega4_failure_open, 'Angular Momentum Envelope -- 4 RWs Pyramid with 1 RW failure', 2 * (J_open \ [hmax, hmax, hmax]'), 'ang_momentum_env_4RW_failure.pdf');
end

% ========================================================= Slew rate
r_Omega_open = rad2deg(inscribed_sphere_radius(Omega4_open))
r_Omega_closed = rad2deg(inscribed_sphere_radius(Omega4_closed))
r_Omega_open_failure = rad2deg(inscribed_sphere_radius(Omega4_failure_open))
r_Omega_closed_failure = rad2deg(inscribed_sphere_radius(Omega4_failure_closed))
