# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;

BEGIN {
  *CORE::GLOBAL::sleep = sub {};
}

use Test::More tests => 4;
use Test::NoWarnings;
use Test::Quattor;
use CAF::RuleBasedEditor qw(:rule_constants);
use NCM::Component::xrootd;
use Readonly;
use CAF::Object;
Test::NoWarnings::clear_warnings();


=pod

=head1 SYNOPSIS

Basic test for local redirector configuration

=cut

use constant REDIR_CONF_FILE => "/etc/xrootd/local-redir.cfg";

use constant REDIR_INITIAL_CONF => '#>>>>>>>>>>>>> Variable declarations

# Installation specific
set xrdlibdir = $XRDLIBDIR
set dpmhost = grid05.lal.in2p3.fr
# set xrootfedlport1 = $XROOT_FED_LOCAL_PORT_ATLAS
# set xrootfedlport2...
setenv DPNS_HOST = grid05.lal.in2p3.fr
setenv DPM_HOST = grid05.lal.in2p3.fr
';

use constant REDIR_EXPECTED_CONF_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#>>>>>>>>>>>>> Variable declarations

# Installation specific
set xrdlibdir = $XRDLIBDIR
#set dpmhost = grid05.lal.in2p3.fr
# set xrootfedlport1 = $XROOT_FED_LOCAL_PORT_ATLAS
# set xrootfedlport2...
setenv DPNS_HOST = grid05.lal.in2p3.fr
#setenv DPM_HOST = grid05.lal.in2p3.fr
';

my %config_rules = (
      "-dpmhost" => "dpmHost:dpm;".LINE_FORMAT_KW_VAL_SET.";:".LINE_OPT_SEP_EQUAL,
      "-DPM_HOST" => "dpmHost:dpm;".LINE_FORMAT_KW_VAL_SETENV.";:".LINE_OPT_SEP_EQUAL,
     );


#############
# Main code #
#############

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $comp = NCM::Component::xrootd->new('xrootd');

my $xrootd_options = {};

set_file_contents(REDIR_CONF_FILE,REDIR_INITIAL_CONF);
my $changes = $comp->updateConfigFile(REDIR_CONF_FILE,
                                   \%config_rules,
                                   $xrootd_options);
my $fh = get_file(REDIR_CONF_FILE);
ok(defined($fh), REDIR_CONF_FILE." was opened");
is("$fh", REDIR_EXPECTED_CONF_1, REDIR_CONF_FILE." (initial ok) has expected contents");
$fh->close();


Test::NoWarnings::had_no_warnings();

