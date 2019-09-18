function slmstats = modelstatistics(slmstats,y,coef,YScale,Mdes)

% generate model statistics, stuffing them into slmstats

% residuals, as yhat - y
resids = (Mdes*coef - y)./YScale;

% RMSE: Root Mean Squared Error
slmstats.RMSE = sqrt(mean(resids.^2))./YScale;

% R-squared
slmstats.R2 = 1 - sum(resids.^2)./sum(((y - mean(y))./YScale).^2);

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

