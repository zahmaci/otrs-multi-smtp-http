# --
# Kernel/Modules/AdminMultiSMTPHTTP.pm - provides admin smtp/http configurations
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --



package Kernel::Modules::AdminMultiSMTPHTTP;

use strict;
use warnings;

use Kernel::System::MultiSMTPHTTP;
use Kernel::System::HTMLUtils;
use Kernel::System::Valid;
use Kernel::System::SystemAddress;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1.1.1 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for my $Needed (qw(ParamObject DBObject LayoutObject ConfigObject LogObject EncodeObject)) {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    # create needed objects
    $Self->{SMTPHTTPObject}  = Kernel::System::MultiSMTPHTTP->new(%Param);
    $Self->{ValidObject}     = Kernel::System::Valid->new(%Param);
    $Self->{HTMLUtilsObject} = Kernel::System::HTMLUtils->new(%Param);
    $Self->{AddressObject}   = Kernel::System::SystemAddress->new(%Param);

	$Self->{AvaibleTypes}	 = {
									'' => '', 
									'SMTP' => 'Regular SMTP',
									'SMTPS' => 'Regular SMTP/S',
									'SMTPTLS' => 'Regular SMTPTLS',
									'MAILGUN' => 'Mailgun Http Api',
									'SENDGRID' => 'Sendgrid Http Api',
									'TURBOSMTP'=> 'TurboSmtp Http Api',
									'GENERALHTTP'=> 'General Http Post'

								};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my @Params = (qw(ID Host User PasswordDecrypted Type ValidID UserID Port Comments Anonymous Vendor));
    my %GetParam;
    for my $Needed (@Params) {
        $GetParam{$Needed} = $Self->{ParamObject}->GetParam( Param => $Needed ) || '';
    }

    if ( $GetParam{Anonymous} ) {
        $GetParam{User}              = '';
        $GetParam{PasswordDecrypted} = '';
    }

    my @Mails = $Self->{ParamObject}->GetArray( Param => 'Emails' );
    $GetParam{Emails} = \@Mails if @Mails;

    # ------------------------------------------------------------ #
    # get data 2 form
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Edit' || $Self->{Subaction} eq 'Add' ) {
        my %Subaction = (
            Edit => 'Update',
            Add  => 'Save',
        );

        my $Output       = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_SMTPHTTPForm(
            %GetParam,
            %Param,
            Subaction => $Subaction{ $Self->{Subaction} },
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();
 
        # server side validation
        my %Errors;
        if (
            !$GetParam{ValidID} ||
            !$Self->{ValidObject}->ValidLookup( ValidID => $GetParam{ValidID} )
            )
        {
            $Errors{ValidIDInvalid} = 'ServerError';
        }

        PARAM:
        for my $Param (qw(ID Host User PasswordDecrypted Type ValidID Port)) {

            next PARAM if $GetParam{Anonymous} and ( $Param eq 'PasswordDecrypted' || $Param eq 'User' );

            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( !$GetParam{Emails} || !@{ $GetParam{Emails} } ) {
              $Errors{EmailsInvalid} = 'ServerError';
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Edit';

            my $Output = $Self->{LayoutObject}->Header();
            $Output .= $Self->{LayoutObject}->NavigationBar();
            $Output .= $Self->_SMTPHTTPForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Update',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }

        my $Update = $Self->{SMTPHTTPObject}->SMTPUpdate(
            %GetParam,
            Password => $GetParam{PasswordDecrypted},
            UserID   => $Self->{UserID},
        );

        if ( !$Update ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminMultiSMTPHTTP" );
    }

    # ------------------------------------------------------------ #
    # insert smtp settings
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Save' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        # server side validation
        my %Errors;
        if (
            !$GetParam{ValidID} ||
            !$Self->{ValidObject}->ValidLookup( ValidID => $GetParam{ValidID} )
            )
        {
            $Errors{ValidIDInvalid} = 'ServerError';
        }

        PARAM:
        for my $Param (qw(ValidID User PasswordDecrypted Host Type Port)) {

            next PARAM if $GetParam{Anonymous} and ( $Param eq 'PasswordDecrypted' || $Param eq 'User' );

            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( !$GetParam{Emails} || !@{ $GetParam{Emails} } ) {
              $Errors{EmailsInvalid} = 'ServerError';
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Add';

            my $Output = $Self->{LayoutObject}->Header();
            $Output .= $Self->{LayoutObject}->NavigationBar();
            $Output .= $Self->_SMTPHTTPForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Save',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }

        my $Success = $Self->{SMTPHTTPObject}->SMTPAdd(
            %GetParam,
            Password => $GetParam{PasswordDecrypted},
            UserID   => $Self->{UserID},
        );

        if ( !$Success ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminMultiSMTPHTTP" );
    }

    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $Self->{SMTPHTTPObject}->SMTPDelete( %GetParam );
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminMultiSMTPHTTP" );
    }

    # ------------------------------------------------------------ #
    # else ! print form
    # ------------------------------------------------------------ #
    else {
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_SMTPHTTPForm();
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

sub _SMTPHTTPForm {
    my ( $Self, %Param ) = @_;

    my %SMTP;
    if ( $Self->{Subaction} eq 'Edit' ) {
        %SMTP = $Self->{SMTPHTTPObject}->SMTPGet( ID => $Param{ID} );

        for my $Key ( keys %SMTP ) {
            $Param{$Key} = $SMTP{$Key} if !$Param{$Key};
        }

        if ( !$Param{User} && !$Param{PasswordDecrypted} ) {
            $Param{AnonymousChecked} = 'checked="checked"';
            $Param{JavascriptCall}    = 'anonymous();';
        }

		if($Param{Type} eq 'MAILGUN' || $Param{Type} eq 'TURBOSMTP' || $Param{Type} eq 'SENDGRID' || $Param{Type} eq 'GENERALHTTP'){
			$Param{JavascriptCall}    = '_4YS_'.lc($Param{Type}).'();';
		}



    }

    $Param{Port} ||= 25;

    my %SMTPAddresses;
    my @Selected = @{ $Param{Emails} || [] } ? @{ $Param{Emails} } : @{ $SMTP{Emails} || [] };
    $SMTPAddresses{$_} = 1 for @Selected;

    my %SystemAddresses = $Self->{SMTPHTTPObject}->SystemAddressList(
        %SMTPAddresses,
    );

    # add AdminEmail
    # add NotificationSenderEmail
    # add PostMaster::PreFilterModule::NewTicketReject::Sender
    CONFIGKEY:
    for my $ConfigKey ( qw/AdminEmail NotificationSenderEmail PostMaster::PreFilterModule::NewTicketReject::Sender/ ) {
        my $Mail = $Self->{ConfigObject}->Get( $ConfigKey );

        next CONFIGKEY if !$Mail;
        next CONFIGKEY if $SystemAddresses{$Mail};

        $SystemAddresses{$Mail} = $Mail . ' (' . $ConfigKey . ')';
    }
    
    $Param{EmailsSelect} = $Self->{LayoutObject}->BuildSelection(
        Data        => \%SystemAddresses,
        Name        => 'Emails',
        Size        => 5,
        Class       => 'Validate_Required ' . ( $Param{EmailsInvalid} || '' ),
        Multiple    => 1,
        SelectedID  => \@Selected,
        HTMLQuote   => 1,
    );


    $Param{TypeSelect} = $Self->{LayoutObject}->BuildSelection(
        Data       => $Self->{AvaibleTypes},
        Name       => 'Type',
        Size       => 1,
        Class       => 'Validate_Required',
        SelectedID => $Param{Type} || $SMTP{Type},
        HTMLQuote  => 1,
    );


    my $ValidID = $Self->{ValidObject}->ValidLookup( Valid => 'valid' );

    $Param{ValidSelect} = $Self->{LayoutObject}->BuildSelection(
        Data       => { $Self->{ValidObject}->ValidList() },
        Name       => 'ValidID',
        Size       => 1,
        SelectedID => $Param{ValidID} || $ValidID || 1,
        HTMLQuote  => 1,
    );

    if ( $Self->{Subaction} ne 'Edit' && $Self->{Subaction} ne 'Add' ) {

        my %SMTPList = $Self->{SMTPHTTPObject}->SMTPList();
  
        if ( !%SMTPList ) {
            $Self->{LayoutObject}->Block(
                Name => 'NoSMTPFound',
            );
        }

        for my $ID ( sort keys %SMTPList ) {
            my %SMTP = $Self->{SMTPHTTPObject}->SMTPGet(
                ID => $ID,
            );

            $SMTP{EmailString} = join ', ', @{ $SMTP{Emails} || [] };

            $Self->{LayoutObject}->Block(
                Name => 'SMTPRow',
                Data => \%SMTP,
            );
        }
    }

    $Param{SubactionName} = 'Update';
    $Param{SubactionName} = 'Save' if $Self->{Subaction} && $Self->{Subaction} eq 'Add';

    my $TemplateFile = 'AdminMultiSMTPHTTPList';
    $TemplateFile = 'AdminMultiSMTPHTTPForm' if $Self->{Subaction};

    return $Self->{LayoutObject}->Output(
        TemplateFile => $TemplateFile,
        Data         => { %Param },
    );
}

1;
