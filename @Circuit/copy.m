function new = copy(obj)
% COPY  generate a separate copy of the Circuit object
%  new = obj.COPY
%
%  Circuits, as well as all Devices, are handle classes.
%  Using a simple assignment just makes a copy of the handle to the object.
%  Changes made through one handle affects the other.
%  The COPY method makes a separate copy, allowing the copy to be modified
%  without affecting the sourhelce.

new = MCIR.Circuit(obj.name);
new.genref = obj.genref; % direct copy possible (no handles)

for c=obj.devices
    % copy each device (handles, so need to use Device.copy method)
    new.devices{end+1} = c{1}.copy;
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net