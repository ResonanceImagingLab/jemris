%function reconstruct_from_ismrmrd_1(filename)
addpath(genpath("/home/rowleylab1/github/NeuroImagingMatlab"));
addpath(genpath("/home/rowleylab1/github/jemris"));

filename = 'result_flip30.h5';

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

Nx = 32; Ny = 32; Nz = 1;

kdata = zeros(Nx, Ny, Nz, nvol);
idx = 1;
xshift = Nx/2;
yshift = Ny/2;
zshift = Nz/2;

for i = 1:nacq
    acq = dset.readAcquisition(i);

    if acq.head.number_of_samples > 1
        traj = acq.traj{1};    % [3 x N]
        data = acq.data{1};    % [N x 1]

        for j = 1:acq.head.number_of_samples
            kx = traj(1, j);
            ky = traj(2, j);
            x = round(kx + xshift);
            y = round(ky + yshift + 1);

            if Nz == 1
                z = 1;
            else
                kz = traj(3, j);
                z = round(kz + zshift + 1);
            end

            % Bounds check
            if x < 1 || x > Nx || y < 1 || y > Ny || z < 1 || z > Nz
                continue;
            end

            % Insert into first available volume slot
            k = 1;
            while k <= nvol && kdata(x, y, z, k) ~= 0
                k = k + 1;
            end

            if k > nvol
                warning('All volumes filled at (%d, %d, %d). Skipping.', x, y, z);
                continue;
            end

            kdata(x, y, z, k) = data(j);

            if debugMode
                debugInd(row, :) = [x, y, z, k];
                row = row + 1;
            end
        end
    end
end

% Reconstruct complex images for each volume
img_vol1 = fftshift(fftn(fftshift(kdata(:, :, :, 1))));
img_vol2 = fftshift(fftn(fftshift(kdata(:, :, :, 2))));

% Compute magnitude images
img_mag_vol1 = abs(img_vol1);
img_mag_vol2 = abs(img_vol2);

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


