    %   load(fullfile(handles.JemrisShare,'MNIbrain.mat'))
    %function reconstruct_from_ismrmrd_1(filename)
    addpath(genpath("/home/rowleylab1/github/NeuroImagingMatlab"));
    addpath(genpath("/home/rowleylab1/github/jemris"));
    
    Nx=size(BRAIN,1); x=([0:Nx-1]-Nx/2+0.5);
    Ny=size(BRAIN,2); y=([0:Ny-1]-Ny/2+0.5);
    Nz=size(BRAIN,3); z=([0:Nz-1]-Nz/2+0.5);
    
    %tissuse parameters
    %        T1  T2 T2*[ms]  M0 CS[rad/sec]      Label
    tissue=[2569 329  158   1.00   0         ;  % 1 = CSF
             833  83   69   0.86   0         ;  % 2 = GM
             500  70   61   0.77   0         ;  % 3 = WM
             350  70   58   1.00 220*2*pi    ;  % 4 = Fat (CS @ 1.5 Tesla)
             900  47   30   1.00   0         ;  % 5 = Muscle / Skin
            2569 329   58   1.00   0         ;  % 6 = Skin
               0   0    0   0.00   0         ;  % 7 = Skull
             833  83   69   0.86   0         ;  % 8 = Glial Matter
             500  70   61   0.77   0         ;];% 9 = Meat
    
    %parameter maps
    PARAMS={'M0','T1','T2','T2S','DB'};
    
    %fact=[handles.sample.M0 handles.sample.T1 handles.sample.T2 handles.sample.T2S handles.sample.CS];
    
    INDEX =[4 1 2 3 5];
    for i=1:9
     for j=1:5
      if i==1
          eval(['BrainSample.',PARAMS{j},'=zeros(size(BRAIN));']);
      end
      I   = find(BRAIN==i);
      ind = INDEX(j);
      eval(['BrainSample.',PARAMS{j},'(I)=tissue(i,ind);']);
     end
    end
    
    figure();
    imshow3Dfull(BrainSample.T1);
    
    temp = BrainSample.T1;
    Dslice= squeeze(temp(110,:,:));
    figure
    imagesc(Dslice); axis image;
    
    for j=1:5
      eval(['temp= BrainSample.',PARAMS{j}, ';']); %extract
      Dslice= squeeze(temp(110,:,:)); %modify extracted
     
      eval(['userSample.',PARAMS{j}, '=Dslice;']); %build output matfile
    
    end
    
    figure
    imagesc(userSample.T1); axis image;
    
    figure
    imagesc(userSample.M0); axis image;
    
    figure
    imagesc(userSample.T2); axis image;
    
    figure
    imagesc(userSample.T2S); axis image;
    
    figure
    imagesc(userSample.DB); axis image;
    
    %userSample.FNAME= %fullpath;
    % now go to writeSample.m to export