/// Stat-card / tab counts for the product management list, computed in one
/// SQL aggregate instead of loading every product (Issues.md #42).
typedef ProductListStats = ({
  int all,
  int products,
  int services,
  int lowStock,
  int outOfStock,
  int expired,
});
