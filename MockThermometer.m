classdef MockThermometer < handle
   properties
       test = 1;
       tc08
       tc08Vals
    end
    methods
        function obj = MockThermometer(test)
            if nargin < 1
               obj.test = 0;
            end
        end
        function connect(obj)
            if ~obj.test
               loadlibrary('usbtc08.dll', @USBTC08MFile);
               obj.tc08 = usbtc08connectslow(['K', 'K', 'K', 'K']); 
            end
        end
        function disconnect(obj)
            if ~obj.test
                usbtc08disconnectslow(obj.tc08);
            end
        end
        function tc08Vals = getPV(obj)
            if ~obj.test
                obj.tc08Vals = usbtc08queryslow(obj.tc08, 0);
            else
                obj.tc08Vals = [1,1,1,1,1];
            end
            tc08Vals = obj.tc08Vals;
        end
    end
end