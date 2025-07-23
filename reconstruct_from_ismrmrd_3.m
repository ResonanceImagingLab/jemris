filename = 'signals_ismrmrd.h5';

% Initialize dataset
dset = ismrmrd.Dataset(filename);
nacq = dset.getNumberOfAcquisitions();

% Set matrix size manually if known
Nx = 64; Ny = 64; Nz = 1;
nvol = 2;             % number of volumes (e.g. TI1 and TI2)
debugMode = true;

% Preallocate arrays
kdata = zeros(Nx, Ny, Nz, nvol);
debugInd = zeros(Nx * Ny * Nz * nvol, 4);
row = 1;

xshift = Nx / 2;
yshift = Ny / 2;
zshift = Nz / 2;

% === Main loop to fill kdata ===
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

% === Reconstruction ===
img_mag_vol = zeros(Nx, Ny, Nz, nvol);
for k = 1:nvol
    if Nz == 1
        img = fftshift(fft2(fftshift(kdata(:, :, 1, k))));
        img_mag_vol(:, :, 1, k) = abs(img);
    else
        img = fftshift(fftn(fftshift(kdata(:, :, :, k))));
        img_mag_vol(:, :, :, k) = abs(img);
    end
end

% === Display ===
if Nz == 1
    figure;
    subplot(1, 2, 1);
    imagesc(flipud(img_mag_vol(:, :, 1, 1)')); axis image off; colormap(gray);
    title('Reconstructed Image - TI1');

    subplot(1, 2, 2);
    imagesc(flipud(img_mag_vol(:, :, 1, 2)')); axis image off; colormap(gray);
    title('Reconstructed Image - TI2');
else
    figure; imshow3Dfull(img_mag_vol(:,:,:,1)); title('TI1 - Volume');
    figure; imshow3Dfull(img_mag_vol(:,:,:,2)); title('TI2 - Volume');
end

 title('Reconstructed Image - TI2');
 
   saveas(gcf, 'reconstructed_images.png');
 
    fprintf('✅ Reconstruction complete. Images saved.\n');
      exit;  % required for -batch mode

% Display log-k-space
figure;
subplot(1, 2, 1);
imagesc(log(abs(kdata(:, :, 1, 1)) + 1e-6)); axis image off;
title('Log K-space TI1');

subplot(1, 2, 2);
imagesc(log(abs(kdata(:, :, 1, 2)) + 1e-6)); axis image off;
title('Log K-space TI2');
