%function reconstruct_from_ismrmrd_1(filename)
addpath(genpath("/home/rowleylab1/github/NeuroImagingMatlab"));
addpath(genpath("/home/rowleylab1/github/jemris"));

%% Save current simulation output with custom name (to prevent overwriting)
%source_path = fullfile(pwd, 'signals_ismrmrd.h5')
%folder = uigetdir('', 'Select Folder to Save Simulation Output');
%new_filename = "JEMRIS_MP2RAGE_3D_EmptyR(2D-Sphere).h5"; % Change to desired filename and include .h5
%destination_path = fullfile(folder, new_filename);
%copyfile(source_path, destination_path);

%% Run signals file (select existing .h5 file)
% [filename, filepath] = uigetfile('*.h5', 'Select ISMRMRD signal file');
% filename = strcat(filepath,filename);

filename = 'signals_ismrmrd.h5';

% Initialize 
dset = ismrmrd.Dataset(filename);
nacq = dset.getNumberOfAcquisitions();
nvol = 2;
debugMode = 1;
row=1;

% Single loop to read header info and build them together
for i = 1:nacq
    acq = dset.readAcquisition(i);
    Nx_list(i) = acq.head.number_of_samples;
    phase_steps(i) = acq.head.idx.kspace_encode_step_1;
    slice_steps(i) = acq.head.idx.kspace_encode_step_2;
end

% % Determine matrix sizes
% Nx_list = zeros(nacq, 1);
% phase_steps = zeros(nacq, 1);
% slice_steps = zeros(nacq, 1);
% Nx = mode(Nx_list);
% Ny = max(phase_steps) + 1;
% Nz = max(slice_steps) + 1;
% fprintf('Nx = %d, Ny = %d, Nz = %d\n', Nx, Ny, Nz);

Nx = 32; Ny = 32; Nz = 1;

if debugMode
    % xmdata = zeros(Nx, Ny, Nz, nvol);
    % ymdata = zeros(Nx, Ny, Nz, nvol);
    % zmdata = zeros(Nx, Ny, Nz, nvol);
    debugInd = zeros(Nx*Ny*Nz*nvol,4);
end

kdata = zeros(Nx, Ny, Nz, nvol);
idx = 1;
xshift = Nx/2;
yshift = Ny/2;
zshift = Nz/2;

for i = 1:nacq
    acq = dset.readAcquisition(i);

    if acq.head.number_of_samples > 1
        traj = acq.traj{1};     % [3 x 64]
        data = acq.data{1};     % [64 x 1] complex vector

        for j = 1:acq.head.number_of_samples
            % extract trajectory position for this sample
            kx = traj(1, j);
            ky = traj(2, j);

            if Nz == 1
                z = 1;
            else
                z = traj(3, j);
                z = round(z + zshift + 1);
            end

            % shift to positive matrix indices (centered)
            x = round(kx + xshift);
            y = round(ky + yshift + 1);


            % insert into kdata only if index is in bounds
            k = 1;
            while kdata(x,y,z,k) ~=0
                k = k+1;
                if k>nvol
                  error("failed, k exceed nvol")
                end
            end

             if debugMode
                % xmdata(x, y, z, 1) = x;
                % ymdata(x, y, z, 1) = y;
                % zmdata(x, y, z, 1) = z;
                debugInd(row,:) = [x, y, z, k];
                row =row+1;
            end

            kdata(x,y,z,k) = data(j);

            idx = idx + 1;

        end
    end
end

% Reconstruct complex images for each volume
img_vol1 = fftshift(fftn(fftshift(kdata(:, :, :, 1))));
img_vol2 = fftshift(fftn(fftshift(kdata(:, :, :, 2))));

% Compute magnitude images
img_mag_vol1 = abs(img_vol1);
img_mag_vol2 = abs(img_vol2);

%% For 3D
% figure;
% imshow3Dfull(img_mag_vol1)
% 
% figure;
% imshow3Dfull(img_mag_vol2)

%% For 2D
figure;
subplot(1, 2, 1);
imagesc(flipud(img_mag_vol1'));  % Transpose for correct orientation
axis image off; colormap(gray);
title('Reconstructed Image - TI1');

subplot(1, 2, 2);
imagesc(flipud(img_mag_vol2'));
axis image off; colormap(gray);
title('Reconstructed Image - TI2');

figure;
subplot(1,2,1)
imagesc(log(abs(kdata(:, :, 1, 1)) + 1e-6));  % Safe visualization
axis image off; % colormap(gray);
title('Reconstructed k-space TI1');

subplot(1,2,2);
imagesc(log(abs(kdata(:, :, 1, 2)) + 1e-6));  % Safe visualization
axis image off; % colormap(gray);
title('Reconstructed k-space TI2');

%% Save only the reconstructed image (2D)
fig = figure('Visible', 'off');

% --- Reconstructed magnitude images ---
subplot(2, 2, 1);
imagesc(flipud(img_mag_vol1'));  % Transpose for correct orientation
axis image off; colormap(gray);
title('Reconstructed Image - TI1');

subplot(2, 2, 2);
imagesc(flipud(img_mag_vol2'));
axis image off; colormap(gray);
title('Reconstructed Image - TI2');

% --- Log-scaled k-space ---
subplot(2, 2, 3);
imagesc(log(abs(kdata(:, :, 1, 1)) + 1e-6));
axis image off; colormap(gray); colorbar;
title('K-space (log-magnitude, TI1)');

subplot(2, 2, 4);
imagesc(log(abs(kdata(:, :, 1, 2)) + 1e-6));
axis image off; colormap(gray); colorbar;
title('K-space (log-magnitude, TI2)');

% Save the combined figure
saveas(fig, 'reconstructed_with_kspace.png');
close(fig);

fprintf('✅ Reconstruction complete. Images saved as reconstructed_with_kspace.png\n');
exit;  % Exit for -batch mode


