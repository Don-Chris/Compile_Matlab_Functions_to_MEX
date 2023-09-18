function fcnHandle = compile_to_mex( command, varargin )
% fcnHandle = compile_to_mex( command, 'option1', value1, 'option2', value2, ... )
% fcnHandle = compile_to_mex( command )
% 
%
% --------- Input: ---------
%        'command': Has to be the string of an example command with the 
%                   right input arguments of the matlab function.
%                   The command must be executable in the base workspace,
%                   so all named arguments and the function name have to 
%                   exist.
%                   e.g.: 'fcnName(argument1,argument2,structElement)'
%
%
% ------- Features: --------
%       - Compiles a matlab function to c code 
%       - Creates a matlab-wrapper function that passes the right datatypes
%         in the mex function
%
%
% -------- Options: --------
%          'path': currentPath (default), e.g. "C:/path/to/file/"
%                      path to the mex and wrapper file
%
%          'path_coder': like 'path' (default), e.g. "C:/path/to/file/"
%                      path to the generated c-code 
%
%          'type': 'mex' (default)
%                      See Matlab Coder for options
%
%          'exactSize': false (default)
%                      Should all input arguments have the same size as in 
%                      the examples command or should all arguments with 
%                      size [n,1] or [n,n] be unlimited in "n".
%
%          'sortStruct': false (default)
%                      Should input structs be sorted before compiling? The
%                      order of the struct-fields cant be changed
%                      afterwards
%
%          'dataType': '' (default), e.g. 'single','double'
%                      Should all input arguments be mapped to one datatype
%                      before compiling? Cant be changed afterwards
%
%          'create_wrapper': true (default)
%                      Should a wrapper function be created that has the
%                      same inputs as the original function (and the mex
%                      function) but it converts all inputs to the compiled
%                      datatype and changes the order of the structs to the
%                      needed order.
%          'inputs': [] (default), e.g. a struct with all inputs to the
%                      function, the order of the fields matter.
%                      This option can be used to give all inputs to the
%                      code generation. If this option is not used, the
%                      inputs will be evaluated in the base workspace with
%                      the names in the example Command.
%
%
% ------- Created by -------
% Institute of Automatic Control, RWTH Aachen
% Christopher Schulte, April 2022
% c.schulte@irt.rwth-aachen.de


%% Get Options
opts.path = pwd;
opts.path_coder = '';
opts.type = 'mex';
opts.exactSize = false;
opts.sortStruct = false;
opts.dataType = '';
opts.create_wrapper = true;
opts.inputs = [];
opts = checkOptions(opts,varargin);


%% Path
if isempty(opts.path_coder)
    opts.path_coder = opts.path;
end


%% Get Function name
list_bracket1 = strfind(command,'(');
list_bracket2 = strfind(command,')');
list_equal = strfind(command,'=');
if isempty(list_equal)
    list_equal = 1;
end
if isempty(list_bracket1)
    list_bracket1 = length(command)+1;
end
fcnName = command(list_equal:list_bracket1(1)-1);



%% Get list of Arguments
if isempty(opts.inputs) % Evaluate in base workspace
    % Get input names
    arguments = command(list_bracket1(1)+1:list_bracket2(end)-1);

    list_comma = [0,strfind(arguments,','),length(arguments)+1];
    list_bracket1 = strfind(arguments,'(');
    list_bracket2 = strfind(arguments,')');
    nextStartPos = 1;
    cnt = 0;
    argsChar = cell(length(list_comma)-2,1);
    for idx = 2:length(list_comma)
        if length(list_bracket1) ~= length(list_bracket2)
            error([' - compile_to_mex: Command "', command, '" is probably wrong.'])
        end
        if isempty(list_bracket1) && isempty(list_bracket2)
            count_bracket1 = 0;
            count_bracket2 = 0;
        else
            count_bracket1 = sum(list_bracket1 < list_comma(idx) && list_bracket1 > list_comma(idx-1) );
            count_bracket2 = sum(list_bracket2 < list_comma(idx) && list_bracket2 > list_comma(idx-1) );
        end

        if count_bracket1 == count_bracket2
            argsChar{cnt+1} = arguments(nextStartPos:list_comma(idx)-1);
            nextStartPos = list_comma(idx) + 1;
            cnt = cnt + 1;
        end
    end
    argsChar = argsChar(1:cnt);
    
    % Get Data
    argsData = cell(length(argsChar),1);
    for idx = 1:length(argsChar)
        argsData{idx} = evalin('base', [argsChar{idx},';']);

    end
else % use opts.inputs
    
    % Get input names
    argsChar = fieldnames(opts.inputs);
    
    % Get Data
    argsData = cell(length(argsChar),1);
    for idx = 1:length(argsChar)
        argsData{idx} = opts.inputs.(argsChar{idx});
    end
end

%% Get Argument data and type info
ARGS = cell(length(argsChar),1);
for idx = 1:length(argsChar)
    ARGS{idx} = getType(argsData{idx},opts);
end

%% CodeGen
cfg = coder.config(opts.type);
cfg.GenerateReport = true;
cfg.EnableJIT = true;

codeCommand = sprintf('codegen -config cfg %s -args ARGS',fcnName);

mex_fcn_name = [fcnName,'_mex'];
currentpath = cd;
try
    cd(opts.path_coder)
    eval(codeCommand)
    if ~strcmp(opts.path_coder,opts.path)
        source_path = fullfile(opts.path_coder,[mex_fcn_name,'.',mexext]);
        new_path = fullfile(opts.path,[mex_fcn_name,'.',mexext]);
        movefile(source_path,new_path);
    end
catch message
    cd(currentpath);
    error(message.message)
end
cd(currentpath);


%% Create Wrapper
if opts.create_wrapper
    fcnHandle = create_mex_wrapper(mex_fcn_name, ARGS, argsChar, ...
        'path',opts.path);
else
    fcnHandle = str2func(mex_fcn_name);
end
end


%% Other functions
% Function for recursive type info
function type = getType(data,opts)
if isstruct(data)
    fields = fieldnames(data);
    for idx = 1:length(fields)
        Struct.(fields{idx}) = getType(data.(fields{idx}),opts);
    end
    if opts.sortStruct % sort Struct
        Struct = orderFields(Struct);
    end
    type = coder.typeof(Struct);
else
    sizeVec = size(data);
    variableSize = zeros(1,numel(sizeVec));
    if ~opts.exactSize
        variableSize(sizeVec >1) = 1;
        sizeVec(sizeVec >1) = Inf;
    end
    if ~isempty(opts.dataType)
        data = cast(data,opts.dataType);
    end
    type = coder.typeof(data,sizeVec,variableSize);
end
end