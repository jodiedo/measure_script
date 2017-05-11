classdef MockSpectrometer < handle
    properties
        test = 1;
        spectro
        integrationTime = 2000000;
    end
    methods
        function obj = MockSpectrometer(test)
            if nargin < 1 
                obj.test = 0;
            end
        end
        function connect(obj)
            if ~obj.test
                javaaddpath('C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME\OmniDriver.jar'); 
                try
                    obj.spectro = com.oceanoptics.omnidriver.api.wrapper.Wrapper(); 
                    assignin('base','spectro_lib',obj.spectro);
                catch
                    obj.spectro = spectro_lib;
                end
                obj.spectro.openAllSpectrometers(); 
                obj.spectro.setIntegrationTime(0, obj.integrationTime);
            end
        end
        function setIntegrationTime(obj,intTime)
            if ~obj.test
                obj.spectro.setIntegrationTime(0,intTime);
            end
            obj.integrationTime = intTime;
        end
        function WL = getWavenumbers(obj)
            if ~obj.test
                WL = (1/532 - 1./obj.spectro.getWavelengths(0))*1E7;
            else
                WL = 1500:4000;
                WL = WL(:);
            end
        end
        function disconnect(obj)
            if ~obj.test
                obj.spectro.closeAllSpectrometers()
            end
        end
        function Intensity = getSpectrum(obj)
            if ~obj.test
                Intensity = obj.spectro.getSpectrum(0);
            else
                Intensity = randomizeData();
                Intensity = Intensity(:);
            end
        end
    end
end

