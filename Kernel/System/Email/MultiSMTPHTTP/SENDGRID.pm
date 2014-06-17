# --
# Kernel/System/Email/MultiSMTPHTTP/SENDGRID.pm - sendgrid email send module
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSMTPHTTP::SENDGRID;
use strict;
use warnings;
use Kernel::System::EmailParser;
use Encode;
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
	$Self->{User} = $Param{User} // die "You must specify an Username";
    $Self->{Password} = $Param{Password} // die "You must specify an Password";
	$Self->{UserAgentObj} = LWP::UserAgent->new( protocols_allowed => ['https'] );  
	$Self->{url} = 'https://api.sendgrid.com/api/mail.send.json';

    my $Timeout = $Self->{ConfigObject}->Get('WebUserAgent::Timeout') || 15;
    my $Proxy = $Self->{ConfigObject}->Get('WebUserAgent::Proxy');
    $Self->{UserAgentObj}->timeout($Timeout);
    $Self->{UserAgentObj}->agent($Self->{ConfigObject}->Get('Product') . ' ' . $Self->{ConfigObject}->Get('Version'));
    if ($Proxy){$Self->{UserAgentObj}->proxy( [ 'https' ], $Proxy ); }

	my $headers = HTTP::Headers->new(
		'Accept' => 'application/json',
		'content-type' => 'application/json',
	);
	$Self->{UserAgentObj}->default_headers($headers);
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
	$Self->{EmailParser} = Kernel::System::EmailParser->new(
		 %{$Self},
		 Email => \( ${$Param{Header}} . "\n\n" . ${$Param{Body}} ),
	);
	$Param{Subject} = $Self->{EmailParser}->GetParam( WHAT => 'Subject' );
	$Param{Body}	= $Self->{EmailParser}->GetMessageBody();	

    # get attachments
    my @Attachments = $Self->{EmailParser}->GetAttachments();
	my %content = (
		'api_user' => $Self->{User},
		'api_key' => $Self->{Password},
		'subject' => $Param{Subject},
		'from' => $Param{From},
		'text' => $Param{Body},
	);

    for my $To (@{$Param{ToArray}}) {
		$content{'to[]'} = encode_utf8($To);
	}

	 for my $Attachment (@Attachments) {
		if(lc($Attachment->{Filename}) eq 'file-1' || lc($Attachment->{Filename}) eq 'file-2'){
			if(lc($Attachment->{MimeType}) eq 'text/html'){
				$content{'html'} = $Attachment->{Content};
			}
		}else{
			if(exists $content{'files['.$Attachment->{Filename}.']'}){
				$content{'files['.time() . int(rand(1000)).'_'.$Attachment->{Filename}.']'} = $Attachment->{Content};
			}else{
				$content{'files['.$Attachment->{Filename}.']'} = $Attachment->{Content};
			}
		}
	}


	my $secondcontent = [%content];
	my $myresponse  = $Self->{UserAgentObj}->post( $Self->{url} ,Content_Type => 'form-data',Content => $secondcontent );   

     if ($Self->{Debug}){        
		if ($myresponse->is_success) {
				$Self->{LogObject}->Log(
					Priority => 'notice',
					Message  => sprintf "SENDGRID Response: %s", $myresponse->decoded_content,
				);
			}else{
				$Self->{LogObject}->Log(
					Priority => 'error',
					Message  => sprintf "SENDGRID Response: %s", $myresponse->status_line,
				);
			}
	 }
	return 1;
}

1;
