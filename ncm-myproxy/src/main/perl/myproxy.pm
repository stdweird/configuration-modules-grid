# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
#

package NCM::Component::myproxy;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element;

use File::Copy;
use File::Path;

local(*DTA);


##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/myproxy";

    # Retrive component configuration
    my $myproxy_config = $config->getElement($base)->getTree();

    # Save the date
    my $date = localtime();

    # Ensure MyProxy flavor is defined. Assume 'edg' by default
    # for backward compatibility.
    unless ( $myproxy_config->{flavor} ) {
      $myproxy_config->{flavor} = 'edg';
    }
    
    # Loop over all of the trusted DNs.
    my $new_config;
    for my $subject (@{$myproxy_config->{trustedDNs}}) {
      if ( $myproxy_config->{flavor} eq 'glite' ) {
        $new_config .= "authorized_renewers $subject"
        
      } else {
        $new_config .= "$subject\n";        
      }
    }

    # Retrieve MyProxy configuration file path
    my $fname;
    if ( $myproxy_config->{trustedDNsFile} ) {
      $fname = $myproxy_config->{trustedDNsFile};
    } else {
      $fname = '/opt/edg/etc/edg-myproxy.conf'
    }

    # Read old file to do a comparaison ignoring comments.
    # If an error occurs, try to continue as the file should be overwritten or
    # another error happen.
    my $old_config = '';
    if ( -f $fname ) {
      my $status = open(CONFFILE,"<$fname");
      if ( $status ) {
        $self->warn("Failed to open existing configuration file. Trying to continue...")
      } else {
        my @old_config = grep (!/^#/,<CONFFILE>);
        $old_config = join "", @old_config;
        close CONFFILE;
      }
    }
    
    my $changes = 0;
    if ( $new_config ne $old_config ) {
      $new_config = "#\n# File generated by ncm-myproxy on $date\n#\n" . $new_config;
      $changes = LC::Check::file($fname,
                                 backup => ".old",
                                 contents => $new_config,
                                );
      if ( $changes < 0 ) {
        $self->error("Error updating MyProxy server configuration file ($fname)")
      }      
    }

    # Reload MyProxy daemon if running, else restart it.
    # Always restart if flavor is edg.
    if ( system('/sbin/service myproxy status >/dev/null 2>&1') ||
         (($myproxy_config->{flavor} eq 'edg') || ($changes > 0)) ) {
      $self->info("Restarting MyProxy server...");
      if ( system('/sbin/service myproxy restart') ) {
        $self->error("MyProxy server restart failed"); 
      }
    } elsif ( $changes > 0 ) {
      $self->info("Reloading MyProxy server...");
      if ( system('/sbin/service myproxy reload') ) {
        $self->error("MyProxy server reload failed"); 
      }      
    }

    return 1;
}

1;      # Required for PERL modules
