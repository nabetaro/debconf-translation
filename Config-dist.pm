# This package holds configuration values for debconf.
# This is the version used after install.
package Debian::DebConf::Config;

# Where to store the database.
$dbfn="/var/lib/debconf/debconf.db";

# The frontend to use by default.
$frontend='Dialog';

# The lowest priority of questions you want to see. Valid priorities
# are "low", "medium", "high", and "critical".
$priority='low';

1
