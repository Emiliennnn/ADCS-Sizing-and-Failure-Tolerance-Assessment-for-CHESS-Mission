output_folder_path = '../../results_pdf/';

% ================= Global Variables
run("../global_variables_load.m")

failed_rw = 4; % Failed Reaction Wheel ID

% ================= Minimization Algo
step = 2000;
start_angle = deg2rad(5);
stop_angle = deg2rad(85);
phi_grid = linspace(start_angle, stop_angle, step);

Htilde_fail = dec2bin(0:7) - '0';
Htilde_fail(Htilde_fail == 0) = -1;
Htilde_fail = sys.h_sat * Htilde_fail';   % 3×8

% 2^4 = 16 combinations
Htilde4 = dec2bin(0:15) - '0';
Htilde4(Htilde4 == 0) = -1;
Htilde4 = sys.h_sat * Htilde4';

Htilde4_fail = zeros(4, size(Htilde_fail,2));
idx = setdiff(1:4, failed_rw);
Htilde4_fail(idx, :) = Htilde_fail;

best_r = -inf;
best_phi = NaN;
best_r_fail = -inf;
best_phi_fail = NaN;

r_array = zeros(1, step);
r_fail_array = zeros(1, step);
i = 0;

for phi = phi_grid
    i = i + 1;

    u = cos(phi);
    v = sin(phi);

    K_DGM = [u  0 -u  0;
             0  u  0 -u;
             v  v  v  v];

    H4_fail = K_DGM * Htilde4_fail;
    H4 = K_DGM * Htilde4;
    Omega_fail = sys.J_open \ H4_fail;
    Omega = sys.J_open \ H4;

    r_fail = inscribed_sphere_radius(Omega_fail);
    r = inscribed_sphere_radius(Omega);

    r_fail_array(i) = r_fail;
    r_array(i) = r;

    if r > best_r
        best_r = r;
        best_r_r_fail = r_fail;
        best_phi = phi;
    end

    if r_fail > best_r_fail
        best_r_fail = r_fail;
        best_r_fail_r = r;
        best_phi_fail = phi;
    end
end

fprintf("============= Nominal ===============\n");
fprintf('Optimal phi = %.4f deg\n', rad2deg(best_phi));
fprintf('Optimal r = %.4f deg\n', rad2deg(best_r));
fprintf('r_fail = %.4f deg\n', rad2deg(best_r_r_fail));
fprintf("============= Failure ===============\n");
fprintf('Optimal phi = %.4f deg\n', rad2deg(best_phi_fail));
fprintf('Optimal r = %.4f deg\n', rad2deg(best_r_fail));
fprintf('r = %.4f deg\n', rad2deg(best_r_fail_r));

fprintf("============= Nominal (Normalized) ===============\n");
J_iso = trace(sys.J_open) / 3;
omega_ref = sys.h_sat / J_iso;
omega_ref_fail = omega_ref;
fprintf('Optimal phi = %.4f deg\n', rad2deg(best_phi));
fprintf('Optimal r = %.4f\n', best_r / omega_ref);
fprintf('r_fail = %.4f\n', best_r_r_fail / omega_ref_fail);
fprintf("============= Failure (Normalized) ===============\n");
fprintf('Optimal phi = %.4f deg\n', rad2deg(best_phi_fail));
fprintf('Optimal r = %.4f\n', best_r_fail / omega_ref_fail);
fprintf('r = %.4f\n', best_r_fail_r / omega_ref);




% ========================= Plotting
alpha = 0.05;   % ±1% band (change freely)
% Nominal
r_norm = r_array / omega_ref;
r_max = max(r_norm);
band_nominal = alpha * r_max;

% Failure
r_fail_norm = r_fail_array / omega_ref_fail;
r_fail_max = max(r_fail_norm);
band_failure = alpha * r_fail_max;

figure('Color','w'); hold on; grid on;

% ===== Filled bands =====
fill([rad2deg(phi_grid), fliplr(rad2deg(phi_grid))], ...
     [(r_max-band_nominal)*ones(size(phi_grid)), ...
      (r_max+band_nominal)*ones(size(phi_grid))], ...
     [0 0.4470 0.7410], ...
     'FaceAlpha', 0.15, 'EdgeColor', 'none');

fill([rad2deg(phi_grid), fliplr(rad2deg(phi_grid))], ...
     [(r_fail_max-band_failure)*ones(size(phi_grid)), ...
      (r_fail_max+band_failure)*ones(size(phi_grid))], ...
     [0.8500 0.3250 0.0980], ...
     'FaceAlpha', 0.15, 'EdgeColor', 'none');

% ===== Curves =====
plot(rad2deg(phi_grid), r_norm, 'LineWidth', 2)
plot(rad2deg(phi_grid), r_fail_norm, 'LineWidth', 2)

% ===== Reference line =====
xline(26.56, '--', '$\phi_{\mathrm{naive}}$', ...
      'Interpreter','latex', ...
      'Color','k', ...
      'LabelVerticalAlignment','bottom');

% ===== Labels =====
xlabel('$\phi$ [deg]', 'Interpreter','latex', 'FontSize',12)
ylabel('$\bar{\omega}_{sr}$ [/]', 'Interpreter','latex', 'FontSize',12)
title('Slew Rate Normalized vs Tilt Angle $\phi$', ...
      'Interpreter','latex', 'FontSize',12)

xlim(rad2deg([start_angle stop_angle]))

% ===== Legend (top-right) =====
legend({ ...
    strcat('$\pm$', string(alpha*100), '\% band (nominal)'), ...
    strcat('$\pm$', string(alpha*100), '\% band (failure)'), ...
    '$\bar{\omega}_{sr}$', ...
    '$\bar{\omega}_{sr,\mathrm{failure}}$'}, ...
    'Interpreter','latex', ...
    'FontSize',12, ...
    'Location','northeast');

exportgraphics(gcf, ...
    fullfile(output_folder_path,'slew_rate_vs_tilt_angle.pdf'), ...
    'ContentType','vector', ...
    'BackgroundColor','white');

