#!/usr/bin/bash
##############################################################################################
#
#   Set Nextcloud Mime Type Filter
#  
#   ./provison_mimetype_filter -u user -p password -c config_file nextcloud_url
#
#   Conrad Beckert kontakt@miradata.de
#
##############################################################################################


while getopts ":u:p:c:n" opt
do
    case $opt in
        u) nc_user="$OPTARG";;
        p) nc_passwd="$OPTARG";;
        c) mime_type_config="$OPTARG";;
        h|?) echo "usage: ./provison_mimetype_filter -u user -p password -c config_file nextcloud_url"
    esac
done
shift "$(($OPTIND -1))"
nc_url=$1
[[ -z $nc_user ]] && echo "Error: provide user -u" && exit 2
[[ -z $nc_passwd ]] && echo "Password for $nc_user:" && read -s nc_passwd
[[ -z $mime_type_config ]] && mime_type_config=$(basename $0|sed 's/sh$/conf/')
[[ ! -r $mime_type_config ]] && echo "Config file $mime_type_config missing" && exit 2
[[ -z $nc_url ]] && echo "Error: provide Nextcloud url" && exit 2
nc_cookie='NCSRV=server1'

mime_type_list=''
for mime_type_item in $(cat ${mime_type_config})
do
   mime_type_list="${mime_type_list} ,
   {
      \"class\": \"OCA\\\\WorkflowEngine\\\\Check\\\\FileMimeType\",
      \"operator\": \"!is\",
      \"value\": \"${mime_type_item}\",
      \"invalid\": false
   }"
done

mime_type_params=" 
{
  \"id\": -$(date +%s),
  \"class\": \"OCA\\\\FilesAccessControl\\\\Operation\",
  \"entity\": \"OCA\\\\WorkflowEngine\\\\Entity\\\\File\",
  \"events\": [],
  \"name\": \"\",
  \"checks\": [
    {
      \"class\": \"OCA\\\\WorkflowEngine\\\\Check\\\\FileMimeType\",
      \"operator\": \"!is\",
      \"value\": \"httpd/unix-directory\",
      \"invalid\": false
    },
    {
      \"class\": \"OCA\\\\WorkflowEngine\\\\Check\\\\FileSize\",
      \"operator\": \"greater\",
      \"value\": \"0 B\",
      \"invalid\": false
    }
    ${mime_type_list}
      ],
  \"operation\": \"deny\",
  \"valid\": true
}
"
curl="curl -u $nc_user:$nc_passwd --header 'Content-Type: application/json; charset=utf-8' --header 'OCS-APIRequest: true' --request POST --cookie '$nc_cookie' --data '$mime_type_params' ${nc_url}/ocs/v2.php/apps/workflowengine/api/v1/workflows/global?format=json"


eval $curl

