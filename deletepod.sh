if [ $# -eq 0 ]
  then
    echo 'deletes all pods that match a certain pattern ...'
    echo 'Usage:'
    echo 'sh deletepod.sh ident   ... will delete pods whose name contain *ident*'
    echo 'sh deletepod.sh "edge\|ident" ... will delete pods of 2 matching patterns: edge or ident'
  else
    kubectl delete $(kubectl get pod -o=name |grep $1)
fi
