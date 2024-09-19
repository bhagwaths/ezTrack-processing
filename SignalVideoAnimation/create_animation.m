mouse_name = 'AS-hSyn-1';
input.stage = 'extinction_1';

% file paths: photometry data, ezTrack freezing-moving spreadsheet, and behavioral video
input.blockpaths = {'Z:\Olena Bukalo\behavioral videos\2.AS-hSyn\extinction1_070924\2AS_hSyn_1-240327-085849'};
freezing_data = 'E:\2.AS-hSyn\extinction_1\FreezingOutput_processed\2.AS-hSyn-1_FreezingOutput_processed.csv';
video_filename = 'Z:\Olena Bukalo\behavioral videos\2.AS-hSyn\extinction1_070924\Split Videos\2.AS-hSyn-1.avi';

% conditioning
% input.blockpaths = {'Z:\Olena Bukalo\behavioral videos\AS-cATP\conditioning_041723\AS-cATP-1_2-230417-123617'};
% freezing_data = 'E:\AS-cATP\conditioning\FreezingOutput_processed\AS-cATP-1_FreezingOutput_processed_example.csv';
% video_filename = 'Z:\Olena Bukalo\behavioral videos\AS-cATP\conditioning_041723\split videos\AS-cATP-1.avi';

% adjust parameters
start_time = -5; % in seconds; relative to first CS
end_time = 30; % in seconds; relative to first CS

z_scale = 2.5; % sets z scale bar on y-axis and rescales signal
time_scale = 5; % sets time scale bar on x-axis (in seconds)

input.TTLonOff = 1;
input.streams = 12;
input.streams_12 = {'ax05B', 'ax70B'};

input.N = 100;
input.ARTIFACT = inf;

input.FPS = 30;
input.freeze_threshold = 30;
input.move_threshold = 30; % must be same as freeze_threshold

CS_start_times = 0:90:2160;
% CS_start_times = [0 90 210]; % conditioning
CS_end_times = CS_start_times + 30;

% % only enable for conditioning
% US_start_times = CS_end_times - 2;
% US_end_times = CS_end_times;

% don't change below here
% read freezing and moving times to variable
freezing_table = readtable(freezing_data);
Frames = freezing_table.Frames;
Freezing = freezing_table.Freezing;
[freeze_onset_times, freeze_offset_times, move_onset_times, move_offset_times] = get_freeze_move_eps(Frames,...
    Freezing, input.freeze_threshold, input.move_threshold, input.FPS, start_time-(input.freeze_threshold/input.FPS), end_time+(input.freeze_threshold/input.FPS));

if length(freeze_onset_times) ~= length(freeze_offset_times)
    freeze_offset_times = [freeze_offset_times end_time];
end

if length(move_onset_times) ~= length(move_offset_times)
    move_offset_times = [move_offset_times end_time];
end

fm_times = {freeze_onset_times, freeze_offset_times, move_onset_times, move_offset_times};

% read photometry data to variable
signal = read_photometry_data(input);

% initialize video reader
reader = VideoReader(video_filename);
frame_size = size(read(reader,1));
figure(1); hold on;
curve = animatedline('LineWidth',2,'Color','c'); hold on;
freeze_line = animatedline('LineWidth',4,'Color','r'); hold on;
move_line = animatedline('LineWidth',4,'Color','g'); hold on;
sigtxt = text;
fmtxt = text;
if strcmp(input.stage,"conditioning")
    UStxt = text;
end

% run through video frames in specified range
video_times = Frames / input.FPS;

[~, start_frame] = min(abs(video_times-start_time));
[~, end_frame] = min(abs(video_times-end_time));

[~, signal_idx_start] = min(abs(signal{1}.ts1-video_times(start_frame)));
[~, signal_idx_end] = min(abs(signal{1}.ts1-video_times(end_frame)));

CS_start_frames = [];
CS_times_in_range = CS_start_times(CS_start_times > start_time & CS_start_times <= end_time);
for i=1:numel(CS_times_in_range)
    [~, curr_CS_start_frame] = min(abs(video_times-CS_times_in_range(i)));
    CS_start_frames = [CS_start_frames, curr_CS_start_frame];
end

if strcmp(input.stage,"conditioning")
    US_start_frames = [];
    US_times_in_range = US_start_times(US_start_times > start_time & US_start_times <= end_time);
    for i=1:numel(US_times_in_range)
        [~, curr_US_start_frame] = min(abs(video_times-US_times_in_range(i)));
        US_start_frames = [US_start_frames, curr_US_start_frame];
    end
end

F = [];
time_axis = linspace(0,320,numel(signal_idx_start:signal_idx_end));
freeze_axis = linspace(0,320,numel(start_frame:end_frame));
signal_in_range = signal{1}.zall(signal_idx_start:signal_idx_end);

y_coord = 30; % z scale bar has fixed size of 30
y_factor = y_coord / z_scale; % sig to coord factor

signal_range = range(signal_in_range);
signal_coord = signal_range * y_factor;

signal_rescaled = rescale(signal_in_range,-175,-175+signal_coord,'InputMin',min(signal_in_range),'InputMax',max(signal_in_range));

x_time_range = end_time - start_time;
x_factor = 320 / x_time_range; % sec to coord factor

for i=1:numel(CS_start_frames)
    figure(1);
    curr_CS_pos = freeze_axis(CS_start_frames(i)-start_frame+1);
    line([curr_CS_pos, curr_CS_pos], [-180,-5], 'Color', 'w', 'LineStyle', ':', 'LineWidth', 1);
    text(curr_CS_pos+20, -10, 'CS 🔊', 'Color', 'w', 'VerticalAlignment','top','HorizontalAlignment','center', 'FontSize',10,'FontWeight','bold');
end
if strcmp(input.stage,"conditioning")
    for i=1:numel(US_start_frames)
        figure(1);
        curr_US_pos = freeze_axis(US_start_frames(i)-start_frame+1);
        line([curr_US_pos, curr_US_pos], [-180,-5], 'Color', 'w', 'LineStyle', ':', 'LineWidth', 1);
        text(curr_US_pos+20, -10, 'US ⚡', 'Color', 'w', 'VerticalAlignment','top','HorizontalAlignment','center', 'FontSize',10,'FontWeight','bold');
    end
end

line([0,0], [-80,-80+y_coord], 'Color', 'w', 'LineWidth', 1);
if mod(z_scale,1)==0
    z_scale_pos = -27;
else
    z_scale_pos = -34;
end
text(z_scale_pos, -63, sprintf('z = %s', num2str(z_scale, '%.2g')), 'Color', 'w', 'FontSize',10,'FontWeight','bold');

line([0,time_scale*x_factor], [-210,-210], 'Color', 'w', 'LineWidth', 1.5);
text(((time_scale*x_factor)/2)-(time_scale*x_factor)/10, -220, sprintf('%s s', num2str(time_scale, '%.2g')), 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');

prev_idx = -1;
for i=start_frame:end_frame
    [~, signal_idx] = min(abs(signal{1}.ts1-video_times(i))); % closest dF/F time idx to video_time
    figure(1);
    hold on;
    set(gca,'XLim',[0 frame_size(2)],'YLim',[-240 frame_size(1)],'FontSmoothing', 'off');
    set(gcf,'Position',[680 354 560 624],'color','k');
    frame = read(reader,i);
    j = imtranslate(flipud(frame), [0 0], 'FillValues', 255, 'OutputView', 'full'); 
    delete(sigtxt); delete(fmtxt);
    sigtxt = text(-20,-10,sprintf('%s ∆F/F', num2str(signal{1}.zall(signal_idx), '%.2f')),'color','c','VerticalAlignment','top','HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
    if strcmp(freeze_or_move(video_times(i), fm_times),'Freezing')
        fmtxt = text(160,-200,'Freezing','color','r','VerticalAlignment','top','HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
    elseif strcmp(freeze_or_move(video_times(i), fm_times),'Moving')
        fmtxt = text(160,-200,'Moving','color','g','VerticalAlignment','top','HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
    else
        fmtxt = text(160,-200,'','color','w','VerticalAlignment','top','HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
    end
    image(j);
    axis off;
    if signal_idx ~= prev_idx
        addpoints(curve,time_axis(signal_idx-signal_idx_start+1),signal_rescaled(signal_idx-signal_idx_start+1));
        drawnow;
    end
    if strcmp(freeze_or_move(video_times(i), fm_times),'Freezing')
        addpoints(freeze_line,freeze_axis(i-start_frame+1),-190);
        drawnow;
        addpoints(move_line,NaN,NaN);
        drawnow;
    elseif strcmp(freeze_or_move(video_times(i), fm_times),'Moving')
        addpoints(move_line,freeze_axis(i-start_frame+1),-190);
        drawnow;
        addpoints(freeze_line,NaN,NaN);
        drawnow;
    else
        addpoints(freeze_line,NaN,NaN);
        addpoints(move_line,NaN,NaN);
        drawnow;
    end
    F = [F; getframe(gcf)];
    prev_idx = signal_idx;
end
%%
% write video frames to folder
output_video_name = sprintf('%s_%s_demo.avi', mouse_name, input.stage); % generates video in same folder: "[mouse_name]_demo.avi"
video = VideoWriter(output_video_name,'Motion JPEG AVI');
video.FrameRate = 30;
video.Quality = 100;
open(video);
writeVideo(video,F);
close(video);

function [result] = freeze_or_move(time, fm_times)
    result = '';
    for i=1:numel(fm_times{1})
        if time >= fm_times{1}(i) && time < fm_times{2}(i)
            result = 'Freezing';
        end
    end
    for i=1:numel(fm_times{3})
        if time >= fm_times{3}(i) && time < fm_times{4}(i)
            result = 'Moving';
        end
    end
end