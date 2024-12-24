{{ define "webapp"}}
- name: webapp
  image: {{ .Values.image_repo }}/k8s-fleetman-helm-demo:v1.0.0{{if .Values.environment }}-dev{{end}}
{{ end}}

{{ define "webapp-replicas"}}
replicas: {{ .Values.numberofreplicas }}
{{end}}
