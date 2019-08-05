function mustBeBetween( A, lower, upper )

if ~all( lower < A & A < upper, 'all' )
    throw(createValidatorException('MATLAB:validators:mustBeBetween'));
end

end

