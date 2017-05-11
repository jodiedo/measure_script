function [opcItems, opcClient] = conServ()

strIP = 'localhost';
strServName = 'Eurotherm.ModbusServer.1';

opcClient = opcda(strIP, strServName);
connect(opcClient);
grp = addgroup(opcClient);

PV1 = additem(grp, '3504.192-168-7-42-502-ID001-3504.Loop.1.Main.PV');
PV2 = additem(grp, '3504.192-168-7-42-502-ID001-3504.Loop.2.Main.PV');
SP1 = additem(grp, '3504.192-168-7-42-502-ID001-3504.Loop.1.SP.SP1');
SP2 = additem(grp, '3504.192-168-7-42-502-ID001-3504.Loop.2.SP.SP1');

opcItems = [PV1, PV2, SP1, SP2];
