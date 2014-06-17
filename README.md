#otrs-multi-smtp-http
====================

Use multiple SMTP servers and RESTful HTTP API based SMTP servers in your OTRS instance.

Main reason of this module instead of using multiple SMTP servers you can use other RESTful HTTP API based SMTP servers.

OTRS Multi SMTPHTTP module's base files copied from https://github.com/reneeb/otrs-MultiSMTP.
Thanks to Renee

Currently otrs-multi-smtp-http allows to use;
- [MAILGUN](http://mailgun.com)
- [SENDGRID](http://sendgrid.com)
- [TURBOSMTP](http://www.serversmtp.com/clients/aff.php?aff=866&lang=en)
- GENERALHTTP

####GENERALHTTP
If you select "General Http Post" option, System will send a HTTP/S Post with following parameters

- auth_user
- auth_pass
- from
- to (comma seperated)
- subject
- text (text email)
- html (html alternative of the email)
- attachment
 

Example: http://www.yoursite.com/emailfromotrs.php?to=&from=&subject=&text=&html=&attachment=&


And also ofcourse you can use normal SMTP,SMTPS,SMTPTLS as well.. 


