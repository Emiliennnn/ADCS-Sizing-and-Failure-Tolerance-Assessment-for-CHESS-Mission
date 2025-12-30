% =========================================== (SATELLITE) SYSTEM & SUBSYSTEMS VARIABLES

% ----------------- SYSTEM
sys.orbit = 500e3; % [m]
sys.J_open = [7.18e-2 0 0; 0 7.17e-2 0; 0 0 4.15e-2]; % Satellite Inertia with Solar Panels deployed
sys.J_closed = [4.84e-2 0 0; 0 4.9e-2 0; 0 0 1e-2];

% ----------------- REACTION WHEELS
sys.phi = deg2rad(26.56); % Tilt Angle [°]
sys.u = cos(sys.phi);
sys.v = sin(sys.phi);
sys.h_sat = 6.995e-4; % [Nms]