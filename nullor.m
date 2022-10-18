% NULLOR   ideal nullator-norator pair
%
% Description:
%   NULLOR is an ideal nullor consisting of a nullator and norator
%   A nullor is useful for modeling an ideal operational-amplifier
%   The nullator input has a voltage V(nu1,nu2)==0 and an input current
%   I(nu1->nu2)==0. The norator output has a voltage and current that are
%   not constrained.
%
%   Remember in the nullor syntax, the norator pins come first followed by
%   the nullator pins (similar to VCVS syntax)
%
%   Card syntax: Nname no1 no2 nu1 nu2
%
% Interface:
%   N = nullor(no1, no2, nu1, nu2)
%   N.equations                - generate equations for the device
%   N.list                     - list the device
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS

classdef nullor < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Access=protected)
        nodes
    end
    
    methods % interface methods
        
        function obj = nullor(no1, no2, nu1, nu2)
            narginchk(4,4)
            name = 'N@'; % auto-generated
            obj@MCIR.Device(name);
            [~,no1] = MCIR.Device.V(no1);
            [~,no2] = MCIR.Device.V(no2);
            [~,nu1] = MCIR.Device.V(nu1);
            [~,nu2] = MCIR.Device.V(nu2);
            obj.nodes = cell(1,4);
            obj.nodes{1} = no1;
            obj.nodes{2} = no2;
            obj.nodes{3} = nu1;
            obj.nodes{4} = nu2;
        end
        
        function new = copy(obj)
            new = MCIR.nullor(obj.nodes{1}, obj.nodes{2}, obj.nodes{3}, obj.nodes{4});
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s %s %s", obj.name, obj.nodes{1}, obj.nodes{2}, obj.nodes{3}, obj.nodes{4});
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, params) %#ok<INUSD>
            narginchk(2,2)
            % alter must be implemented to de-abstract class, but there is
            % nothing to alter in a nullor
        end
  
        function card = get.card(obj)
            card = obj.list;
        end
        
    end % interface methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'nullor';
        end
        
        function eqns = generate_equations(obj)
            name = obj.name;
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.V(obj.nodes{3});
            v(4).name = MCIR.Device.V(obj.nodes{4});
            v(5).name = MCIR.Device.I(name);
            eqns = obj.pack_equations([0 0 0 0 1;0 0 0 0 -1;0 0 0 0 0;0 0 0 0 0;0 0 1 -1 0],v);
        end
    end
    
    methods (Static, Access=public)
        function [N,tf] = SPICE(card)
            [name, nodes, ~, ~] = MCIR.Device.SPICE_card(card, 'N', 4);
            if ~isempty(name)
                tf = true;
                N = MCIR.nullor(nodes{1}, nodes{2}, nodes{3}, nodes{4});
                N.name = name;
            else
                tf = false;
                N = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net