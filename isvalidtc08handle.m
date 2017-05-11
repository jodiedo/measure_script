function response = isvalidtc08handle(handle)
% ISVALIDTC08HANDLE superficially checks the validity of a USB TC-08 handle
% response = isvalidtc08handle(handle) returns true, only if the handle is
% a scalar int16 from 1 to 65535.

response = isscalar(handle) && isa(handle, 'int16') && handle >=1 && handle <= 65535;