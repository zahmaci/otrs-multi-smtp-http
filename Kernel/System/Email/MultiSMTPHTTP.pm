# --
# Kernel/System/Email/MultiSMTPHTTP.pm - the global email send module
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSMTPHTTP;

use strict;
use warnings;

use Kernel::System::EmailParser;
use Kernel::System::MultiSMTPHTTP;
use Kernel::System::Email::SMTP;
use Kernel::System::Email::SMTPS;
use Kernel::System::Email::SMTPTLS;

use Kernel::System::Email::MultiSMTPHTTP::SMTP;
use Kernel::System::Email::MultiSMTPHTTP::SMTPS;
use Kernel::System::Email::MultiSMTPHTTP::SMTPTLS;
use Kernel::System::Email::MultiSMTPHTTP::MAILGUN;
use Kernel::System::Email::MultiSMTPHTTP::POSTMARK;
use Kernel::System::Email::MultiSMTPHTTP::SENDGRID;
use Kernel::System::Email::MultiSMTPHTTP::TURBOSMTP;
use Kernel::System::Email::MultiSMTPHTTP::GENERALHTTP;





sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for my $Needed (qw(ConfigObject LogObject EncodeObject MainObject DBObject TimeObject)) {
        die "Got no $Needed" if ( !$Self->{$Needed} );
    }

    # create needed object
    $Self->{MSMTPObject}  = Kernel::System::MultiSMTPHTTP->new( %Param );
    $Self->{ParserObject} = Kernel::System::EmailParser->new(
        %{$Self},
        Mode  => 'Standalone',
        Debug => 0,
    );

    $Self->{Debug} = $Self->{ConfigObject}->Get( 'MultiSMTPHTTP::Debug' );

    return $Self;
}

sub Check {
    return (Successful => 1, MultiSMTPHTTP => shift ); 
}

sub Send {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Header Body ToArray)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    # try to parse the sender address from header
    if ( !$Param{From} ) {
        ($Param{From}) = ${ $Param{Header} } =~ m{^ From: \s+ ([^\n]+) }xms;
    }

    my $SMTPObject;
    if ( !$Param{From} ) {
        # use standard SMTP module as fallback
        my $Module  = $Self->{ConfigObject}->Get('MultiSMTPHTTP::Fallback');
        $SMTPObject = $Module->new( %{$Self} );
        my $Success = $SMTPObject->Send( %Param );
        return $Success;
    }

    my $PlainFrom = $Self->{ParserObject}->GetEmailAddress(
        Email => $Param{From},
    );


    my %SMTP = $Self->{MSMTPObject}->SMTPGetForAddress(
        Address => $PlainFrom,
    );

    if ( $Self->{Debug} ) {
        $Self->{LogObject}->Log(
            Priority => 'notice',
            Message  => 'From: ' . $PlainFrom . ' // SMTP: ' . $SMTP{ID},
        );
    }

    if ( !%SMTP ) {
		if ( $Self->{Debug} ) {
			$Self->{LogObject}->Log(
				Priority => 'notice',
				Message  => 'Cannot find SMTP object, fallback here: ',
			);
		}

        # use standard SMTP module as fallback
        my $Module  = $Self->{ConfigObject}->Get('MultiSMTPHTTP::Fallback');
        $SMTPObject = $Module->new( %{$Self} );
        my $Success = $SMTPObject->Send( %Param );
        return $Success;
    }

    $SMTP{Password} = $SMTP{PasswordDecrypted};
    $SMTP{Type} =~ s/\W//g;

    my $Module  = 'Kernel::System::Email::MultiSMTPHTTP::' . $SMTP{Type};
    $SMTPObject = $Module->new( %{$Self}, %SMTP );

    if ( $Self->{Debug} ) {
        $Self->{LogObject}->Log(
            Priority => 'notice',
            Message  => "Use MultiSMTPHTTP $Module",
        );

        $Self->{LogObject}->Log(
            Priority => 'notice',
            Message  => sprintf "Use SMTP %s/%s (%s)", $SMTP{Host}, $SMTP{User}, $SMTP{ID},
        );
    }

    return if !$SMTPObject;
    
    my $Success = $SMTPObject->Send( %Param );

    return $Success;
}

1;
