function [hfig,hdB,hph] = bode_compare(f, varargin)
% BODE_COMPARE(f, H1, H2, ...)
%
% Description:
%   Plot multiple responses on a single Bode diagram (magnitude and phase)
%
% Inputs:
%   f    = frequency vector (common for all passed H vectors)
%   H1   = complex frequency response #1
%   H2   = complex frequency response #2
%   H... = additional complex frequency response vectors
%
% Outputs:
%   hfig = the handle to the Bode diagram figure window {optional}
%   hdB  = the handle to the dB axis
%   hph  = the handle to the phase axis

narginchk(2,inf)

n = length(varargin);  % number of responses
H = cell(n, 1);
for i=1:n
    H{i} = squeeze(varargin{i});
end

hfig = tiledlayout(2, 1, "TileSpacing","tight", "Padding", "loose");
hdB = nexttile;
semilogx(f, 20*log10(abs(H{1})))
hold on
for i=2:n
    semilogx(f, 20*log10(abs(H{i})))
end
xticklabels(hdB, {})

hph = nexttile;
semilogx(f, unwrap(angle(H{1})))
hold on
for i=2:n
    semilogx(f, unwrap(angle(H{i})))
end

xlabel(hph, "Frequency (Hz)")
ylabel(hph, "Phase (deg)")
ylabel(hdB, "Magnitude (dB)")
title(hfig, "Bode Diagram")

if nargout<1
    clear hfig hdB hph
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net