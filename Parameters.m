classdef Parameters < handle
    properties
        automation     
        measure      
        integrationTime
        scansToAverage
        acquisitionTime
        numberOfSpectra 
        tStart         
        tStop           
        tIncr           
        pressure       
        deltaT          
        currentSetpoint
        molfractionInit 
        phasestate
        wMin
        wMax
        infoText
        background
    end
    methods
        function obj = Parameters()
        obj.automation      = 0;
        obj.measure         = 0;
        obj.integrationTime = 4000000;
        obj.scansToAverage  = 1;
        obj.acquisitionTime = 4;
        obj.numberOfSpectra = 16;
        obj.tStart          = 20;
        obj.tStop           = 30;
        obj.tIncr           = 10;
        obj.pressure        = 0;
        obj.deltaT          = 1;
        obj.currentSetpoint = 20;
        obj.molfractionInit = 1;
        obj.phasestate      = 1;
        obj.wMin            = 0;
        obj.wMax            = 4500;
        obj.background      = 0;
        obj.infoText        = ' ';
        end
        function updateAcquisitionTime(obj)
            obj.acquisitionTime = obj.integrationTime*obj.scansToAverage/1E6;
        end
        function saveParameters(obj,path)
            currentDir = pwd;
            cd(path);
            ID = fopen(['Parameters_' datestr(now, 'HHMMSS') '.txt'],'w');
            fprintf(ID,'%-20s\t%-20s\r\n','info text',obj.infoText);
            fprintf(ID,'%-20s\t%-20f\r\n','integration time',obj.integrationTime);
            fprintf(ID,'%-20s\t%-20f\r\n','scans to average',obj.scansToAverage);
            fclose(ID);
            cd(currentDir);
        end
    end
end