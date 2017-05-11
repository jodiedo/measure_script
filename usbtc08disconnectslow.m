function usbtc08disconnectslow(handle)
% USBTC08DISCONNECTSLOW disconnects the USB TC-08 from MATLAB
% usbtc08disconnectslow(handle) disconnects the USB TC-08 from MATLAB and
% unloads the DLL's, where tc08Handle is an integer from 1-65535 supplied
% by usbtc08connectslow.

% number of arguments error check
narginchk(1, 1)

% initialises variables for convenience
tc08LibraryName = 'usbtc08';

% error handling
if ~isvalidtc08handle(handle)
    % errors
    error('handle must be an unsigned integer from 1 to 65335')
    
elseif ~libisloaded(tc08LibraryName)
    % errors
    error('dll is not loaded - TC-08 is not currently connected anyway')
end

% close unit
closeOutcome = calllib(tc08LibraryName, 'usb_tc08_close_unit', handle);

% if 0...it didn't close properly
if ~closeOutcome
    % close
    warning('Failed to close connection with USB TC-08.')
end

% tries to unload the libraries
try
    % unload
    unloadlibrary(tc08LibraryName)
    
catch
    % warns
    warning('Unable to unload USB TC-08 library.')
end