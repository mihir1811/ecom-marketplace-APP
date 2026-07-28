/// Fixed FX rate used while the catalog runs on mock data. Segments are quoted
/// in different currencies, so shared surfaces (cart, wishlist) need both.
const double usdToInrRate = 96.0;

double usdToInr(double usd) => usd * usdToInrRate;

double inrToUsd(double inr) => inr / usdToInrRate;
