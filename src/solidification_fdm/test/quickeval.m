function y = quickeval(x,knots,coefs1,coefs2)

%[~,~,xbin] = histcounts(x,knots);

% x is a matrix
%  - rows are time steps
%  - cols are elements in mesh

% knots is a matrix
%  - rows are time steps
%  - cols are elements in mesh

% coefs is a matrix
%  - rows are time steps
%  - cols are elements in mesh

x = x(:);

count = size( knots, 2 );
xbin = nan( numel( x ), count );
for i = 1 : count
    [~,~,xbin(:,i)] = histcounts(x,knots(:,i));
end

dx = diff(knots);

xbin( xbin == 0 ) = 1;
xx = xbin + ( 1 : size(knots,1) : numel(knots) ) - 1;
dxx = xbin + ( 1 : size(dx,1) : numel(dx) ) - 1;

t = (x-knots(xx))./dx(dxx);
t2 = t.^2;
t3 = t.^3;
s2 = (1-t).^2;
s3 = (1-t).^3;

c2 = coefs2(xx);
c21 = coefs2(xx+1);
c1 = coefs1(xx);
c11 = coefs1(xx+1);

y = (-c2.*(s3-s2) + ...
    c21.*(t3-t2)).*dx(dxx) + ...
    c1.*(3*s2-2*s3) + ...
    c11.*(3*t2-2*t3);

end

