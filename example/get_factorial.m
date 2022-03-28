function [ factorial ] = get_factorial( n , struc )
%GET_FACTORIAL calculates the factorial

factorial = struc.startValue;
for idx = 1:n
    factorial = factorial * idx;
end

end

