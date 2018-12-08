function spkcount = spkCount(spikes, varargin)

% for each unit calculates firing frequency in Hz, defined as spike count
% per binsize divided by binsize {default 1 min}. Also calculates average
% and std of normailzed firing frequency
% 
% INPUT
% required:
%   spikes      struct (see getSpikes)
% optional:
%   graphics    plot figure {1}.
%   win         time window for calculation {[0 Inf]}. specified in seconds.
%   binsize     size in s of bins {60}.
%   saveFig     save figure {1}.
%   basePath    recording session path {pwd}
%
% OUTPUT
% spkcount      struct with fields strd, norm, avg, std, bins, binsize
%
% 24 nov 18 LH

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% arguments and initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validate_win = @(win) assert(isnumeric(win) && length(win) == 2,...
    'time window must be in the format [start end]');

p = inputParser;
addOptional(p, 'binsize', 60, @isscalar);
addOptional(p, 'graphics', 1, @islogical);
addOptional(p, 'win', [0 max(spikes.spindices)], validate_win);
addOptional(p, 'saveFig', 1, @islogical);
addOptional(p, 'basepath', pwd);
addOptional(p, 'saveVar', true, @islogical);

parse(p,varargin{:})
graphics = p.Results.graphics;
spkcount.binsize = p.Results.binsize;
win = p.Results.win;
win = win / 60;
saveFig = p.Results.saveFig;
basepath = p.Results.basepath;
saveVar = p.Results.saveVar;

% nbins = ceil(diff(win) / spkcount.binsize);
nunits = length(spikes.UID);
nmints = ceil(win(2)) - win(1);

spkcount.strd = zeros(nunits, nmints);
spkcount.norm = zeros(nunits, nmints);
spkcount.avg = zeros(1, nmints);
spkcount.std = zeros(1, nmints);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate spike count
for i = 1 : nunits
    binsize = 60;
    for j = 1 : nmints
        % correct for last minute
        if j > win(2)
            binsize = mod(win(2), 60) * 60;
        end
        spkcount.strd(i, j) = sum(ceil(spikes.times{i} / 60) == j) / binsize;
    end
end

% normalize spike count
for i = 1 : nunits
    for j = 1 : nmints
        spkcount.norm(i, j) = spkcount.strd(i, j) / max(spkcount.strd(i, :));
    end
end

% calculate mean and std of norm spike count
for j = 1 : nmints
    spkcount.avg(j) = mean(spkcount.norm(:, j));
    spkcount.std(j) = std(spkcount.norm(:, j));
end
errbounds = [abs(spkcount.avg) + abs(spkcount.std);...
    abs(spkcount.avg) - abs(spkcount.std)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if saveVar
    [~, filename] = fileparts(basepath);
    save([basepath, '\', filename, '.spkcount.mat'], 'spkcount')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if graphics
    
    f = figure;
    x = ([1 : nmints] / 60);
    
    % raster plot of units
    subplot(3, 1, 1)
    hold on
    for i = 1 : nunits
        y = ones(length(spikes.times{i}) ,1) * spikes.UID(i);
        plot(spikes.times{i} / 60 / 60, y, '.k', 'markerSize', 0.1)
    end
    axis tight
    ylabel('Unit #')
    title('Raster Plot')
    
    subplot(3, 1, 2)
    hold on
    for i = 1 : nunits
        plot(x, spkcount.strd(i, :))
    end
    axis tight
    ylabel('Frequency [Hz]')
    title('Spike Count')
    
    subplot(3, 1, 3)
    hold on
    for i = 1 : nunits
        plot(x, spkcount.norm(i, :))
    end
    p = patch([x, x(end : -1 : 1)], [errbounds(1 ,:), errbounds(2, end : -1 : 1)], [.5 .5 .5]);
    p.EdgeColor = 'none';
    plot(x, spkcount.avg, 'lineWidth', 3, 'Color', 'k')
    axis tight
    xlabel('Time [h]')
    ylabel('Norm. Frequency')
    title('Norm. Spike Count')
    
end

if saveFig
    filename = 'spikeCount';
    savePdf(filename, basepath, f)
end

end

% EOF