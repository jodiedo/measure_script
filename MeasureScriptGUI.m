function varargout = MeasureScriptGUI(varargin)
% MEASURESCRIPTGUI MATLAB code for MeasureScriptGUI.fig
%      MEASURESCRIPTGUI, by itself, creates a new MEASURESCRIPTGUI or raises the existing
%      singleton*.
%
%      H = MEASURESCRIPTGUI returns the handle to a new MEASURESCRIPTGUI or the handle to
%      the existing singleton*.
%
%      MEASURESCRIPTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MEASURESCRIPTGUI.M with the given input arguments.
%
%      MEASURESCRIPTGUI('Property','Value',...) creates a new MEASURESCRIPTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MeasureScriptGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MeasureScriptGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MeasureScriptGUI

% Last Modified by GUIDE v2.5 10-Apr-2017 11:48:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MeasureScriptGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MeasureScriptGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MeasureScriptGUI is made visible.
function MeasureScriptGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% varargin   command line arguments to MeasureScriptGUI (see VARARGIN)

% Choose default command line output for MeasureScriptGUI
handles.output = hObject;

%set additional properties for axes
title(handles.GraphLocalT    ,'Local Temperature Distribution')
xlabel(handles.GraphLocalT   ,'Temperature Sensors','FontSize',8)
ylabel(handles.GraphLocalT   ,'Temperature in °C','FontSize',8)
title(handles.GraphTimeT     ,'Temporal Temperature Distribution')
xlabel(handles.GraphTimeT    ,'Time in s','FontSize',8)
ylabel(handles.GraphTimeT    ,'Temperature in °C','FontSize',8)
legend(handles.GraphTimeT    ,'Sensor 2','Sensor 5')
title(handles.GraphSpectrum  ,'Spectrum')
xlabel(handles.GraphSpectrum ,'Wavenumber in 1/cm','FontSize',8)
ylabel(handles.GraphSpectrum ,'Intensity','FontSize',8)
%devices, add an argument to start in test mode (device response getting
%mocked)
handles.Thermometer = MockThermometer();
handles.Thermostat = MockThermostat();
handles.Spectrometer = MockSpectrometer();
% connect devices
handles.Thermometer.connect();
handles.Thermostat.connect()
handles.Spectrometer.connect();
% Parameter class to store values
handles.Parameters = Parameters();
%
handles.basicPath = 'C:\Users\FuelCaps\Desktop\FuelCaps\Versuche\';
handles.wavenumber = handles.Spectrometer.getWavenumbers();
handles.intensity = zeros(length(handles.wavenumber),1);
handles.temperatureHistory = ones(120, 7)*20;
handles.temperatureTimestamps = ones(120, 1);
handles.DATA = struct();
handles.counter = 1;
%
handles.toc_spectro = [];
handles.toc_temperature = [];
%


% update the GUI edit fields
set(handles.MolfractionInit_SV  ,'String',handles.Parameters.molfractionInit);
% set(handles.Phasestate_SV       ,'String',handles.Parameters.phasestate);
set(handles.CurrentSP_Value     ,'String',handles.Parameters.currentSetpoint);
set(handles.Tstart_SV           ,'String',handles.Parameters.tStart);
set(handles.Tstop_SV            ,'String',handles.Parameters.tStop);
set(handles.Tincr_SV            ,'String',handles.Parameters.tIncr);
set(handles.Pressure_SV         ,'String',handles.Parameters.pressure);
set(handles.DeltaT_SV           ,'String',handles.Parameters.deltaT);
set(handles.NrOfSpectra_SV      ,'String',handles.Parameters.numberOfSpectra);
set(handles.ScansToAverage_SV   ,'String',handles.Parameters.scansToAverage);
set(handles.IntTime_SV          ,'String',handles.Parameters.integrationTime/1E6);
set(handles.CurrentSavePath     ,'String',handles.basicPath);
set(handles.MeasureMode         ,'Value' ,1);
% Update handles structure
guidata(hObject, handles);
plot(handles.GraphSpectrum,handles.wavenumber,handles.intensity);
plot(handles.GraphLocalT,zeros(1,7));
plot(handles.GraphTimeT,handles.temperatureHistory(:,2));
 

function varargout = MeasureScriptGUI_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;  
if ~exist([handles.basicPath datestr(now, 'yymmdd')], 'dir')
        mkdir(handles.basicPath, datestr(now, 'yymmdd'));
        handles.SavePath = [handles.basicPath datestr(now, 'yymmdd') '\'];
else
        handles.SavePath = [handles.basicPath datestr(now, 'yymmdd') '\'];
end
set(handles.CurrentSavePath,'String',handles.SavePath);
handles.Spectrometer.setIntegrationTime(handles.Parameters.integrationTime);
guidata(hObject,handles);
pause(1);
startGUI();
%continuousMode();

function startGUI
handles = guidata(gcf);
handles.spectro_timer = timer('BusyMode','drop','ExecutionMode','FixedSpacing','Name','spectroTimer','Period',(handles.Parameters.acquisitionTime-0.4),'TimerFcn',@(~,~)spectrum);
handles.temp_timer = timer('BusyMode','queue','StartDelay',0.5,'ExecutionMode','FixedRate','Name','tempTimer','Period',1,'TimerFcn',@(~,~)temperature);
handles.refresh_timer = timer('BusyMode','queue','StartDelay',1500,'ExecutionMode','FixedRate','Name','refreshTimer','Period',1500,'TimerFcn',@(~,~)refresh);
start(handles.spectro_timer);
start(handles.temp_timer);
start(handles.refresh_timer);
guidata(gcf,handles);

function temperature
tic;
    handles = guidata(gcf);
    [currentTemperatures, temp_timestamp] = currentT(handles.Thermostat.getPV(),handles.Thermometer.getPV(),handles.Parameters.pressure,handles.SavePath);
    handles.temperatureHistory = [handles.temperatureHistory(2:end,:); currentTemperatures];
    handles.temperatureTimestamps = [handles.temperatureTimestamps(2:end,1); temp_timestamp];
    currentDeltaT = (mean(abs(handles.temperatureHistory(91:end,2)-handles.Parameters.currentSetpoint))+...
                mean(abs(handles.temperatureHistory(91:end,5)-handles.Parameters.currentSetpoint)))/2;
    set(handles.currentDeltaT_SV,'String',sprintf('%4.3f',currentDeltaT));
    if and(handles.Parameters.automation,currentDeltaT < handles.Parameters.deltaT)
        handles.Parameters.measure = 1;
    elseif and(handles.Parameters.automation,handles.Parameters.currentSetpoint < handles.Parameters.tStart)
        handles.Parameters.currentSetpoint = handles.Parameters.tStart;
        handles.Thermostat.setSV(handles.Parameters.tStart);
        set(handles.CurrentSP_Value,'String',handles.Parameters.tStart);
    end
    plot(handles.GraphTimeT,1:120,handles.temperatureHistory(:,2),1:120,handles.temperatureHistory(:,5));
    plot(handles.GraphLocalT,handles.temperatureHistory(120,1:6));
    t = toc;
    handles.toc_temperature= [handles.toc_temperature t];
    guidata(gcf,handles);
  
    
function spectrum
tic
    handles = guidata(gcf);
    handles.intensity = handles.Spectrometer.getSpectrum();
    if and(handles.counter <= handles.Parameters.numberOfSpectra,handles.Parameters.measure)
        [tMean] = currentTMean(handles.Thermostat.getPV(),handles.Thermometer.getPV());
%         [currentTemperatureMean] = currentTMean(handles.Thermostat.getPV(),handles.Thermometer.getPV());
%         tMean = (currentTemperatureMean(4)+currentTemperatureMean(5)+currentTemperatureMean(6))/3;
        if handles.Parameters.background
            spectrum = Data(tMean,handles.Parameters.pressure,handles.wavenumber,handles.intensity,...
                ['bg_' datestr(now, 'HHMMSS') '_' num2str(handles.counter)],handles.SavePath,...
                handles.Parameters.molfractionInit,handles.Parameters.phasestate);
        else 
            spectrum = Data(tMean,handles.Parameters.pressure,handles.wavenumber,handles.intensity,...
                [datestr(now, 'HHMMSS') '_' num2str(handles.counter)],handles.SavePath,...
                handles.Parameters.molfractionInit,handles.Parameters.phasestate);
        end
        spectrum.saveData();
        name = ['id_' spectrum.filename];
        handles.DATA.(name) = spectrum;
        set(handles.SpectraList,'String',fieldnames(handles.DATA));
        set(handles.SpectraList,'UserData',fieldnames(handles.DATA));
        handles.counter = handles.counter + 1;
    elseif handles.counter > handles.Parameters.numberOfSpectra
        handles.counter = 1;
        handles.Parameters.measure = 0;
        if handles.Parameters.background
            handles.Parameters.background = 0;
        elseif and(handles.Parameters.automation,handles.Parameters.currentSetpoint < handles.Parameters.tStop)
            if (handles.Parameters.currentSetpoint + handles.Parameters.tIncr) > handles.Parameters.tStop
                handles.Parameters.currentSetpoint = handles.Parameters.tStop;
                handles.Thermostat.setSV(handles.Parameters.tStop);
                set(handles.CurrentSP_Value,'String',handles.Parameters.tStop);
            else
                handles.Parameters.currentSetpoint = handles.Parameters.currentSetpoint + handles.Parameters.tIncr;
                handles.Thermostat.setSV(handles.Parameters.currentSetpoint);
                set(handles.CurrentSP_Value,'String',handles.Parameters.currentSetpoint);
            end
        elseif and(handles.Parameters.automation,handles.Parameters.currentSetpoint == handles.Parameters.tStop)
            handles.Thermostat.reset();
            handles.Parameters.currentSetpoint = 20;
            set(handles.CurrentSP_Value,'String',20);
            handles.Parameters.automation = 0;
            set(handles.StartStop,'String','START','enable','on');
        end
    end
    if get(handles.MeasureMode,'Value') == 1
        plot(handles.GraphSpectrum,handles.wavenumber,handles.intensity);
        xlim(handles.GraphSpectrum,[handles.Parameters.wMin handles.Parameters.wMax]);
    elseif length(handles.SpectraList.UserData) > 1
        selected = get(handles.SpectraList,'Value');
        handles.DATA.(handles.SpectraList.UserData{selected}).plotData(handles.GraphSpectrum);
        xlim(handles.GraphSpectrum,[handles.Parameters.wMin handles.Parameters.wMax]);
    end
    t = toc;
    handles.toc_spectro = [handles.toc_spectro t];
    guidata(gcf,handles);
    
function [T,timestamp] = currentT(ThermostatValues,ThermometerValues,pressure,basicPath)
    T = zeros(1,7);
    T(1) = ThermometerValues(2);
    T(2) = ThermostatValues(1);
    T(3) = ThermometerValues(3);
    T(4) = ThermometerValues(4);
    T(5) = ThermostatValues(2);
    T(6) = ThermometerValues(5);
    T(7) = ThermometerValues(1);
    timestamp = str2double(datestr(now, 'HHMMSS'));
    if ~exist([basicPath 'Temperatures.txt'], 'file')
        dlmwrite([basicPath 'Temperatures.txt'] , sprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n','timestamp','TC2','TS1', 'TC3', 'TC4', 'TS2', 'TC5', 'TC1', 'pressure'), '');         
    end
    dlmwrite([basicPath 'Temperatures.txt'] , [timestamp T pressure], '-append', 'precision', '%3.2f', 'delimiter', '\t', 'newline', 'pc'); 
    
function [tMean] = currentTMean(ThermostatValues,ThermometerValues)
    T = zeros(1,7);
    T(1) = ThermometerValues(2);
    T(2) = ThermostatValues(1);
    T(3) = ThermometerValues(3);
    T(4) = ThermometerValues(4);
    T(5) = ThermostatValues(2);
    T(6) = ThermometerValues(5);
    T(7) = ThermometerValues(1);
    tMean = (T(4)+T(5)+T(6))/3;
    
function refresh
    handles = guidata(gcf);
    handles.Thermostat.disconnect();
    handles.Thermostat.connect();
    guidata(gcf,handles);

%Callbacks
% function Phasestate_SV_Callback(hObject, eventdata, handles)
% phasestate = round(str2double(get(hObject,'String')));
% if isnan(phasestate)
%     phasestate = 1;
% elseif phasestate < 1
%     phasestate = 1;
% elseif phasestate > 3
%     phasestate = 3;
% end
% set(hObject,'String',phasestate);
% handles.Parameters.phasestate = phasestate;
% guidata(hObject,handles);

function MolfractionInit_SV_Callback(hObject, eventdata, handles)
molfrac = str2double(get(hObject,'String'));
if isnan(molfrac)
    molfrac = 1;
elseif molfrac < 0
    molfrac = 0;
elseif molfrac > 1
    molfrac = 1;
end
set(hObject,'String',molfrac);
handles.Parameters.molfractionInit = molfrac;
guidata(hObject,handles);

function MeasureNow_Callback(hObject, eventdata, handles)
handles.Parameters.measure = 1;
guidata(hObject,handles);

function CurrentSP_Value_Callback(hObject, eventdata, handles)
    currentSP = str2double(get(hObject,'String'));
    if isnan(currentSP)
        currentSP = 20;
    elseif currentSP > 500
        currentSP = 500;
    end
set(hObject,'String',currentSP);
handles.Parameters.currentSetpoint = currentSP;
handles.Thermostat.setSV(currentSP);
guidata(hObject, handles);
    
function IntTime_SV_Callback(hObject, eventdata, handles)
IntegrationTime = str2double(get(hObject,'String'));
if isnan(IntegrationTime)
    IntegrationTime = 1;
elseif IntegrationTime > 100
    IntegrationTime = 100;
end
set(hObject,'String',IntegrationTime);
handles.Spectrometer.setIntegrationTime(IntegrationTime*1E6);
handles.Parameters.integrationTime = IntegrationTime*1E6;
handles.Parameters.updateAcquisitionTime();
stop(handles.spectro_timer);
delete(handles.spectro_timer);
handles.spectro_timer = timer('BusyMode','drop','ExecutionMode','FixedSpacing','Name','spectroTimer','Period',(handles.Parameters.aquisitionTime-0.4),'TimerFcn',@(~,~)spectrum);
start(handles.spectro_timer);
guidata(hObject, handles);

function NrOfSpectra_SV_Callback(hObject, eventdata, handles)
NrOfSpectra = str2double(get(hObject,'String'));
if isnan(NrOfSpectra)
    NrOfSpectra = 1;
elseif NrOfSpectra > 100
    NrOfSpectra = 100;
end
set(hObject,'String',NrOfSpectra);
handles.Parameters.numberOfSpectra = NrOfSpectra;
guidata(hObject, handles);

function ScansToAverage_SV_Callback(hObject, eventdata, handles)
ScansToAverage = str2double(get(hObject,'String'));
if isnan(ScansToAverage)
    ScansToAverage = 1;
elseif ScansToAverage > 100
    ScansToAverage = 100;
end
set(hObject,'String',ScansToAverage);
handles.Parameters.scansToAverage = ScansToAverage;
handles.Parameters.updateAcquisitionTime();
stop(handles.spectro_timer);
delete(handles.spectro_timer);
handles.spectro_timer = timer('BusyMode','drop','ExecutionMode','FixedSpacing','Name','spectroTimer','Period',(handles.Parameters.aquisitionTime-0.4),'TimerFcn',@(~,~)spectrum);
start(handles.spectro_timer);
guidata(hObject, handles);

function Tstart_SV_Callback(hObject, eventdata, handles)
Tstart = str2double(get(hObject,'String'));
tstop = handles.Parameters.tStop;
if isnan(Tstart)
    Tstart = 20;
elseif Tstart < 20
    Tstart = 20;
elseif Tstart > 500
    Tstart = 500;
elseif Tstart > tstop
    handles.Parameters.tStop = Tstart;
    set(handles.Tstop_SV,'String',Tstart);
end
set(hObject,'String',Tstart);
handles.Parameters.tStart = Tstart;
guidata(hObject, handles);

function Tstop_SV_Callback(hObject, eventdata, handles)
Tstop = str2double(get(hObject,'String'));
min_tstop = handles.Parameters.tStart;
if isnan(Tstop)
    Tstop = min_tstop;
elseif Tstop < min_tstop
    Tstop = min_tstop;
elseif Tstop > 500
    Tstop = 500;
end
set(hObject,'String',Tstop);
handles.Parameters.tStop = Tstop;
guidata(hObject, handles);

function Tincr_SV_Callback(hObject, eventdata, handles)
Tincr = str2double(get(hObject,'String'));
max_incr = handles.Parameters.tStop - handles.Parameters.tStart;
if isnan(Tincr)
    Tincr = 1;
elseif Tincr < 0
    Tincr = 1;
elseif Tincr > max_incr
    Tincr = max_incr;
end
set(hObject,'String',Tincr);
handles.Parameters.tIncr = Tincr;
guidata(hObject, handles);

function Pressure_SV_Callback(hObject, eventdata, handles)
Pressure = str2double(get(hObject,'String'));
if isnan(Pressure)
    Pressure = 0;
elseif Pressure < 0
    Pressure = 0;
elseif Pressure > 500
    Pressure = 500;
end
set(hObject,'String',Pressure);
handles.Parameters.pressure = Pressure;
guidata(hObject, handles);

function DeltaT_SV_Callback(hObject, eventdata, handles)
DeltaT = str2double(get(hObject,'String'));
max_deltaT = handles.Parameters.tIncr;
if isnan(DeltaT)
    DeltaT = 1;
elseif DeltaT < 0
    DeltaT = 1;
elseif DeltaT > max_deltaT
    DeltaT = max_deltaT;
end
set(hObject,'String',DeltaT);
handles.Parameters.deltaT = DeltaT;
guidata(hObject, handles);

function MeasureMode_Callback(hObject, eventdata, handles)
if get(handles.MeasureMode,'Value') == 1
    set(handles.HistoryMode,'Value',0);
elseif get(handles.MeasureMode,'Value') == 0
    set(handles.HistoryMode,'Value',1);
end
guidata(hObject,handles);

function HistoryMode_Callback(hObject, eventdata, handles)
if get(handles.HistoryMode,'Value') == 1
    set(handles.MeasureMode,'Value',0);
elseif get(handles.HistoryMode,'Value') == 0
    set(handles.MeasureMode,'Value',1);
end
guidata(hObject,handles);

function ResetThermostat_Callback(hObject, eventdata, handles)
handles.Parameters.measure = 0;
handles.Parameters.automation = 0;
handles.Parameters.currentSetpoint = 20;
handles.Thermostat.reset();
set(handles.CurrentSP_Value,'String',20);
guidata(hObject,handles);

function StartStop_Callback(hObject, eventdata, handles)
set(hObject,'String','STOP','enable','off');
handles.Parameters.automation = 1;
guidata(hObject,handles);

function StartStop_ButtonDownFcn(hObject, eventdata, handles)
set(hObject,'String','START','enable','on');
handles.Parameters.automation = 0;
handles.Parameters.measure = 0;
guidata(hObject,handles);

function ChangePath_Callback(hObject, eventdata, handles)
new_path = uigetdir;
handles.basicPath = [new_path '\'];
if ~exist([handles.basicPath datestr(now, 'yymmdd')], 'dir')
        mkdir(handles.basicPath, datestr(now, 'yymmdd'));
        handles.SavePath = [handles.basicPath datestr(now, 'yymmdd') '\'];
else
        handles.SavePath = [handles.basicPath datestr(now, 'yymmdd') '\'];
end
set(handles.CurrentSavePath,'String',handles.SavePath);
guidata(hObject,handles);

function SpectraList_Callback(hObject, eventdata, handles) %#ok<*INUSD>

function Exit_Callback(hObject, eventdata, handles)
stop(handles.refresh_timer);
stop(handles.temp_timer);
stop(handles.spectro_timer);
delete(handles.refresh_timer);
delete(handles.temp_timer);
delete(handles.spectro_timer);
%Reset thermostat to 20 degree
handles.Thermostat.reset();
handles.Spectrometer.disconnect();
handles.Thermometer.disconnect();
handles.Thermostat.disconnect();
pause(2);
assignin('base','toc_spectro',handles.toc_spectro);
assignin('base','toc_temperature',handles.toc_spectro);
%close all connected devices
close all;

function Wmin_Callback(hObject, eventdata, handles) %#ok<*DEFNU,*INUSL>
Wmin = str2double(get(hObject,'String'));
max_Wmin = handles.Parameters.wMax;
if isnan(Wmin)
    Wmin = 0;
elseif Wmin < 0
    Wmin = 0;
elseif Wmin > max_Wmin
    Wmin = max_Wmin;
end
set(hObject,'String',Wmin);
handles.Parameters.wMin = Wmin;
guidata(hObject, handles);

function Wmax_Callback(hObject, eventdata, handles)
Wmax = str2double(get(hObject,'String'));
min_Wmax = handles.Parameters.wMin;
if isnan(Wmax)
    Wmax = 4500;
elseif Wmax < 0
    Wmax = 4500;
elseif Wmax < min_Wmax
    Wmax = min_Wmax;
end
set(hObject,'String',Wmax);
handles.Parameters.wMax = Wmax;
guidata(hObject, handles);

function Phasestate_Callback(hObject, eventdata, handles)
handles.Parameters.phasestate = get(hObject,'Value');
guidata(hObject, handles)

function InfoBox_Callback(hObject, eventdata, handles)
text = get(hObject, 'String');
handles.Parameters.infoText = text;
guidata(hObject,handles);

function BackgroundSpectrum_Callback(hObject, eventdata, handles)
handles.Parameters.measure = 1;
handles.Parameters.background = 1;
guidata(hObject,handles);

%Create Functions
function SpectraList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DeltaT_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function IntTime_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Pressure_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Tincr_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Tstop_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Tstart_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function NrOfSpectra_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ScansToAverage_SV_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function MolfractionInit_SV_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Phasestate_SV_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Wmin_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Wmax_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function InfoBox_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Phasestate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%


% --------------------------------------------------------------------
function saveParameters_Callback(hObject, eventdata, handles)
handles.Parameters.saveParameters(handles.SavePath);

