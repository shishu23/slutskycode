function [chunks] = n2chunks(varargin)

% gets a number of elements and divides it to chunks of chunksize. handles
% start/end points and allows clipping of certain elements 
%
% INPUT:
%   n           numeric. number of elements to split
%   chunksize   numeric. number of elements in a chunk {1e6}. 
%   clip        mat n x 2 indicating samples to diregard from chunks.
%               for example: clip = [0 50; 700 Inf] will remove the first
%               50 samples and all samples between 700 and n
%
% OUTPUT
%   chunks      mat n x 2 
%
% CALLS:
%
% TO DO LIST:
%   # add an option to restrict minimum chunk size
%
% 22 apr 20 LH      


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
addOptional(p, 'n', [], @isnumeric);
addOptional(p, 'chunksize', [], @isnumeric);
addOptional(p, 'clip', [], @isnumeric);

parse(p, varargin{:})
n = p.Results.n;
chunksize = p.Results.chunksize;
clip = p.Results.clip;

% validate
% if max(clip(:)) > n
%     error('')
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% partition into chunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% partition into chunks
if isempty(chunksize)       % load entire file
    chunks = [1 n];
else                        % load file in chunks
    nchunks = ceil(n / chunksize);
    chunks = [1 : chunksize : chunksize * nchunks;...
        chunksize : chunksize : chunksize * nchunks]';
    chunks(nchunks, 2) = n;
end

% assimilate clip into chunks
if ~isempty(clip)
    if isempty(chunksize)
        if size(clip, 1) == 1 && clip(1) == 0
            chunks(1, 1) = clip(1, 2);
        elseif size(clip, 1) == 1 && clip(2) == Inf
            chunks(1, 2) = clip(1, 1);
        else
            for j = 1 : size(clip, 1) - 1
                chunks = [chunks; clip(j, 2) clip(j + 1, 1)];
            end
        end
        if clip(1, 1) > 0
            chunks = [0 clip(1, 1); chunks];
        end
    else
        idx = zeros(1, 2);
        for j = 1 : size(clip, 1)
            idx(1) = find(chunks(:, 2) > clip(j, 1), 1, 'first');
            chunks(idx(1), 2) = clip(j, 1);
            if clip(j, 2) ~= Inf
                idx(2) = find(chunks(:, 1) > clip(j, 2), 1, 'first');
                chunks(idx(2), 1) = clip(j, 2);
                rmblk = idx(1) + 1 : idx(2) - 1;
            else
                rmblk = idx(1) + 1 : size(chunks, 1);
            end
            if ~isempty(rmblk)
                chunks(rmblk, :) = [];
            end
        end
    end
    chunks = chunks(any(chunks, 2), :);
end