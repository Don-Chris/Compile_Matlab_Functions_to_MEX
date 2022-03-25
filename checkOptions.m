function options = checkOptions(options, inputArgs, doWarning)
% options = checkOptions(options, inputArgs, doWarning)
%
% options: struct with valid fields
% inputargs: a cell of inputs -> varargin of a higher function
% doWarning: true (default), false
%

if nargin == 2
    doWarning = true;
end

if doWarning
    stack = dbstack(1);
    fcnName = stack(1).name;
else
    fcnName = '';
end

% List of valid options to accept, simple way to deal with illegal user input
validEntries = fieldnames(options);

% Loop over each input name-value pair, check whether name is valid and overwrite fieldname in options structure.
for ii = 1:2:length(inputArgs)
    entry = inputArgs{ii};
    
    [isValid,validEntry] = isValidEntry(validEntries,entry,fcnName,doWarning);
    if ischar(entry) && isValid
        options.(validEntry) = inputArgs{ii+1};
        
    elseif isstruct(entry)
        fieldNames = fieldnames(entry);
        for idx = 1:length(fieldNames)
            subentry = fieldNames{idx};
            [isval,validEntry] = isValidEntry(validEntries,subentry,fcnName,doWarning);
            if isval 
                options.(validEntry) = entry.(subentry);
            end
        end
    else
        continue;
    end
end
end

function [bool,validEntry] = isValidEntry(validEntries, input, fcnName,doWarning)
% allow input of an options structure that overwrites existing fieldnames with its own, for increased flexibility
bool = false;
validEntry = '';
valIdx = strcmpi(input,validEntries);
if nnz(valIdx) == 0 && ~isstruct(input)
    valIdx = contains(validEntries,input,'IgnoreCase',true);
end
if nnz(valIdx) > 1 && doWarning
    strings = [validEntries(1); strcat(',', validEntries(2:end)) ] ; % removes ' ' at the end when concatenating
    longString = [strings{:}];
    longString = strrep(longString,',',', ');
    error(['-',fcnName,'.m: Option "', input,'" not correct. Allowed options are [', longString, '].'])
elseif nnz(valIdx) > 0 % All else options
    validEntry = validEntries{valIdx};
    bool = true;
elseif doWarning && ~isstruct(input)
    strings = [validEntries(1); strcat(',', validEntries(2:end)) ] ; % removes ' ' at the end when concatenating
    longString = [strings{:}];
    longString = strrep(longString,',',', ');
    warning(['-',fcnName,'.m: Option "', input,'" not found. Allowed options are [', longString, '].'])
end
end
