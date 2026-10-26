/// Stat-card / tab counts for the customer management list, computed in one
/// SQL aggregate instead of loading every customer (Issues.md #43).
typedef CustomerListStats = ({
  int all,
  int businesses,
  int individuals,
  int taxRegistered,
});
