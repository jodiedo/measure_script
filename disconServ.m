function disconServ(handle)

opcClient = getappdata(handle, 'opcClient');

disconnect(opcClient);
delete(opcClient);