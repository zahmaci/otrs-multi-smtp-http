# --
# Kernel/Language/de_MultiSMTPHTTP.pm - the Turkish translation of MultiSMTPHTTP
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::tr_MultiSMTPHTTP;

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

    $Lang->{'Add SMTP/HTTP'}        = 'SMTP/HTTP Ekle';
    $Lang->{'SMTP/HTTP settings'}   = 'SMTP/HTTP Ayarları';
    $Lang->{'Manage SMTP/HTTP settings'} = 'SMTP/HTTP Yöneticisi';
    $Lang->{'Add/Change SMTP/HTTP'}      = 'SMTP/HTTP Ekle/Değiştir';
    $Lang->{'Type is mandatory'}    = 'Type gerekli';
    $Lang->{'A host is required'}   = 'Host gerekli';
    $Lang->{'User is mandatory'}    = 'User gerekli';
    $Lang->{'Port is mandatory'}    = 'Port gerekli';
    $Lang->{'Email is mandatory'}   = 'E-Mail gerekli';
    

    return 1;
}

1;
