function slm = slmengine_cubic( x, y, knots, yscale, regularization_parameter, verbosity )
%% SETUP
nx = size( x, 1 );
count = size( x, 2 );
nk = size( knots, 1 );
nc = 2 * nk; % two coefs per knot in Hermite Cubic Spline

left_values = y( 1, : );
left_slopes = ( y( 2, : ) - y( 1, : ) ) ./ ( x( 2, : ) - x( 1, : ) );
right_values = y( end, : );
right_slopes = ( y( end - 1, : ) - y( end, : ) ) ./ ( x( end - 1, : ) - x( end, : ) );

%% BUILD DESIGN MATRIX
xbin = nan( nx, count );
for i = 1 : count
    [ ~, ~, xbin( :, i ) ] = histcounts( x, knots( :, i ) );
end
xbin( xbin == nk ) = nk - 1; % dump outside into last bin

% build design matrix
dx = diff( knots );

t = ( x - knots( xbin ) ) ./ dx( xbin );
t2 = t.^2;
t3 = t.^3;
s2 = (1-t).^2;
s3 = (1-t).^3;

vals = [...
    3 * s2 - 2 * s3; ...
    3 * t2 - 2 * t3; ...
    -( s3 - s2 ) .* dx( xbin ); ...
    ( t3 - t2 ) .* dx( xbin ) ...
    ];

% the coefficients will be stored in two blocks,
% first nk function values, then nk derivatives.
bins = [ xbin; xbin + 1; nk + xbin; nk + xbin + 1 ];
inds = [ repmat( ( 1 : nx ).', [ 4 1 ] ) bins ];
Mdes = accumarray( inds, vals, [ nx nc ], [], [], true );
rhs = y;

% -------------------------------------
% Regularizer
% We are integrating the piecewise linear f''(x), as
% a quadratic form in terms of the (unknown) second
% derivatives at the knots.
diags = [ ...
    [ dx; 0 ] ...
    [ dx( 1 ); dx( 1 : end - 1 ) + dx( 2 : end ); dx( end ) ] ...
    [ 0; dx ] ...
    ];
diags = diags ./ [ 6 3 6 ];
Mreg = spdiags2( diags, [ -1 0 1 ], nk, nk );

% do a matrix square root. cholesky is simplest & ok since regmat is
% positive definite. this way we can write the quadratic form as:
%    s'*r'*r*s,
% where s is the vector of second derivatives at the knots.
Mreg = chol( Mreg );

% next, write the second derivatives as a function of the
% function values and first derivatives.   s = [sf,sd]*[f;d]
diags = [ ...
    [ dx; -dx( end ) ] ...
    [ 0; dx ] ...
    ];
diags = diags .^ 2;
diags = [ diags; -diags( end, : ) ];
diags = [ -6 6 ] ./ diags;
sf = spdiags2( diags, [ 0 1 ], nk, nk );
sf( nk, nk-1 ) = 6 ./ ( dx( end ) .^ 2 );

diags = [ ...
    [ dx; -dx( end ) ] ...
    [ 0; dx ] ...
    ];
diags = [ diags; -diags( end, : ) ];
diags = [ -4 -2 ] ./ diags;
sd = spdiags2( diags, [ 0 1 ], nk, nk );
sd( nk, nk-1 ) = 2 ./ ( dx( end ) );

Mreg = Mreg * [ sf sd ];

% scale the regularizer before we apply the
% regularization parameter.
Mreg = Mreg / norm( Mreg, 1 );
rhsreg = zeros( nk, 1 );

% -------------------------------------
% C2 continuity across knots
diags = [ ...
    6 ./ dx( 1 : end - 1 ) .^ 2 ...
    -6 ./ dx( 1 : end - 1 ) .^ 2 + 6 ./ dx( 2 : end ) .^ 2 ...
    -6 ./ dx( 2 : end ) .^ 2 ...
    ];
diags2 = [ ...
    2 ./ dx( 1 : end - 1 ) ...
    4 ./ dx( 1 : end - 1 ) + 4 ./ dx( 2 : end ) ...
    2 ./ dx( 2 : end ) ...
    ];
m_eq = spdiags2( [ diags diags2 ], [ 0 1 2 nk nk+1 nk+2 ], nk-2, nc );
rhs_eq = zeros( nk - 2, 1 );

% -------------------------------------
% single point equality constraints at a knot
% left hand side
M = zeros( 1, nc );
M( 1, 1 ) = 1;
m_eq = [ m_eq; M ];
rhs_eq = [ rhs_eq; left_values ];

% right hand side
M = zeros( 1, nc );
M( 1, nk ) = 1;
m_eq = [ m_eq; M ];
rhs_eq = [ rhs_eq; right_values ];

% left end slope
M = zeros(1,nc);
M(1,nk+1) = 1;
m_eq = [m_eq;M];
rhs_eq = [rhs_eq;left_slopes];

% Right end slope
M = zeros(1,nc);
M(1,2*nk) = 1;
m_eq = [m_eq;M];
rhs_eq = [rhs_eq;right_slopes];

% -------------------------------------
% force curve through an x-y pair or pairs
% xy = prescription.XY;
% if ~isempty(xy)
%     n = size(xy,1);
%     if any(xy(:,1)<knots(1)) || any(xy(:,1)>knots(end))
%         error('SLMENGINE:improperconstraint','XY pairs to force the curve through must lie inside the knots')
%     end
%
%     [junk,ind] = histc(xy(:,1),knots); %#ok
%     ind(ind==(nk))=nk-1;
%
%     t = (xy(:,1) - knots(ind))./dx(ind);
%     t2 = t.^2;
%     t3 = t.^3;
%     s2 = (1-t).^2;
%     s3 = (1-t).^3;
%
%     vals = [3*s2-2*s3 ; 3*t2-2*t3 ; ...
%         -(s3-s2).*dx(ind) ; (t3-t2).*dx(ind)];
%
%     M = accumarray([repmat((1:n)',4,1), ...
%         [ind;ind+1;nk+ind;nk+ind+1]],vals,[n,nc]);
%
%     m_eq = [m_eq;M];
%     rhs_eq = [rhs_eq;xy(:,2)];
% end

% -------------------------------------
% monotonicity?
% increasing regions
totalmonotoneintervals = 0;
L=0;

% decreasing regions
L=L+1;
mono(L).knotlist = [1,nk];
mono(L).direction = -1;
totalmonotoneintervals = totalmonotoneintervals + nk - 1;

min_eq = zeros( 0, nc );
rhs_ineq = [];
if L>0
    % there were at least some monotone regions specified
    M = zeros(7*totalmonotoneintervals,nc);
    n = 0;
    for i=1:L
        for j = mono(i).knotlist(1):(mono(i).knotlist(2) - 1)
            % the function must be monotone between
            % knots j and j + 1. The direction over
            % that interval is specified. The constraint
            % system used comes from Fritsch & Carlson, see here:
            %
            % http://en.wikipedia.org/wiki/Monotone_cubic_interpolation
            %
            % Define delta = (y(i+1) - y(i))/(x(i+1) - x(i))
            % Thus delta is the secant slope of the curve across
            % a knot interval. Further, define alpha and beta as
            % the ratio of the derivative at each end of an
            % interval to the secant slope.
            %
            %  alpha = d(i)/delta
            %  beta = d(i+1)/delta
            %
            % Then we have an elliptically bounded region in the
            % first quadrant that defines the set of monotone cubic
            % segments. We cannot define that elliptical region
            % using a set of linear constraints. However, by use
            % of a system of 7 linear constraints, we can form a
            % set of sufficient conditions such that the curve
            % will be monotone. There will be some few cubic
            % segments that are actually monotone, yet lie outside
            % of the linear system formed. This is acceptable,
            % as our linear approximation here is a sufficient
            % one for monotonicity, although not a necessary one.
            % It merely says that the spline may be slightly over
            % constrained, i.e., slightly less flexible than is
            % absolutely necessary. (So?)
            %
            % The 7 constraints applied for an increasing function
            % are (in a form that lsqlin will like):
            %
            %    -delta          <= 0
            %    -alpha          <= 0
            %    -beta           <= 0
            %    -alpha + beta   <= 3
            %     alpha - beta   <= 3
            %     alpha + 2*beta <= 9
            %   2*alpha + beta   <= 9
            %
            % Multiply these inequalities by (y(i+1) - y(i)) to
            % put them into a linear form.
            M(n + 1,j+[0 1]) = [1 -1]*mono(i).direction;
            M(n + 2,nk + j) = -mono(i).direction;
            M(n + 3,nk + j + 1) = -mono(i).direction;
            
            M(n + 4,j + [0, 1, nk,nk + 1]) = mono(i).direction*[3, -3, [-1, 1]*dx(j)];
            M(n + 5,j + [0, 1, nk,nk + 1]) = mono(i).direction*[3, -3, [1, -1]*dx(j)];
            M(n + 6,j + [0, 1, nk,nk + 1]) = mono(i).direction*[9, -9, [1, 2]*dx(j)];
            M(n + 7,j + [0, 1, nk,nk + 1]) = mono(i).direction*[9, -9, [2, 1]*dx(j)];
            
            n = n + 7;
        end
    end
    
    min_eq = [min_eq;M];
    rhs_ineq = [rhs_ineq;zeros(size(M,1),1)];
end

% -------------------------------------
% scale equalities for unit absolute row sum
if ~isempty( m_eq )
    rs = spdiags2( 1 ./ sum( abs( m_eq ), 2 ), 1, size( m_eq, 1 ), size( m_eq, 1 ) );
    m_eq = rs * m_eq;
    rhs_eq = rs * rhs_eq;
end
% scale inequalities for unit absolute row sum
if ~isempty( min_eq )
    rs = spdiags2( 1 ./ sum( abs( min_eq ), 2 ), 1, size( min_eq, 1 ), size( min_eq, 1 ) );
    min_eq = rs * min_eq;
    rhs_ineq = rs * rhs_ineq;
end

% solve
[ coef, ~ ] = solve_slm_system( ...
    regularization_parameter, ...
    Mdes, rhs, ...
    Mreg, rhsreg, ...
    m_eq, rhs_eq, ...
    min_eq, rhs_ineq, ...
    verbosity ...
    );

% -------------------------------------
% unpack coefficients into the result structure
slm.form = 'slm';
slm.degree = 3;
slm.knots = knots;
slm.coef = reshape(coef,nk,2);

% generate model statistics
slmstats.TotalDoF = 2*nk;
slmstats.NetDoF = slmstats.TotalDoF - size(m_eq,1);
% this function does all of the stats, stuffing into slmstats
slm.stats = modelstatistics(slmstats,y,coef,yscale,Mdes);

slm.stats.finalRP = regularization_parameter;

end


function slmstats = modelstatistics(slmstats,y,coef,yscale,Mdes)

% generate model statistics, stuffing them into slmstats

% residuals, as yhat - y
resids = (Mdes*coef - y)./yscale;

% RMSE: Root Mean Squared Error
slmstats.RMSE = sqrt(mean(resids.^2))./yscale;

% R-squared
slmstats.R2 = 1 - sum(resids.^2)./sum(((y - mean(y))./yscale).^2);

% adjusted R^2
ndata = numel(y);
slmstats.R2Adj = 1 - (1-slmstats.R2)*(ndata - 1)./(ndata - slmstats.NetDoF);

% range of the errors, min to max, as yhat - y
slmstats.ErrorRange = [min(resids),max(resids)];

% compute the 25% and 75% points (quartiles) of the residuals
% (This is consistent with prctile, from the stats TB.)
resids = sort(resids.');
ind = 0.5 + ndata*[0.25 0.75];
f = ind - floor(ind);
ind = min(ndata - 1,max(1,floor(ind)));
slmstats.Quartiles = resids(ind).*(1-f) + resids(ind+1).*f;

end


