function [coef,lambda] = solve_slm_system(RP,Mdes,rhs,Mreg,rhsreg,Meq,rhseq,Mineq,rhsineq,verbosity)
% solves the final linear system of equations for the model coefficients

if verbosity > 1
    % Linear solve parameters
    disp('=========================================')
    disp('LINEAR SYSTEM SOLVER')
    disp(['Design matrix shape:    ',num2str(size(Mdes))])
    disp(['Regularizer shape:      ',num2str(size(Mreg))])
    disp(['Equality constraints:   ',num2str(size(Meq))])
    disp(['Inequality constraints: ',num2str(size(Mineq))])
    disp(' ')
    disp(['Condition number of the regression: ',num2str(cond(Mdes))])
    disp(' ')
end

Mfit = [Mdes;RP*Mreg];
rhsfit = [rhs;RP*rhsreg];

if isempty(Mineq) && isempty(Meq)
    % backslash will suffice
    coef = Mfit\rhsfit;
    lambda.eqlin=[];
    lambda.ineqlin=[];
    
    solver = 'backslash';
    
elseif isempty(Mineq)
    % with no inequality constraints, lse is faster than
    % is lsqlin. This also allows the use of slm when
    % the optimization toolbox is not present if there
    % are no inequality constraints.
    coef = lse(Mfit,rhsfit,full(Meq),rhseq);
    lambda.eqlin=[];
    lambda.ineqlin=[];
    
    solver = 'lse';
    
else
    % use lsqlin. first, set the options
    options = optimset('lsqlin');
    if verbosity > 1
        options.Display = 'final';
    else
        options.Display = 'off';
    end
    % the Largescale solver will not allow general constraints,
    % either equality or inequality
    options.LargeScale = 'off';
    %options.Algorithm = prescription.LsqlinAlgorithm;
    options.Algorithm = 'interior-point';
    
    % and solve
    [coef,junk,junk,exitflag,junk,lambda] = ...
        lsqlin(Mfit,rhsfit,Mineq,rhsineq,Meq,rhseq,[],[],[],options); %#ok
    
    % was there a feasible solution?
    if exitflag == -2
        warning('No feasible solution was found by LSQLIN. This may reflect an inconsistent prescription set.')
        coef = nan(size(Mfit,2),1);
    end
    
    solver = 'lsqlin';
    
end

if verbosity > 0
    disp('=========================================')
    disp(['Solver chosen as:     ',solver])
    disp('=========================================')
end


end

