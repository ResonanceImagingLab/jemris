%% Save current simulation output with custom name (to prevent overwriting)
source_path = fullfile(pwd, 'signals_ismrmrd.h5')
folder = uigetdir('', 'Select Folder to Save Simulation Output');
new_filename = "MP2RAGE-test-7-hard_1.h5"; % Change to desired filename and include .h5
destination_path = fullfile(folder, new_filename);
copyfile(source_path, destination_path);

%% Run signals file (select existing .h5 file)
[filename, filepath] = uigetfile('*.h5', 'Select ISMRMRD signal file');

filename = 'signals_ismrmrd.h5';

%% Image reconstruction using ISMRMRD trajectory data

Nx = 32;
Ny = 32;

% Load dataset
dset = ismrmrd.Dataset(filename); 
nacq = dset.getNumberOfAcquisitions();

% Initialize k-space and trajectory data arrays
kdata = zeros(Nx, Ny);
kcount = zeros(Nx, Ny);
kxmdata = zeros(Nx * Ny, 1);
kymdata = zeros(Nx * Ny, 1);

idx = 1;
xshift = Nx / 2;
yshift = Ny / 2;

% Loop through acquisitions
for i = 1:nacq
    acq = dset.readAcquisition(i);

    if acq.head.number_of_samples > 1
        traj = acq.traj{1};
        data = acq.data{1};

        for j = 1:acq.head.number_of_samples
            kx = traj(1, j);
            ky = traj(2, j);

            % Convert to matrix indices (1-based, centered)
            x = round(kx + xshift + 1);
            y = round(ky + yshift + 1);

            % Clamp to matrix bounds
            if x >= 1 && x <= Nx && y >= 1 && y <= Ny
                kdata(x, y) = kdata(x, y) + data(j);
                kcount(x, y) = kcount(x, y) + 1;
            end

            kxmdata(idx) = kx;
            kymdata(idx) = ky;
            idx = idx + 1;
        end
    end
end

% Avoid divide-by-zero when averaging
kcount(kcount == 0) = 1;
kdata = kdata ./ kcount;

% Display k-space matrix dimensions
disp(size(kdata));
disp(numel(kdata));

% Visualize log-magnitude k-space
figure;
imagesc(log(abs(kdata) + 1e-6));
axis image off;
title('Log Magnitude of Reconstructed k-space');

% Reconstruct image using FFT
img_complex = fftshift(fft2(fftshift(kdata)));
img_mag = abs(img_complex);

figure;
imagesc(flipud(img_mag'));
axis image off; colormap(gray);
title('Reconstructed Image from ISMRMRD k-space');