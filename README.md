# midi_strobe
creating an SCCS strobe sequence aligning with the frequencies (minus a perfect third for greater intermodulation distortion) and amplitudes of each time slice within any midi file

This script requires a .midi file of your favorite piece of music, using the Midi Toolbox, Audio Toolbox, and Signal Processing Toolboxes. The Midi Toolbox can be found here: https://github.com/miditoolbox/ 
(The latter two toolboxes can be installed directly from MATLAB.)

It converts each value for note (pitch) of the midi file into its corresponding note. 

Values for pitch are then transmuted into the corresponding frequencies for the C-1 to B-1 range ("subsubcontra"), transposed down one major third from Ab-2 to G-1 for greater intermodulation distortion between auditory and visual information, 
and the aligned with the note data within the midi file to associate the frequency of the light with each change in dominant note per time slice.

Velocity (loudness) is transformed into amplitude by correcting for the general reduction in dynamic notation used to form midi files; to remain on the upper end of the brightness spectrum of the device, these values are 
then made relative to the 125-255 brightness scale of the light to shift the brightness range upward so that the loudest moments of each song are met with the maximum intensity of the strobe light. 

Frequency and amplitude per time sample are then fed into a periodic strobosopic stimulation sequence for the SCCS research strobe.

This repository contains one example of this script in action to J.S. Bach's "Brandenburg Concerto No. 3 in G Major, BWV 1048".
