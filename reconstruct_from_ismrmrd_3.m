[filename, filepath] = uigetfile('*.h5', 'Select ISMRMRD signal file');
filename = strcat(filepath,filename);

Nx = 128;  % Known matrix dimensions
Ny = 128;
Nz = 1; 
nvol = 2;
debugMode = 1;

% Load dataset
dset = ismrmrd.Dataset(filename); 
nacq = dset.getNumberOfAcquisitions();

% Initialize k-space
kdata = zeros(Nx, Ny, Nz, nvol);

if debugMode
    % Preallocate index tracking arrays
    kxmdata = [];
    kymdata = [];
    kzmdata = [];
    xmdata = [];
    ymdata = [];
    zmdata = [];
end

xshift = Nx/2;
yshift = Ny/2;

for i = 1:nacq
    acq = dset.readAcquisition(i);

    % Determine volume index
    if i <= floor(nacq/2)
        vol_idx = 1;
    else
        vol_idx = 2;
    end

    if acq.head.number_of_samples > 1
        traj = acq.traj{1};
        data = acq.data{1};

        for j = 1:acq.head.number_of_samples
            kx = traj(1, j);
            ky = traj(2, j);

            if Nz == 1
                z = 1;
            else
                z = traj(3, j);
            end

            x = round(kx + xshift + 1);
            y = round(ky + yshift + 1);

            % Bounds check
            if x >= 1 && x <= Nx && y >= 1 && y <= Ny
                kdata(x, y, z, vol_idx) = data(j);

                if debugMode
                    kxmdata(end+1) = kx;
                    kymdata(end+1) = ky;
                    kzmdata(end+1) = z;
                    xmdata(end+1) = x;
                    ymdata(end+1) = y;
                    zmdata(end+1) = z;
                end
            end
        end
    end
end
