```bash
$ kubectl create sa demo-sa
$ export TOKEN=`kubectl create token demo-sa`
$ jq -R 'split(".") | select(length > 0) | .[0], .[1] | @base64d | fromjson' <<< $TOKEN

{
  "alg": "RS256",
  "kid": "26VouO-s2HvImLL-ekQMmELkzqJ9-il_Kjz_jCQw8Mw"
}
```

https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-request-v1/