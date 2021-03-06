# Compile Matlab Functions to MEX
Compilates Matlab Functions to fast Mex-files that can then be called in Matlab. Should work with every function that has %#codegen and no errors. Feel free to post issues on my github page. Matlab functions with for loops are significantly slower than a c-code call of the same code. 

This repository uses the Matlab Coder Interface to generate c-code that can then be executed in Matlab. Only an example command needs to be passed to the "compile_function.m" function to successfully generate c code and a wrapper function. The wrapper function ensures that the inputs to the generated c-code have the correct form and data type.

[![View Compile_Matlab_Functions_to_MEX on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://de.mathworks.com/matlabcentral/fileexchange/108654-compile_matlab_functions_to_mex)

## compile_function.m
- Command:
  - fcnHandle = compile_function( command )
  - fcnHandle = compile_function( command, 'option1', value1, 'option2', value2, ... )
- Features:
  - Finds the original function-path and checks if the function has changed in comparison with the mex file. If the file has changed, the c code compilation starts. If not, the compilation is skipped
  - Compiles a matlab function to c code 
  - Creates a matlab-wrapper function that passes the right datatypes in the mex function
- Input:
  - 'command': Has to be the string of an example command with the right input arguments of the matlab function. The command must be executable in the base workspace,so all named arguments and the function name have to exist. e.g.: 'fcnName(argument1,argument2,structElement)'
- Options: 
  - 'path': path of the original function (default), e.g. "C:/path/to/file/", Path to the mex and wrapper file
  - 'exactSize': false (default) Should all input arguments have the same size as in the examples command or should all arguments with size [n,1] or [n,n] be unlimited in "n".
  - 'sortStruct': false (default), Should input structs be sorted before compiling? The order of the struct-fields cant be changed afterwards
  - 'dataType': '' (default), e.g. 'single','double', Should all input arguments be mapped to one datatype before compiling? Cant be changed afterwards
  - 'create_wrapper': true (default), Should a wrapper function be created that has the same inputs as the original function (and the mex function) but it converts all inputs to the compiled datatype and changes the order of the structs to the needed order.

## compile_to_mex.m
- Command:
  - fcnHandle = compile_to_mex( command )
  - fcnHandle = compile_to_mex( command , 'option1', value1, ...)
- Features:
  - Compiles a matlab function to c code 
  - Creates a matlab-wrapper function that passes the right datatypes in the mex function
- Input:
  - 'command': Has to be the string of an example command with the right input arguments of the matlab function. The command must be executable in the base workspace,so all named arguments and the function name have to exist. e.g.: 'fcnName(argument1,argument2,structElement)'
- Options: 
  - 'path': currentPath (default), e.g. "C:/path/to/file/", Path to the mex and wrapper file
  - 'type': 'mex' (default), See Matlab Coder for options
  - 'exactSize': false (default) Should all input arguments have the same size as in the examples command or should all arguments with size [n,1] or [n,n] be unlimited in "n".
  - 'sortStruct': false (default), Should input structs be sorted before compiling? The order of the struct-fields cant be changed afterwards
  - 'dataType': '' (default), e.g. 'single','double', Should all input arguments be mapped to one datatype before compiling? Cant be changed afterwards
  - 'create_wrapper': true (default), Should a wrapper function be created that has the same inputs as the original function (and the mex function) but it converts all inputs to the compiled datatype and changes the order of the structs to the needed order.

## create_mex_wrapper.m
- Command:
  - fcnHandle = create_mex_wrapper(mex_fcn_name, ARGS, argsChar)
  - fcnHandle = create_mex_wrapper(mex_fcn_name, ARGS, argsChar, 'option1', value1, 'option2', value2, ... )
- Features:
  - Creates a matlab-wrapper function that passes the right datatypes in the mex function
- Input:
  - mex_fcn_name: the string of the mex-function
  - ARGS: Argument Cell for matlab coder (see coder.typeof())
  - argsChar: Cell of the argument namesworkspace,so all named arguments and the function name have to exist. e.g.: 'fcnName(argument1,argument2,structElement)'
- Options: 
  - 'path': currentPath (default), e.g. "C:/path/to/file/", Path to the mex and wrapper file
  - 'fcnName':  'functionName_wrapper' (default), Function name of the wrapper function.
  - 'arg_suffix': '_in' (default)  All arguments will be remapped in the wrapper-function. So all arguments need a new name in the format 'old_name,arg_suffix', e.g. with suffix='_in': arg1 -> arg1_in
