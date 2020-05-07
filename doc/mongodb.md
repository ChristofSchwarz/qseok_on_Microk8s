 # Mongo DB
 
## Mongo Shell Commands
Sometimes it is useful to look into the data tables in MongoDB, for example, which tenants have been set up? You may use the Mongo 
Shell (https://docs.mongodb.com/manual/mongo/) by bashing into the mongodb pod. You have two ways:

### Direct Execution of one command

To use `kubectl exec` you need to know the pod name. The pod name starts with "mongo-mongodb" followed by some hex characters at 
the end, like mongo-mongodb-66cb45c6cb-99l5f ... so I am using another kubectl command to retrieve the current pod name using a 
selector based on the non-changing app name)

For example: **list all collections (“tables”)** <br/>
`kubectl exec $(kubectl get pods --selector app=mongodb -o=name) -- bash -c 'mongo qsefe -u qlik -p Qlik1234 --eval "db.getCollectionNames()"'`
Note, that the database name here is qsefe, the user is qlik, the password is Qlik1234 (check in [settings.sh](../settings.sh) what your settings are)

For example: **list all entries from “tenants” collection** <br/>
`kubectl exec $(kubectl get pods --selector app=mongodb -o=name) -- bash -c 'mongo qsefe -u qlik -p Qlik1234 --eval "db.tenants.find()"'`

For example: **count all users**
`kubectl exec $(kubectl get pods --selector app=mongodb -o=name) -- bash -c 'mongo qsefe -u qlik -p Qlik1234 --eval "db.users.count()"'`

Interactive Mode
kubectl exec -i $(kubectl get pods --selector app=mongodb -o=name) bash

There is no prompt. You are in the shell. Try “ls”. To enter mongo shell type:
mongo qsefe -u qlik -p Qlik1234
show collections
db.tenants.count()
db.tenants.find()
exit

to get out of the pod bash, hit Ctrl+C or type “exit” again.
