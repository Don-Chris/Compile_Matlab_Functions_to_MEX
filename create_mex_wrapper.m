function fcnHandle = create_mex_wrapper(mex_fcn_name, ARGS, argsChar, varargin)
% fcnHandle = create_mex_wrapper(mex_fcn_name, ARGS, argsChar, 'option1', value1, 'option2', value2, ... )
% fcnHandle = create_mex_wrapper(mex_fcn_name, ARGS, argsChar)
% 
%
% --------- Input: ---------
%        - mex_fcn_name: the string of the mex-function
%        - ARGS: Argument Cell for matlab coder (see coder.typeof())
%        - argsChar: Cell of the argument names
% 
%
% ------- Features: --------
%        - Creates a matlab-wrapper function that passes the right 
%          datatypes in the mex function
%
%
% -------- Options: --------
%          'path':     currentPath (default), e.g. "C:/path/to/file/"
%                      path to the mex and wrapper file
%
%          'fcnName':  'functionName_wrapper' (default)
%                      Function name of the wrapper function.
%
%          'arg_suffix': '_in' (default)
%                      All arguments will be remapped in the
%                      wrapper-function. So all arguments need a new name
%                      in the format 'old_name,arg_suffix', 
%                      e.g. with suffix='_in': arg1 -> arg1_in
%
%
% ------- Created by -------
% Institute of Automatic Control, RWTH Aachen
% Christopher Schulte, April 2022
% c.schulte@irt.rwth-aachen.de


%% Options
opts.fcnName = [mex_fcn_name(1:end-4),'_wrapper'];
opts.path = pwd;
opts.arg_suffix = '_in';
opts = checkOptions(opts,varargin);


%% Check Argument Names 
% if argument_name='data.F(idx)' then convert to 'F'
ArgNames = cell(size(argsChar));
for idx = 1:numel(ArgNames)
    str = argsChar{idx};
    idxDot = strfind(str,'.');
    if ~isempty(idxDot)
        str = str(idxDot+1:end);
    end
    idxBracket1 = strfind(str,'(');
    if ~isempty(idxBracket1)
        str = str(1:idxBracket1-1);
    end
    str = strtrim(str);
    if isempty(str)
        str = ['arg',num2str(idx)];
    end
    ArgNames{idx} = str;
end

%% Create Wrapper
fid = fopen(fullfile(opts.path,[opts.fcnName,'.m']), 'wt');

print_header(opts.fcnName,ArgNames,fid)
print_conversion(ARGS,ArgNames,opts,fid)
print_function_call(mex_fcn_name,ArgNames,opts,fid)

fclose(fid);


%% Set Output
fcnHandle = str2func(opts.fcnName);
end


function print_header(name, ArgNames, fid)
argString = strjoin(ArgNames,', ');
fprintf(fid, 'function varargout = %s(%s)\n',name,argString);
fprintf(fid, '%% varargout = %s(%s)\n',name,argString);
fprintf(fid, '%%\n');
fprintf(fid, '%% Automatically created by create_mex_wrapper.m\n');
fprintf(fid, '%% Date: %s\n',datestr(datetime('now'),'dd.mmmm.yyyy HH:MM'));
fprintf(fid, '%%\n');
fprintf(fid, '%% Institute of Automatic Control, RWTH Aachen\n');
fprintf(fid, '%% Christopher Schulte, April 2022\n');
fprintf(fid, '%% c.schulte@irt.rwth-aachen.de\n');

fprintf(fid, '\n');
end

function print_conversion(ARGS, ArgNames, opts, fid)
for idx = 1:length(ArgNames)
    if ~strcmp('struct',ARGS{idx}.ClassName)
        arg_in = [ArgNames{idx},opts.arg_suffix];
        dataType = ARGS{idx}.ClassName;
        if strcmp(dataType,'logical')
            dataType = 'boolean';
        end
        fprintf(fid, '%s = %s(%s);\n',arg_in,dataType,ArgNames{idx});
    else
        structName = ArgNames{idx};
        structName_in = [ArgNames{idx},opts.arg_suffix];
        str = getStructString(ARGS{idx},structName);
        fprintf(fid, '%s = %s;\n',structName_in,str);
    end
end
fprintf(fid, '\n');
end

function print_function_call(mex_fcn_name, ArgNames, opts, fid)
ArgInNames = strcat(ArgNames,opts.arg_suffix);

argString = strjoin(ArgInNames,', ');
fprintf(fid, '[varargout{1:nargout}] = %s(%s);\n',mex_fcn_name,argString);
fprintf(fid, '\n');
end

function str = getStructString(structElement,name)
fields = fieldnames(structElement.Fields);
str_add = cell(numel(fields),1);
for idx = 1:numel(fields) 
    element = structElement.Fields.(fields{idx});
    dataType = element.ClassName;
    if strcmp(dataType,'logical')
        dataType = 'boolean';
    end
    if ~strcmp('struct',dataType)
        str_add{idx} = sprintf('''%s'', %s(%s.%s)',fields{idx},dataType,name,fields{idx});
    else
        name = [name,'.',fields{idx}]; %#ok<AGROW>
        str_temp = getStructString(element,name);
        str_add{idx} = sprintf('''%s'', %s',fields{idx},str_temp);
    end
end
str = sprintf('struct(%s)',strjoin(str_add,', ...\n    '));
end
