%% Save current simulation output with custom name (to prevent overwriting)
source_path = fullfile(pwd, 'signals_ismrmrd.h5')
folder = uigetdir('', 'Select Folder to Save Simulation Output');
new_filename = "JEMRIS_GRE_MP2RAGE.h5"; % Change to desired filename and include .h5
destination_path = fullfile(folder, new_filename);
copyfile(source_path, destination_path);

%% Run signals file (select existing .h5 file)
[filename, filepath] = uigetfile('*.h5', 'Select ISMRMRD signal file');
filename = strcat(filepath,filename);

filename = 'signals_ismrmrd.h5';

%% Image reconstruction using ISMRMRD trajectory data

Nx = 128;  % Known matrix dimensions from .h5 file
Ny = 128;

% Load dataset
dset = ismrmrd.Dataset(filename); 
nacq = dset.getNumberOfAcquisitions();

% Instead build kspace using traj
kdata = zeros(Nx, Ny);  % 2D k-space matrix
kxmdata = zeros(Nx, Ny);  % 2D k-space matrix
kymdata = zeros(Nx, Ny);  % 2D k-space matrix
xmdata = zeros(Nx, Ny);  % 2D k-space matrix
ymdata = zeros(Nx, Ny);  % 2D k-space matrix

idx = 1;
xshift = Nx/2;
yshift = Ny/2;

for i = 1:nacq
    acq = dset.readAcquisition(i);

    if acq.head.number_of_samples > 1
        traj = acq.traj{1};     % [3 x 64]
        data = acq.data{1};     % [64 x 1] complex vector

        for j = 1:acq.head.number_of_samples
            % extract trajectory position for this sample
            kx = traj(1, j);
            ky = traj(2, j);

            % shift to positive matrix indices (centered)
            x = round(kx + xshift + 1);
            y = round(ky + yshift + 1);

            kxmdata(idx) = kx;
            kymdata(idx) = ky;
            xmdata(idx) = x;
            ymdata(idx) = y;
           
            kdata(x, y) = data(j);
            
            idx = idx + 1;

        end
    end
end


% Remove first row from kdata (e.g., if it's zero or dummy data)
kdata = kdata(2:end, :);

% Display k-space dimensions
disp(size(kdata));
disp(numel(kdata));

figure;
imagesc(log(abs(kdata) + 1e-6));  % Safe visualization
axis image off; % colormap(gray);
title('Log Magnitude of Reconstructed k-space');

% Reconstruct image from k-space

img_complex = fftshift(fft2(fftshift(kdata)));
img_mag = abs(img_complex);

figure;
imagesc(flipud(img_mag')); 
axis image off; colormap(gray);
title('Reconstructed Image from ISMRMRD k-space');