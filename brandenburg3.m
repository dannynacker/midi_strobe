%% This script selects pitch, time and velocity data from a MIDI file and
% converts it into a bitmap to be read by the SCCS research strobe. 
% It requires the Audio Toolbox and Signal Processing Toolbox. 
% Strobe frequencies are transposed to one major third + octaves below the
% auditory frequencies to increase the likelihood of more significant IMD
% component generation. 

addpath("C:\Users\David\Desktop\danny\miditoolbox")
midiFile = readmidi("C:\Users\David\Desktop\danny\spotifyAPI\MIDI\bach_brandenburg3.mid");
durationSeconds = 60*10.16; %length of song
durationMinutes = 10.16;

audioFilePath = "C:\Users\David\Desktop\danny\spotifyAPI\MIDI\brandenburg3.mp3";
[y, Fs] = audioread(audioFilePath);

% Assuming midiFile is a table or array with 7 columns

% Extract columns 1, 2, 3, and 4
data = midiFile(:, [1, 2, 3, 4]);

% Initialize arrays to store the result
arrangement = unique(data(:, 1));
timeValues = [];
velocityValues = [];
noteValues = [];

% Loop over each unique value in column 1
for i = 1:length(arrangement)
    % Get the subset of rows with the current unique value in column 1
    subset = data(data(:, 1) == arrangement(i), :);
    
    % Find the row with the highest value in column 2
    [~, maxIndex] = max(subset(:, 2));
    
    % Extract the corresponding values
    timeValues = [timeValues; subset(maxIndex, 1)];
    velocityValues = [velocityValues; subset(maxIndex, 2)];
    noteValues = [noteValues; subset(maxIndex, 4)];
end

% Define the Hz values for each note from C to B minus a major third
respHzValues = [6.54, 6.93, 7.34, 7.78, 8.18, 8.66, 9.18, 9.72, 10.3, 10.91, 11.56, 12.25];

% Define the Hz values for each note from C to B without transposition
% (reference)
correspondingFreqArray = [8.18, 8.66, 9.18, 9.72, 10.3, 10.91, 11.56, 12.25, 12.98, 13.75, 14.57, 15.43];

% Initialize an array to store the custom values
corrFreqValues = zeros(1, length(noteValues));

% Loop through the noteValues array and assign custom values
for i = 1:length(noteValues)
    % Calculate the note index
    noteIndex = mod(noteValues(i), 12) + 1;
    
    % Get the custom value for the note
    corrFreqValues(i) = [correspondingFreqArray(noteIndex)];
end

% Initialize an array to store the custom values
respectiveFreqValues = zeros(1, length(noteValues));

% Loop through the noteValues array and assign custom values
for i = 1:length(noteValues)
    % Calculate the note index
    noteIndex = mod(noteValues(i), 12) + 1;
    
    % Get the custom value for the note
    respectiveFreqValues(i) = [respHzValues(noteIndex)];
end

% Find the minimum and maximum values in velocityValues
minVelocity = min(velocityValues);
maxVelocity = max(velocityValues);

% Define the desired range
minDesired = 1; %%Maybe half of the light intensity can serve as a good minimum)
maxDesired = 255;

% Scale the values so that the minimum value becomes 1 and the maximum value becomes 255
amplitude = ((velocityValues - minVelocity) / (maxVelocity - minVelocity)) * (maxDesired - minDesired) + minDesired;

% Round the scaled values to the nearest integer
amplitude = round(amplitude);

%% Set it up

timeValues_mins = timeValues / 60;

% Determine the length of start_values
n = length(timeValues);

% Perform the concatenation
relativeAtTimes = [timeValues, respectiveFreqValues'];
frequencyAtTimes = [timeValues, corrFreqValues'];

frequencyInterpMethod = 'nearest'; % nearest makes it square

ringBrightness = 255; % max brightness

centralBrightnessAtTimes = [timeValues_mins,amplitude];

brightnessInterpMethod = 'linear'; 

frameDurationS = (1/2000); % Time duration of each frame
sampleTimes = (0:frameDurationS:durationSeconds- frameDurationS)'; % Generate a list sample timestamps

frequencyValues = interp1(frequencyAtTimes(:,1), frequencyAtTimes(:,2), sampleTimes, frequencyInterpMethod); % Interpolate the current frequency for each of the sample times
relativeFrequencyValues = interp1(relativeAtTimes(:,1), relativeAtTimes(:,2), sampleTimes, frequencyInterpMethod); % Interpolate the current RELATIVE frequency for each of the sample times

frequencyValues = frequencyValues(~isnan(frequencyValues) & ~isinf(frequencyValues));
relativeFrequencyValues = relativeFrequencyValues(~isnan(relativeFrequencyValues) & ~isinf(relativeFrequencyValues));

avgFreqSinceStart = cumsum(relativeFrequencyValues) ./ (1:length(relativeFrequencyValues))'; % Calculate the average frequency since the start for each sample time

strobeDutyCycle = 50;

% Determine the length of start_values
fix = length(avgFreqSinceStart);

% Truncate all_corresponding_Freqs to the same length as start_values
sampleTimes = sampleTimes(1:fix);

strobe = (1 + square(sampleTimes * 2 * pi .* avgFreqSinceStart, strobeDutyCycle)) ./ 2; % Generate strobe waveform for each of the sample times (and shift to be 0-1-0-1)

ledONBitmap = binary8ToUint8(repmat(strobe, 1, 8)); % Use the strobe signal to turn on and off the ring LED states

centralBrightness = round(interp1(centralBrightnessAtTimes(:,1), centralBrightnessAtTimes(:,2), sampleTimes / 60, brightnessInterpMethod)); % Interpolate brightness for the central LED

dacChannelValuesPerSample = [centralBrightness, repmat([ringBrightness, ringBrightness, ringBrightness, ringBrightness], [length(sampleTimes), 1])]; % Varying central brightness, constant ring brightness, repeat ring values for every generated sample

preparedStrobeData2D = [ledONBitmap, dacChannelValuesPerSample]; % Join bitmap with dac channels
preparedStrobeData1D = reshape(preparedStrobeData2D', [size(preparedStrobeData2D, 1) * size(preparedStrobeData2D, 2), 1])'; % convert to 1D array

figure;
tiledlayout(2,1)
nexttile
title('Frequency and Central Brightness')
yyaxis left
plot(sampleTimes, frequencyValues)
ylabel("Strobe Frequency (Hz)")
xlabel("Time (seconds)")
xlim([0, 610])
hold on
plot(sampleTimes, relativeFrequencyValues, 'r')
hold on
yyaxis right
plot(sampleTimes, centralBrightness)
ylabel("Strobe Light Intensity")
ylim([0,255])
nexttile
title('Strobe Output')
hold on
plot(sampleTimes, strobe)
ylim([-0.5,1.5])
yticks([0,1]);
yticklabels(["Off", "On"])
xlabel("Time (seconds)")
xlim([0, 610])

% Saving the strobe data to a .mat file
save('brandenburg3.mat');

%% Define the parameters of the participant signaling tone

% Parameters
frequency = 100; % Frequency of the tone in Hz
duration = 2; % Duration of the tone in seconds
sampleRate = 44100; % Sampling rate (number of samples per second)

% Time vector
t = linspace(0, duration, duration * sampleRate);

% Generate the tone
tone = sin(2 * pi * frequency * t);

 %% Device Usage from File
    
    comPort = "COM4"; % You can use serialportlist() to list all available ports
    filename = "Example.txt";
    
    % Before this script is run, the ### sequence should be executed
    if ~exist('preparedStrobeData1D', 'var')
        disp("Cannot find preparedStrobeData1D");
        disp("No strobe data prepared, run something.m first");
        return;
    end
    
    % Don't remake the device if the connection already exists
    if ~exist('device', 'var')
        device = StrobeDevice(comPort);
    end
    
    % Wait 1s for serial thread to start up
    pause(1);
    
    if ~device.isConnected()
        disp("Device not connected.");
        device.closePort();
        clear('device') % Clear the device variable so it is recreated next execution
        return;
    end
    disp("Device connected.");
    
    % Check to see if we have a valid connection
    [device, success] = device.tryGetDeviceInfo(2); % Ask the device for its info
    % StrobeDevice(device) here ensures autocompletion in the rest of the script
    if ~success
        disp("Failed to verify device.");
        device.closePort();
        clear('device') % Clear the device variable so it is recreated next execution
        return;
    end
    disp("Device verified.");
    
    pause(1);
    
    % Check if the file already exists before we try to write to it.
    fileList = device.getFileList();
    for i=1:length(fileList)
        if contains(fileList(i), filename)
            disp("File already exists. Deleting first.")
            disp(device.deleteFile(filename));
        end
    end
    pause(1);
    
    disp("Re-reading file list.")
    fileListAfterDelete = device.getFileList();
    
    pause(1);

    % Play a tone signaling start of sequence
    
    sound(tone, sampleRate);
    pause(duration);
    
    disp("Writing strobe samples to file...")
    response = device.writeToFile(filename, preparedStrobeData1D); % Filename must be at most 8.3 format
    if ~strcmp(response, "Done")
        disp("File write failed, aborting.")
        disp(response);
        device.closePort();
        clear('device') % Clear the device variable so it is recreated next execution
        return;
    end
    disp("Done.")
    pause(1);
    
    disp("Re-reading file list.")
    fileListAfterWrite = device.getFileList();
    pause(1);
    
    disp("Playing strobe file...")
    sound(y, Fs);
    disp(device.playStrobeFile(filename, (length(preparedStrobeData1D)/12000) + 5)); % Play the newly written file and wait N+5 seconds for it to confirm that it has finished.
    pause(1)
    
    disp("Getting device temps:")
    disp(device.getTemperatures()) % Print the device temperatures.
    
    pause(5)

    % When finished wrap up and close the port, stopping the serial thread.
    device.closePort();
    
function value = binary8ToUint8(bitArray)
    value = sum([2^7 2^6, 2^5, 2^4, 2^3, 2^2, 2^1, 2^0] .* bitArray, 2);
    return;
end
