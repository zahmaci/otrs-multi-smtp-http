# --
# Kernel/System/Email/MultiSMTPHTTP/TURBOSMTP.pm - turbosmtp email send module
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSMTPHTTP::TURBOSMTP;
use strict;
use warnings;
use Kernel::System::EmailParser;
require LWP::UserAgent;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for (qw(ConfigObject LogObject EncodeObject)) {
        die "Got no $_" if ( !$Self->{$_} );
    }
	$Self->{User} = $Param{User} // die "You must specify a User name";
    $Self->{Password} = $Param{Password} // die "You must specify an Password";

	$Self->{UserAgentObj} = LWP::UserAgent->new( protocols_allowed => ['https'] );  
	$Self->{url} = 'https://api.turbo-smtp.com/api/mail/send';

    my $Timeout = $Self->{ConfigObject}->Get('WebUserAgent::Timeout') || 15;
    my $Proxy = $Self->{ConfigObject}->Get('WebUserAgent::Proxy');
    $Self->{UserAgentObj}->timeout($Timeout);
    $Self->{UserAgentObj}->agent($Self->{ConfigObject}->Get('Product') . ' ' . $Self->{ConfigObject}->Get('Version'));
    if ($Proxy){$Self->{UserAgentObj}->proxy( [ 'https' ], $Proxy ); }
	return $Self;
}

sub Send {
    my ($Self, %Param) = @_;
	for (qw(Header Body ToArray)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }
    my $ToString = '';
    for my $To (@{$Param{ToArray}}) {
        $ToString .= $To . ',';
    }

	$Self->{EmailParser} = Kernel::System::EmailParser->new(
		 %{$Self},
		 Email => \( ${$Param{Header}} . "\n\n" . ${$Param{Body}} ),
	);

=begin
	my @no_need_headers = qw(X-Powered-BY X-Mailer Message-ID Organization In-Reply-To References);
	my $my_mime_raw_email = ${$Param{Header}};
	my $search = '';

    for my $regexstart (@no_need_headers) {
        $search = $regexstart.'.*\n';
		$my_mime_raw_email =~ s/$search//gi;
   }
	$my_mime_raw_email = $my_mime_raw_email . "\n\n" . ${$Param{Body}};
=cut

	$Param{Subject} = $Self->{EmailParser}->GetParam( WHAT => 'Subject' );
	$Param{Body}	= $Self->{EmailParser}->GetMessageBody();	
	my $submit_values  =  {    
		'authuser' => $Self->{User},
		'authpass' =>$Self->{Password},
		'from' => $Param{From},
		'to' =>$ToString,
		'subject' => $Param{Subject},
		'content' => $Param{Body},
		#'mime_raw' => $my_mime_raw_email,
	}; 
	my $content = [%$submit_values];

    # get attachments
    my @Attachments = $Self->{EmailParser}->GetAttachments();

	 for my $Attachment (@Attachments) {
		if(lc($Attachment->{Filename}) eq 'file-1' || lc($Attachment->{Filename}) eq 'file-2'){
			if(lc($Attachment->{MimeType}) eq 'text/html'){
				push @$content, html_content => $Attachment->{Content};
			}
		}
	}

	 my $myresponse  = $Self->{UserAgentObj}->post( $Self->{url}, Content => $content );   

     if ($Self->{Debug}){        
		if ($myresponse->is_success) {
				$Self->{LogObject}->Log(
					Priority => 'notice',
					Message  => sprintf "TURBOSMTP Response: %s", $myresponse->decoded_content,
				);
			}else{
				$Self->{LogObject}->Log(
					Priority => 'error',
					Message  => sprintf "TURBOSMTP Response: %s", $myresponse->status_line,
				);
			}
	 }
	return 1;
}
1;