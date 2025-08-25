%% Select xml
[xmlfile, filepath] = uigetfile('*.xml', 'Select xml signal file');
xmlfile = strcat(filepath,xmlfile);

doc = xmlread(xmlfile);
params = doc.getElementsByTagName('Parameters').item(0);

Nx = str2double(char(params.getAttribute('Nx')));
Ny = str2double(char(params.getAttribute('Ny')));
Nz = str2double(char(params.getAttribute('Nz')));
TR = str2double(char(params.getAttribute('TR')));  % in ms

%% --- Compute durations ---
% Find P7 Duration (inversion pulse)
rfpulses = doc.getElementsByTagName('HARDRFPULSE');
P7_duration = NaN;
for i = 0:rfpulses.getLength-1
    node = rfpulses.item(i);
    if strcmp(char(node.getAttribute('Name')), 'P7')
        P7_duration = str2double(char(node.getAttribute('Duration')));
    end
end

% Display
fprintf('P7 Duration: %.1f ms\n', P7_duration);

%% Recon

filename = 'signals_ismrmrd.h5';

dset = ismrmrd.Dataset('signals_ismrmrd.h5');
nacq = dset.getNumberOfAcquisitions();
nvol = 2;
debugMode = 1;

kdata = zeros(Nx, Ny, Nz, nvol);
if debugMode
    xmdata = zeros(Nx, Ny, Nz, nvol);
    ymdata = zeros(Nx, Ny, Nz, nvol);
    zmdata = zeros(Nx, Ny, Nz, nvol);
end

% Loop over acquisitions
for i = 1:nacq
    acq = dset.readAcquisition(i);

    if acq.head.number_of_samples > 1
        traj = acq.traj{1};    % [3 x N]
        data = acq.data{1};    % [N x 1]

        for j = 1:acq.head.number_of_samples
            kx = traj(1, j);
            ky = traj(2, j);
            x = round(kx + Nx/2);
            y = round(ky + Ny/2 + 1);

            if Nz == 1
                z = 1;
            else
                kz = traj(3, j);
                z = round(kz + Nz/2 + 1);
            end

            if debugMode
                xmdata(x, y, z, 1) = x;
                ymdata(x, y, z, 1) = y;
                zmdata(x, y, z, 1) = z;
            end

            % Place data in next available volume slot
            k = 1;
            while kdata(x, y, z, k) ~= 0
                k = k + 1;
                % if k > nvol
                %     error("failed, k exceed nvol");
                % end
            end

            kdata(x, y, z, k) = data(j);
        end
    end
end

% Reconstruct complex images for each volume
img_vol1 = fftshift(fft2(fftshift(kdata(:, :, 1, 1))));
img_vol2 = fftshift(fft2(fftshift(kdata(:, :, 1, 2))));

% Compute magnitude images
img_mag_vol1 = abs(img_vol1);
img_mag_vol2 = abs(img_vol2);

% Display them side by side
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
