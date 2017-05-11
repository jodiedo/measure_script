function handle = usbtc08connectslow(types, tc08Path)
% USBTC08CONNECTSLOW configures the USB Pico Technology TC-08 data logger
% handle = usbtc08connect(types, tc08Path) configures the USB Pico
% Technology TC-08 data logger where types is a string or a vector array of
% strings of the respective channel types e.g. 'K' for type K
% thermocouples, and 'X' for measuring the voltage. If the tc08Path is
% supplied, it must point to the folder containing the DLLs, otherwise it
% assumes a default path of 'C:\Program Files (x86)\Pico Technology\Pico
% Full'.  Empty paths are also acceptable, in which case the default is
% used.  handle is the handle of the TC-08 for using usbtc08query, or is 0
% if any of the steps were unsuccessful.  This is the much slower method
% (ca. 0.9 s to read out all 8 channels), but also returns the cold
% junction temperature.

% e.g. usbtc08connect('KKX') sets up a USB TC-08 with 2 type K
% thermocouples and 1 voltage measurement, numbered as channels 2, 3 and 4
% (the cold junction is #1).  Returns the handle.

% Range

% types = string or vector array of strings: 'B', 'E', 'J', 'K', 'N', 'R',
% 'S', 'T' for different thermocouples, or 'X' for measuring voltages


% number of arguments error check
narginchk(1, 2)

% error handling
if ~ischar(types) || ~any(ismember('BEJKNRSTX', types)) || numel(types) > 8
    % errors
    error('types must be a string or a vector array of strings no longer than 8, being either: B, E, J, K, N, R, S, T or X')
    
elseif nargin >= 2 && ~isempty(tc08Path) && ~exist(tc08Path, 'file')
    % errors
    error('If supplied, the folder must be a valid folder, containing the correct DLLs and header file.')
end

% variables for location and filenames
tc08LibraryName = 'usbtc08';
tc08Call = 'usb_tc08';

% define a default path
tc08DefaultPath = 'C:\Users\FuelCaps\Desktop\CapCon';

% need to define a default path if necessary
if nargin <= 2 || isempty(tc08Path)
    % for development
    tc08Path = tc08DefaultPath;
end

% defines the file locations
tc08dllLocation = [tc08Path, filesep, tc08LibraryName '.dll'];
tc08hLocation = [tc08Path, filesep, tc08LibraryName, '.h'];

% if either doesn't exist, give a warning about using default path
% if ~exist(tc08dllLocation, 'file') || ~exist(tc08hLocation, 'file')
%     % warning
%     warning('usbtc08Connect:incorrectPath', 'Either the dll or the h file could not be found, reverting to default location...')
% 
%     % redefines the path as the default
%     tc08Path = tc08DefaultPath;
%     
%     % redefines the file locations
%     tc08dllLocation = [tc08Path, filesep, tc08LibraryName '.dll'];
%     tc08hLocation = [tc08Path, filesep, 'usbtc08', '.h'];
% end

% loads the dll library and accompanying header file
if ~libisloaded(tc08LibraryName)
    % loads function library - this will error if it doesn't work, so we
    % don't need to check it again
    loadlibrary(tc08dllLocation, @USBTC08MFile)
end

% format is (from libfunctionsview(tc08LibraryName)
% int16 = usb_tc08_open_unit ...except calllib always turns scalars outputs
% into double, so we need to convert it back into int16 so it works
% properly with the other functions
handle = int16(calllib(tc08LibraryName, [tc08Call, '_open_unit']));

% handling of response
switch handle
    
    case -1
        % Unit found, but couldn't open it
        error('Unit failed to open - call ''usb_tc08_last_error'' to see why.')
        
    case 0
        % couldn't find any units - possible it isn't plugged in or the
        % drivers never loaded
        error('Could not detect any units to connect to.')
        
    otherwise
        % if its 1 or larger, then its the handle of a unit
        %disp(['Connected successfuly to unit ', num2str(tc08Handle)])
end

% sets up the channels

% convert it to the right datatype for calling the DLL
types = int8(types);

% loops to calibrate all the channels
for m = int16(1:numel(types))
    
    % format should be...
    %int16 = usb_tc08_set_channel(int16, int16, int8)

    % returns 1 if OK (stored for later comparison)
    response = calllib(tc08LibraryName, 'usb_tc08_set_channel', handle, m, types(m));
    
    % displays something if it didn't work
    if ~response
        
        % it didn't
        disp(['Channel ', num2str(m), ' failed to initialise.'])
    end
end