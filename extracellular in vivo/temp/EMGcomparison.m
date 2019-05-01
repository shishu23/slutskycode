chans = [1 5 9 12];
emgflp = getEMGfromLFP(double(lfp.data(:, chans)), 'emgFs', 0.2, 'saveVar', true, 'graphics', false);

sfactor = 20; % s

emgdata = movmedian(emg.data(:, 1), sfactor * emg.fs);
emglfpdata = movmedian(emglfp.data(:, 1), sfactor * emglfp.fs);

emgdata = emg.data(:, 1);
emglfpdata = emglfp.data(:, 1);

figure
plot((1 : length(emgdata)) / emg.fs / 60, emgdata);
hold on
plot((1 : length(emglfpdata)) / emglfp.fs / 60, emglfpdata);

axis tight
ylim([0 1])
set(gca, 'TickLength', [0 0])
yticks([0 1])


% TO DO LIST
%   find accuracy measurement (correlation?)
%   charecterize accuracy as a function of EMG Fs
%   charecterize accuracy as a function of LFP channels
%   optimize smoothing of EMG and EMGLFP