classdef Data < handle
    properties
        temperature
        pressure
        filename
        pathname
        wavenumber
        intensity
        molefractioninit = 0;
        phasestate = 0;
    end
    methods
        function obj = Data(T,P,W,I,filename,path,molf,phase)
            obj.temperature = T;
            obj.pressure = P;
            obj.wavenumber = W;
            obj.intensity = I;
            obj.filename = filename;
            obj.pathname = path;
            obj.molefractioninit = molf;
            obj.phasestate = phase;
       end
        function plotData(obj,axes_handle)
            plot(axes_handle,obj.wavenumber,obj.intensity);
        end
        function saveData(obj)
            dlmwrite([obj.pathname obj.filename '.txt'], sprintf('%-15s\t%-15s\t%-15s\t%-15s\t%-15s\t%-15s\r\n','Wavenumber','Intensity','Temperature', 'Pressure', 'MolfractionInit', 'Phasestate'), '');
            dlmwrite([obj.pathname obj.filename '.txt'], [obj.wavenumber(1) obj.intensity(1) obj.temperature obj.pressure obj.molefractioninit obj.phasestate], '-append', 'precision','%-15.2f','delimiter', '\t', 'newline', 'pc');
            dlmwrite([obj.pathname obj.filename '.txt'], [obj.wavenumber(2:end) obj.intensity(2:end)], '-append', 'precision','%-15.2f','delimiter', '\t', 'newline', 'pc');
        end
    end
end