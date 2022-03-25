function fcnHandle = compile_function(command,varargin)
% fcnHandle = compile_function( command, 'option1', value1, 'option2', value2, ... )
% fcnHandle = compile_function( command )
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
%       - Finds the original function-path and checks if the function has 
%         changed in comparison with the mex file. If the file has changed, 
%         the c code compilation starts. If not, the compilation is skipped
%       - Compiles a matlab function to c code 
%       - Creates a matlab-wrapper function that passes the right datatypes
%         in the mex function
%
%
% -------- Options: --------
%          'path': path of the original function (default)
%                      can be changed to e.g. "C:/path/to/file/"
%                      path to the mex and wrapper file
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
%
%
% ------- Created by -------
% Institute of Automatic Control, RWTH Aachen
% Christopher Schulte, April 2022
% c.schulte@irt.rwth-aachen.de


%% Get Options
opts.exactSize = false;
opts.sortStruct = false;
opts.dataType = '';
opts.create_wrapper = true;
opts.path = '';
opts = checkOptions(opts,varargin);


%% Get Function name
list_bracket1 = strfind(command,'(');
list_equal = strfind(command,'=');
if isempty(list_equal)
    list_equal = 1;
end
fcnName = command(list_equal:list_bracket1(1)-1);


%% Get Path to mex file
filepath = which(fcnName);
if isempty(opts.path) % find the path to the mex file (same folder as orig function)
    if isempty(strfind(filepath,'\'))
        delimiter = '/';
    else
        delimiter = '\';
    end
    pathparts = strsplit(filepath,delimiter);
    fullpath = strjoin(pathparts(1:end-1),delimiter);
    opts.path = fullpath;
else
    fullpath = opts.path;
end


%% Check if File is updated
mexfileName = [fcnName,'_mex.',mexext];
mexfilePath = fullfile(fullpath,mexfileName);
fcnUpdated = fileIsNewer(filepath,mexfilePath);


%% compile to c code if necessary
if fcnUpdated
    fcnHandle = compile_to_mex(command, opts);
else
    fcnHandle = str2func([fcnName,'_wrapper']);
end
end


%% Other functions
% Check if File is newer
function hasChanged = fileIsNewer(orig_file, compilated_file)
file1 = dir(orig_file);
if ~isempty(file1)
    date1 = datetime(file1.datenum,'ConvertFrom','datenum');
else
    date1 = datetime('now');
end

file2 = dir(compilated_file);
if ~isempty(file2)
    date2 = datetime(file2.datenum,'ConvertFrom','datenum');
else
    date2 = datetime(1970,1,1);
end

hasChanged = date2 < date1;
end