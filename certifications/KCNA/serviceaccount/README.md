```bash
$ kubectl create sa demo-sa
$ export TOKEN=`kubectl create token demo-sa`
$ jq -R 'split(".") | select(length > 0) | .[0], .[1] | @base64d | fromjson' <<< $TOKEN

{
  "alg": "RS256",
  "kid": "26VouO-s2HvImLL-ekQMmELkzqJ9-il_Kjz_jCQw8Mw"
}
{
  "aud": [
    "https://k8s-projects-2cbab576.hcp.westeurope.azmk8s.io",
    "\"k8s-projects-2cbab576.hcp.westeurope.azmk8s.io\""
  ],
  "exp": 1739377138, -- expires within an hour by default 
  "iat": 1739373538,
  "iss": "https://k8s-projects-2cbab576.hcp.westeurope.azmk8s.io",
  "jti": "2679e301-8667-46c0-9ad1-bf08b59d5ebc",
  "kubernetes.io": {
    "namespace": "migrosbank-1eb-youthful-jang",
    "serviceaccount": {
      "name": "demo-sa",
      "uid": "c24cb93a-2d2f-436f-ae88-10f347b0266d"
    }
  },
  "nbf": 1739373538,
  "sub": "system:serviceaccount:migrosbank-1eb-youthful-jang:demo-sa"
}
```

https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-request-v1/