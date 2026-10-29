function seed_rng(s)
%SEED_RNG  Reproducible random numbers in MATLAB and Octave.
if exist('OCTAVE_VERSION', 'builtin'), rand('state', s); randn('state', s); else, rng(s, 'twister'); end %#ok<RAND>
end
