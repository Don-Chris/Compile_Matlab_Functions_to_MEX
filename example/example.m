%% Compile
n = 100000000;
struc = struct('startValue',1);
compile_function('get_factorial(n,struc)','exactSize',true)

%% Test
tic 
factorial1 = get_factorial(n,struc);
time_orig = toc;

tic 
factorial2 = get_factorial_wrapper(n,struc);
time = toc;

fprintf('- Original Time: %0.5f sec\n',time_orig)
fprintf('- Wrapper Time:  %0.5f sec\n',time)
fprintf('- Speedup:       %0.5f x\n',time_orig/time)
