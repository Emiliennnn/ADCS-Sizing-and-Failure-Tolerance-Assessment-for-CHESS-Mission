output_folder_path = '../../results_pdf/';

% ================= Global Variables
run("../global_variables_load.m")

failed_rw = 4; % Failed Reaction Wheel ID

% ================= Minimization Algo
phi_opt = sdpvar(1, 1, 'full');

u_opt = cos(phi_opt);
v_opt = sin(phi_opt);
K_DGM_pyramidal = [u_opt  0 -u_opt  0; 0  u_opt  0 -u_opt; v_opt  v_opt v_opt v_opt]; %

Htilde_fail = dec2bin(0:7) - '0';
Htilde_fail(Htilde_fail == 0) = -1;
Htilde_fail = sys.h_sat * Htilde_fail';   % 3×8

Htilde4_fail = zeros(4, size(Htilde_fail,2));
idx = setdiff(1:4, failed_rw);
Htilde4_fail(idx, :) = Htilde_fail;
H4_fail = K_DGM_pyramidal * Htilde4_fail;
Omega4_failure_open = sys.J_open \ H4_fail;

obj = inscribed_sphere_radius(Omega4_failure_open);
con = [phi_opt >= 0, phi_opt <= pi/2];

options = sdpsettings('verbose', 0);
diagnostics = optimize(con, obj, options);
if diagnostics.problem == 0
    phi_opt = rad2deg(value(phi_opt));
    disp(phi_opt);
else
    disp('Solver failed.');
end