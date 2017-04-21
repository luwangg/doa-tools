function sp = mvdr_1d(R, n, design, wavelength, grid_size, varargin)
%MVDR_1D 1D MVDR beamforming.
%Syntax:
%   sp = MVDR_1D(R, n, design, wavelength, grid_size, ...);
%   sp = MVDR_1D(R, n, f_steering, [], grid_size, ...);
%Inputs:
%   R - Sample covariance matrix.
%   n - Number of sources.
%   design - Array design. Can also be a function handle that generates
%            a steering matrix. This function must take two arguments,
%            wavelength and the doa vector.
%   wavelength - Wavelength.
%   grid_size - Number of grid points used.
%   ... - Options:
%           'Unit' - Can be 'radian', 'degree', or 'sin'. Default value is
%                   'radian'.
%           'RefineEstimates' - If set to true, will refine the estimated
%                               direction of arrivals around the grid.
%Output:
%   sp - Spectrum.
unit = 'radian';
refine_estimates = false;
for ii = 1:2:nargin-5
    option_name = varargin{ii};
    option_value = varargin{ii+1};
    switch lower(option_name)
        case 'unit'
            unit = option_value;
        case 'refineestimates'
            refine_estimates = true;
        otherwise
            error('Unknown option "%s".', option_name);
    end
end
% discretize and create the corresponding steering matrix
[doa_grid_rad, doa_grid_display, ~] = default_doa_grid(design, grid_size, unit, 1);
% compute spectrum
R_inv = eye(size(R)) / R;
sp_intl = 1./compute_inv_spectrum(R_inv, design, wavelength, doa_grid_rad);
[x_est, x_est_idx, resolved] = find_doa_est_1d(doa_grid_display, sp_intl, n);
% refine
if resolved && refine_estimates
    f_obj = @(x) compute_inv_spectrum(R_inv, design, wavelength, x);
    x_est = refine_grid_estimates(f_obj, doa_grid_rad, x_est_idx);
end
% return
sp = struct();
sp.x = doa_grid_display;
sp.x_est = x_est;
sp.x_unit = unit;
sp.y = sp_intl;
sp.resolved = resolved;
sp.discrete = false;
end

function v = compute_inv_spectrum(R_inv, design, wavelength, theta)
if ishandle(design)
    A = design(wavelength, theta);
else
    A = steering_matrix(design, wavelength, theta);
end
v = real(sum(conj(A) .* (R_inv * A), 1));
end


