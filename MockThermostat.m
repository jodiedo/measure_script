classdef MockThermostat < handle
   properties
       test = 1;
       SetpointValue =20;
       ProcessValue =20;
       opcItems
       opcClient
       index = 1;
    end
    methods
        function obj = MockThermostat(test)
            if nargin < 1
                obj.test = 0;
            end
        end
        function [opcItems,opcClient] = connect(obj)
            if ~obj.test
                [opcItems, opcClient] = conServ();
                obj.opcItems = opcItems;
                obj.opcClient = opcClient;
            end                
        end
        function disconnect(obj)
            if ~obj.test
                disconnect(obj.opcClient);
                delete(obj.opcClient);
            end
        end
        function setSV(obj,SP)
            if ~obj.test
                write(obj.opcItems(3),SP);
                write(obj.opcItems(4),SP);
            end
            obj.index = 1;
            obj.SetpointValue = SP;
        end
        function SV = getSV(obj)
            if ~obj.test
               % SV = [obj.opcItems(3).Value obj.opcItems(4).Value];
               SV = obj.opcItems(3).Value;
            end
            %SV = [obj.SetpointValue obj.SetpointValue];
            SV = obj.SetpointValue;
        end
        function setPV(obj,PV)
            obj.ProcessValue = PV;
        end
        function PV = getPV(obj)
            if ~obj.test
                PV = [obj.opcItems(1).Value obj.opcItems(2).Value];
                n = 0;
%                 while or(numel(PV) ~= 2, n ~= 20) 
%                     PV = [obj.opcItems(1).Value obj.opcItems(2).Value];
%                     n = n + 1;
%                     pause(0.1);
%                 end
                while numel(PV) ~= 2
                    PV = [obj.opcItems(1).Value obj.opcItems(2).Value];
                    n = n + 1;
                    pause(0.1);
                    if n >= 20
                        break
                    end
                end
                return
            else
                x = 0:1:1200*pi;
                obj.ProcessValue = obj.SetpointValue + dampOscillation(x(obj.index));
                PV = [obj.ProcessValue+rand(1) obj.ProcessValue+rand(1)];
                if obj.index > length(x)
                    obj.index = 1;
                end
                obj.index = obj.index + 1;
            end
        end
        function reset(obj)
            if ~obj.test
                write(obj.opcItems(3),20);
                write(obj.opcItems(4),20);
            end
            obj.index = 1;
            obj.ProcessValue = 20;
            obj.SetpointValue = 20;
        end
    end
end