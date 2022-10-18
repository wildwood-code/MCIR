% SubcircuitPool is a handle class used to hold static data for Subcircuit
% It will contain a pool of references to all Subcircuit class objects,
% allowing Subcircuits to be instantiated into a Circuit or another
% Subcircuit by assigned name
classdef SubcircuitPool < handle
    properties
        Subs  % will be a cell array of Subcircuits
    end
end