#!/bin/bash

checkroot() {
if [[ "$(id -u)" -ne 0 ]]; then
     printf "\e[1;77m Please, run this program as root!\n \e[0m"
     exit 1
fi
}
dependencies() {

if [[ -e "/etc/mail/sendmail.mc" ]]; then
read -p "Config Gmail account? [y/n]" gmail;
  if [[ $gmail == "y" ]]; then
    functiongmail
  fi
else
printf "\e[1;32m Installing sendmail, please wait...\n \e[0m";
apt-get update 1> /dev/null &
wait $!
apt-get install -y sendmail 1> /dev/null &
wait $!
functiongmail
fi
}
functiongmail() {
printf "\e[1;77m";
read -p "Insert your gmail address: " address
read -s -p "Insert your password (to create hash): " password
printf "\n";
read -p "Insert email username: " username
printf "\e[0m";
if [[ -e "/etc/mail/authinfo" ]]; then
echo ""
else
mkdir -m 700 /etc/mail/authinfo
fi
touch /etc/mail/authinfo/gmail-auth
/bin/bash -c "echo 'AuthInfo: \"U:$username\" \"I:$address\" \"P:$password\"' > /etc/mail/authinfo/gmail-auth"
/bin/bash -c "makemap hash /etc/mail/authinfo/gmail-auth < /etc/mail/authinfo/gmail-auth"
rm -rf /etc/mail/authinfo/gmail-auth
configmail
}
configmail() {
smtp=$(grep 'smtp.gmail.com' /etc/mail/sendmail.mc)
if [[ $smtp == "" ]]; then
printf "\e[1;32m Configuring /etc/mail/sendmail.mc\n \e[0m";
sed -i "/MAILER_DEFINITIONS/ i define(\`SMART_HOST',\`[smtp.gmail.com]')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ i define(\`RELAY_MAILER_ARGS', \`TCP \$h 587')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ i define(\`ESMTP_MAILER_ARGS', \`TCP \$h 587')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ i define(\`confAUTH_OPTIONS', \`A p')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ i TRUST_AUTH_MECH(\`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ i define(\`confAUTH_MECHANISMS', \`EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ i FEATURE(\`authinfo',\`hash -o /etc/mail/authinfo/gmail-auth.db')dnl" /etc/mail/sendmail.mc
make -C /etc/mail 1> /dev/null &
wait $!
/etc/init.d/sendmail reload
fi
}
checkroot
dependencies
printf "\e[0;32m Sendmail + Gmail configured \n \e[0m";
printf "\e[0;32m To send email start Sendmail (service sendmail start) and use: \n \e[0m";
printf '\e[1;77m echo "message" | mail -s "subject" send-to@domain.com \n';
printf '\e[1;31m Warning: to send emails  with google you need to set up "Less secure apps" \n \e[0m';
printf "\e[1;31m Visit: https://myaccount.google.com/lesssecureapps\n \e[0m"
