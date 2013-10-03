% Initialize Matlab environment. 
function startup 
   % initialize matlab paths
   wd = cd;            % working directory
   addpath(wd);
   % mpi functions and toolbox
   addpath(fullfile(wd,'mpi','matlab_mpi','src'));
   addpath(fullfile(wd,'mpi','matlab_mpi','queue'));
   addpath(genpath(fullfile(wd,'mpi','toolbox')));
   % benchmarking
   addpath(fullfile(wd,'bench'));
   % boundary correspondence
   addpath(fullfile(wd,'correspond'));
   % rendering (annotation boundary map generation)
   addpath(fullfile(wd,'render'));
   % utilities
   addpath(fullfile(wd,'util'));
   % visualization
   addpath(fullfile(wd,'vis'));
end
