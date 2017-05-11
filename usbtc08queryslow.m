function [response, overflowFlag] = usbtc08queryslow(handle, units)
% USBTC08QUERYSLOW gets information from USB TC-08 data loggers
% response = usbtc08query(handle, units) returns the values (as a numeric
% column vector) from the number of channels specified by
% usbtc08connectslow, including the cold junction as item #1.
% usbtc08connectslow must be run first to configure the USB TC-08 and to
% obtain the handle.  Units (for thermocouples only) can be 0 (Celsius), 1
% (Fahrenheit), 2 (Kelvin) or 3 (Rankine).  If overflowFlag is supplied,
% then it is a logical vector the same size as the data, where the flag is
% 1 if it overflowed the buffer (i.e. the measurement was out of range).


% number of arguments error check
narginchk(1, 2)

% define default units if necessary
if nargin == 1
    
    % default is Celsius
    units = 0;
end

% checks validity of handle
if ~isvalidtc08handle(handle)
    
    % complains
    error('handle must be valid for use with USB TC-08 DLLs.')
    
% checks we can run this
elseif ~libisloaded('usbtc08')
    
    % complain
    error('USB TC-08 library is not loaded.')

% check the units (but not worrying about the datatype - fix that later
elseif ~isscalar(units) || ~isnumeric(units) || ~ismember(units, [0, 1, 2, 3])
    
    % units must be valid if specified
    error('Units must be set to 0 (Celsius), 1 (Fahrenheit), 2 (Kelvin) or 3 (Rankine) only.')
end

% channels
channels = 9;

% need to define the pointers for the data
dataPointer = libpointer('singlePtr', NaN(channels, 1));
overflowPointer = libpointer('int16Ptr', 0);

% fetches data into DLL - the final 0 is for the units being Celsius
readResponse = calllib('usbtc08', 'usb_tc08_get_single', handle, dataPointer, overflowPointer, int16(units));

% message or not
if ~readResponse
    % it didn't work
    error('Data not successfully read.')
    
else
    
    % fetches data into MATLAB (includes the cold junction temperature)
    response = get(dataPointer, 'Value');
    
    % checks the overflowBuffer if the argument was supplied - bits 1
    % through 9 (LSB to MSB) indicate whether or not the overflow buffer
    % has been exceeded (i.e. out of range measurements) for channels 1 to
    % 9 - not worth checking if the output argument wasn't supplied
    if nargout >= 2
        
        % gets the overflow indicator
        overflow = get(overflowPointer, 'Value');
        
        % get the first 9 bits
        overflowFlag = bitget(overflow, 1:channels);
    end
end