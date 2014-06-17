# --
# Kernel/System/Email/MultiSMTPHTTP/GENERALHTTP.pm - general http post email send module
# Copyright (C) 2014 4ys.net, http://www.4ys.net
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSMTPHTTP::GENERALHTTP;
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
    my $Domain = $Param{Host} // die "You need to specify a URL endpoint (IE: http://mysite.com/sendmeailfromotrs.php)";
    $Self->{User}     = $Param{User};
    $Self->{Password} = $Param{Password};

	
	$Self->{UserAgentObj} = LWP::UserAgent->new( protocols_allowed => ['https', 'http'] );  
	$Self->{url} = $Domain;


    my $Timeout = $Self->{ConfigObject}->Get('WebUserAgent::Timeout') || 15;
    my $Proxy = $Self->{ConfigObject}->Get('WebUserAgent::Proxy');
    $Self->{UserAgentObj}->timeout($Timeout);
    $Self->{UserAgentObj}->agent($Self->{ConfigObject}->Get('Product') . ' ' . $Self->{ConfigObject}->Get('Version'));
    if ($Proxy){$Self->{UserAgentObj}->proxy( [ 'https','http' ], $Proxy ); }

	my $headers = HTTP::Headers->new(
		'content-type' => 'multipart/form-data',
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
    my $ToString = '';
    for my $To (@{$Param{ToArray}}) {
        $ToString .= $To . ',';
    }

	$Self->{EmailParser} = Kernel::System::EmailParser->new(
		 %{$Self},
		 Email => \( ${$Param{Header}} . "\n\n" . ${$Param{Body}} ),
	);
	$Param{Subject} = $Self->{EmailParser}->GetParam( WHAT => 'Subject' );
	$Param{Body}	= $Self->{EmailParser}->GetMessageBody();	

    # get attachments
    my @Attachments = $Self->{EmailParser}->GetAttachments();
	my $submit_values  =  {
		'auth_user' => $Self->{User},
		'auth_pass' => $Self->{Password},
		'from' => $Param{From},
		'to' =>$ToString,
		'subject' => $Param{Subject},
		'text' => $Param{Body},
	}; 

	my $content = [%$submit_values];
	for my $Attachment (@Attachments) {
			if(lc($Attachment->{Filename}) eq 'file-1' || lc($Attachment->{Filename}) eq 'file-2'){
				if(lc($Attachment->{MimeType}) eq 'text/html'){
					push @$content, html => $Attachment->{Content};
				}
			}else{
				push (@$content, 'attachment[]' => [undef, $Attachment->{Filename},'Content_Type'=>$Attachment->{ContentType},'Content'=>$Attachment->{Content}]);
				
			}
	}
	 my $myresponse  = $Self->{UserAgentObj}->post($Self->{url},Content_Type => 'form-data', Content => $content ); 
	 if ($Self->{Debug}){        
		if ($myresponse->is_success) {
				$Self->{LogObject}->Log(
					Priority => 'notice',
					Message  => sprintf "GENERALHTTP Response: %s", $myresponse->decoded_content,
				);
			}else{
				$Self->{LogObject}->Log(
					Priority => 'error',
					Message  => sprintf "GENERALHTTP Response: %s", $myresponse->status_line,
				);
			}
	 }
	return 1;
}

1;
