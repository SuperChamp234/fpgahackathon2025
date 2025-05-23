clear
clc

% ========================================================================
% Generate test points
% ========================================================================

% Number of bins
N = 128;
epsilon = 2^(-23); 

% Compute the bin edges (129 points from 0 to 2)
edges = linspace(0, 2, N + 1);

% Uncomment the version you want to generate:
% test_points = edges(1:end-1);                         % start points
test_points = (edges(1:end-1) + edges(2:end)) / 2;    % midpoints
% test_points = edges(2:end) - epsilon;                 % endpoints

% Show first few values
disp('First 5 test point values:');
disp(test_points(1:5));

% ========================================================================
% Write test points to file in u1.23 HEX format
% ========================================================================

filename = 'task10.mem';
fid = fopen(filename, 'w');
fprintf('Writing test points to %s in u1.23 format...\n', filename);

for i = 1:N
    x = test_points(i);
    x_fi = fi(x, 0, 24, 23); % unsigned, 24-bit total, 23 fraction bits
    fprintf(fid, '%s\n', x_fi.hex);
end

fclose(fid);
fprintf('Done! File saved as %s\n', filename);
