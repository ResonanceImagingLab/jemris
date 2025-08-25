%% Image reconstruction

% function reconstruct_from_ismrmrd(filename)
   filename = 'signals_ismrmrd.h5'; % Input desired .h5 file

   Nx = 128;  % Known from signals.h5 (64x64 = 4096 time samples)
   Ny = 128;

   % Load dataset
   dset = ismrmrd.Dataset(filename); % This opens the .h5 ISMRMRD file and loads it into a Dataset object. From this object, can then access all the acquisition data.
   nacq = dset.getNumberOfAcquisitions();


   idx = 1;
   kdata = zeros(Nx, Ny);
   for i = 1:nacq
        acq = dset.readAcquisition(i);
        if acq.head.number_of_samples > 1
            kdata(idx,:) = acq.data{1};
            idx=idx+1;
        end
   end

%% Instead build kspae using traj
   idx = 1;
   kdata = zeros(Nx, Ny);
   yshift = Ny/2;
   xshift = Nx/2;
   for i = 1:nacq
        acq = dset.readAcquisition(i);
        if acq.head.number_of_samples > 1

            % extract trajectory value (3 x nsamples)

            for j  1:acq.head.number_of_samples
                % make sure trajectory is normalized for 1: Ny... (convert
                % trajectory to a matrix index)

                x = 
                y= 
                z = 

                kdata(x, y, z) = acq.data{j};
            end

        end
   end

% Known matrix size

disp(size(kdata));
disp(numel(kdata));

%kdata = kdata(2:end); 

figure;
imagesc(log(abs(kdata) + 1e-6));  % Safe visualization
axis image off; % colormap(gray);
title('Log Magnitude of Reconstructed k-space');

img_complex = fftshift(fft2(fftshift(kspace_grid)));
img_mag = abs(img_complex);

figure;
imagesc(flipud(img_mag')); axis image off;
colormap(gray);
title('Reconstructed Image from ISMRMRD k-space');

