Create your kafka service account keypair, service account, secret and assign permissions:
```
dcos security org service-accounts keypair kafka-private-key.pem kafka-public-key.pem

dcos security org service-accounts create -p kafka-public-key.pem -d "kafka service account" kafka-principal

dcos security org service-accounts show kafka-principal

dcos security secrets create-sa-secret --strict kafka-private-key.pem kafka-principal kafka/kafka-secret

dcos security org groups add_user superusers kafka-principal
```
