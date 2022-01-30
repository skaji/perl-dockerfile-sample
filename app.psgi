use 5.34.0;
use warnings;
use experimental 'signatures';

use App;

App->new->to_psgi;
