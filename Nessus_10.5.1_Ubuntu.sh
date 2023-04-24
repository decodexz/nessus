#!/bin/bash
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi
echo //==============================================================
echo   Nessus 10.5.1 DOWNLOAD, INSTALL By TinyActive
echo //==============================================================
echo " o making sure we have prerequisites.."
sudo apt-get update &>/dev/null
sudo apt-get install curl dpkg expect -y &>/dev/null
echo " o stopping old nessusd in case there is one!"
/bin/systemctl stop nessusd.service &>/dev/null
echo " o downloading Nessus.."
curl -A Mozilla --request GET \
  --url 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.5.1-ubuntu1404_amd64.deb' \
  --output 'Nessus-10.5.1-ubuntu1404_amd64.deb' &>/dev/null
{ if [ ! -f Nessus-10.5.1-ubuntu1404_amd64.deb ]; then
  echo " o nessus download failed :/ exiting. get copy of it from t.me/vouuvhb"
  exit 0
fi }
echo " o installing Nessus.."
chmod +x Nessus-10.5.1-ubuntu1404_amd64.deb &>/dev/null
dpkg -i Nessus-10.5.1-ubuntu1404_amd64.deb &>/dev/null
# look I tried to just make changes and run but it doesnt work. if you can optimize
# what im doing here, let me know.  but this was it for me, it had to be run once :/
echo " o starting service once FIRST TIME INITIALIZATION (we have to do this)"
/bin/systemctl start nessusd.service &>/dev/null
echo " o let's allow Nessus time to initalize - we'll give it like 20 seconds..."
sleep 20
echo " o stopping the nessus service.."
/bin/systemctl stop nessusd.service &>/dev/null
echo " o changing nessus settings to Zen preferences (freedom fighter mode)"
echo "   listen port: 11127"
/opt/nessus/sbin/nessuscli fix --set xmlrpc_listen_port=11127 &>/dev/null
echo "   theme:       dark"
/opt/nessus/sbin/nessuscli fix --set ui_theme=dark &>/dev/null
echo "   safe checks: off"
/opt/nessus/sbin/nessuscli fix --set safe_checks=false &>/dev/null
echo "   logs:        performance"
/opt/nessus/sbin/nessuscli fix --set backend_log_level=performance &>/dev/null
echo "   updates:     off"
/opt/nessus/sbin/nessuscli fix --set auto_update=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set auto_update_ui=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set disable_core_updates=true &>/dev/null
echo "   telemetry:   off"
/opt/nessus/sbin/nessuscli fix --set report_crashes=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set send_telemetry=false &>/dev/null
echo " o adding a user you can change this later (u:admin,p:TinyActive)"
cat > expect.tmp<<'EOF'
spawn /opt/nessus/sbin/nessuscli adduser admin
expect "Login password:"
send "TinyActive\r"
expect "Login password (again):"
send "TinyActive\r"
expect "*(can upload plugins, etc.)? (y/n)*"
send "y\r"
expect "*(the user can have an empty rules set)"
send "\r"
expect "Is that ok*"
send "y\r"
expect eof
EOF
expect -f expect.tmp &>/dev/null
rm -rf expect.tmp &>/dev/null
echo " o downloading new plugins.."
curl -A Mozilla -o all-2.0.tar.gz \
  --url 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz&u=4e2abfd83a40e2012ebf6537ade2f207&p=29a34e24fc12d3f5fdfbb1ae948972c6' &>/dev/null
{ if [ ! -f all-2.0.tar.gz ]; then
  echo " o plugins all-2.0.tar.gz download failed :/ exiting. get copy of it from t.me/vouuvhb"
  exit 0
fi }
echo " o installing plugins.."
chmod +x all-2.0.tar.gz
/opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
echo " o fetching version number.."
# i have seen this not be correct for the download.  hrm. but, it works for me.
vernum=$(curl https://plugins.nessus.org/v2/plugins.php 2> /dev/null)
echo " o building plugin feed..."
cat > /opt/nessus/var/nessus/plugin_feed_info.inc <<EOF
PLUGIN_SET = "${vernum}";
PLUGIN_FEED = "ProfessionalFeed (Direct)";
PLUGIN_FEED_TRANSPORT = "Tenable Network Security Lightning";
EOF
echo " o protecting files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
cp /opt/nessus/var/nessus/plugin_feed_info.inc /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
echo " o let's set everything immutable..."
chattr +i /opt/nessus/var/nessus/plugin_feed_info.inc &>/dev/null
chattr +i -R /opt/nessus/lib/nessus/plugins &>/dev/null
echo " o but unsetting key files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
chattr -i /opt/nessus/lib/nessus/plugins  &>/dev/null
echo " o starting service.."
rm -r all-2.0.tar.gz &>/dev/null
/bin/systemctl start nessusd.service &>/dev/null
echo " o Let's sleep for another 20 seconds to let the server have time to start!"
sleep 20
echo " o Monitoring Nessus progress. Following line updates every 10 seconds until 100%"
zen=0
while [ $zen -ne 100 ]
do
 statline=$(curl -sL -k https://localhost:11127/server/status|awk -F"," -v k="engine_status" '{ gsub(/{|}/,""); for(i=1;i<=NF;i++) { if ( $i ~ k ){printf $i} } }')
 if [[ $statline != *"engine_status"* ]]; then echo -ne "\n Problem: Nessus server unreachable? Trying again..\n"; fi
 echo -ne "\r $statline"
 if [[ $statline == *"100"* ]]; then zen=100; else sleep 10; fi
done
echo -ne '\n  o Done!\n'
echo
echo "        Access your Nessus:  https://localhost:11127/ (or your VPS IP)"
echo "                             username: admin"
echo "                             password: TinyActive"
echo "                             you can change this any time"
echo
read -p "Press enter to continue"
