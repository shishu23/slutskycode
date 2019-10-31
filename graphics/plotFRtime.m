function f = plotFRtime(varargin)

% plot firing rate with or without mean +- std of firing rate across time
% and/or raster plot of spikes per unit.
%
% INPUT
%   spktimes    array of cells (units). cells are vectors of spike times.
%               see for example spikes.times (from getSpikes)
%   fr          struct. See FR.m.
%   raster      plot raster {1} or not (0).
%   units       plot FR of each unit {1} or not (0).
%   avg         plot mean +- std {1} or not (0).
%   lns         timestamps [hr] for adding lines to norm graph {[]}.
%   lbs         labels to add near lines.
%               for example, lns can be cumsum(info.blockduration / 60 / 60)
%               and lbs can be info.blocks. see tdt2dat.m.
%   saveFig     save figure {1} or not (0)
%   basepath    recording session path {pwd}
%
% 11 jan 19 LH. Updates:
% 28 oct 19 LH  separated strd and norm. added lines w/ labels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = inputParser;
addOptional(p, 'spktimes', []);
addOptional(p, 'fr', []);
addOptional(p, 'raster', false, @islogical);
addOptional(p, 'units', false, @islogical);
addOptional(p, 'avg', false, @islogical);
addOptional(p, 'lns', [], @isnumeric);
addOptional(p, 'lbs', {}, @iscell);
addOptional(p, 'saveFig', false, @islogical);
addOptional(p, 'basepath', pwd);

parse(p, varargin{:})
spktimes = p.Results.spktimes;
fr = p.Results.fr;
raster = p.Results.raster;
units = p.Results.units;
avg = p.Results.avg;
lns = p.Results.lns;
lbs = p.Results.lbs;
saveFig = p.Results.saveFig;
basepath = p.Results.basepath;

if raster && isempty(spktimes)
    error('spktimes is required for raster plot')
end
if (units || avg) && isempty(fr)
    error('fr is required for plots')
end
if length(lns) ~= length(lbs)
    error('the number of lines and labels does not match')
end

[nunits, nbins] = size(fr.strd);
nplots = sum([raster, units, avg]);

x = ([1 : nbins] / (60 / fr.binsize) / 60);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f = figure;
j = 1;

% raster plot
if raster
    subplot(nplots, 1, j)
    j = j + 1;
    hold on
    for i = 1 : nunits
        y = ones(length(spktimes{i}) ,1) * i;
        plot(spktimes{i} / 60 / 60, y, 'markerSize', 0.1)
    end
    axis tight
    ylabel('Unit #')
    title('Raster Plot')
end

% FR of each unit
if units
    subplot(nplots, 1, j)
    j = j + 1;
    hold on
    for i = 1 : nunits
        plot(x, fr.strd(i, :))
    end
    axis tight
    ylabel('Frequency [Hz]')
    title('Firing Rate')
end

% mean +- std
if avg
    % calculate mean and std of norm spike count
    fravg = mean(fr.norm, 1);
    frstd = std(fr.norm, 0, 1);
    errbounds = [abs(fravg) + abs(frstd);...
        abs(fravg) - abs(frstd)];
    
    subplot(nplots, 1, j)
    hold on
    p = patch([x, x(end : -1 : 1)], [errbounds(1 ,:), errbounds(2, end : -1 : 1)], [.5 .5 .5]);
    p.EdgeColor = 'none';
    plot(x, fravg, 'lineWidth', 3, 'Color', 'k')
    axis tight
    xlabel('Time [h]')
    ylabel('Norm. Frequency')
    title('Mean +- STD')
          
    if ~isempty(lns)
        nlines = length(lns);
        x = repmat(lns, 2, 1);
        y = repmat(ylim, nlines, 1);
        plot(x, y' ,'--k')
        if ~isempty(lbs)
            text(x(1, :), y(1, 2)*ones(nlines, 1), lbs)
        end
    end
    
end

if saveFig
    filename = 'firingRate';
    savePdf(filename, basepath, f)
end

end

% EOF