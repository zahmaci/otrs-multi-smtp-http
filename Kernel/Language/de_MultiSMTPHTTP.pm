# --
# Kernel/Language/de_MultiSMTPHTTP.pm - the german translation of MultiSMTPHTTP
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_MultiSMTPHTTP;

use strict;
use warnings;

use utf8;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.3 $) [1];

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{Creator} = 'Ersteller';

    $Lang->{'Add SMTP/HTTP'}             = 'SMTP/HTTP hinzufügen';
    $Lang->{'SMTP/HTTP settings'}        = 'SMTP/HTTP-Einstellungen';
    $Lang->{'Manage SMTP/HTTP settings'} = 'SMTP/HTTP-Einstellungen verwalten';
    $Lang->{'Add/Change SMTP/HTTP'}      = 'SMTP/HTTP hinzufügen/bearbeiten';
    $Lang->{'Type is mandatory'}    = 'Typ wird benötigt';
    $Lang->{'A host is required'}   = 'Ein Hostname wird benötigt';
    $Lang->{'User is mandatory'}    = 'Ein Benutzername wird benötigt';
    $Lang->{'Port is mandatory'}    = 'Eine Port-Angabe wird benötigt';
    $Lang->{'Email is mandatory'}   = 'E-Mail-Adressen werden benötigt';
    

    return 1;
}

1;
