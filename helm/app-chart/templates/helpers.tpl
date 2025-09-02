{{/*
Expand the name of the chart.
*/}}
{{- define "eks-cloudforge-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eks-cloudforge-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eks-cloudforge-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "eks-cloudforge-app.labels" -}}
helm.sh/chart: {{ include "eks-cloudforge-app.chart" . }}
{{ include "eks-cloudforge-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.labels }}
{{- toYaml .Values.global.labels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "eks-cloudforge-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "eks-cloudforge-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "eks-cloudforge-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "eks-cloudforge-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the configmap to use
*/}}
{{- define "eks-cloudforge-app.configMapName" -}}
{{- printf "%s-config" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "eks-cloudforge-app.secretName" -}}
{{- printf "%s-secret" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the service to use
*/}}
{{- define "eks-cloudforge-app.serviceName" -}}
{{- printf "%s-service" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the ingress to use
*/}}
{{- define "eks-cloudforge-app.ingressName" -}}
{{- printf "%s-ingress" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the HPA to use
*/}}
{{- define "eks-cloudforge-app.hpaName" -}}
{{- printf "%s-hpa" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the PDB to use
*/}}
{{- define "eks-cloudforge-app.pdbName" -}}
{{- printf "%s-pdb" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the ServiceMonitor to use
*/}}
{{- define "eks-cloudforge-app.serviceMonitorName" -}}
{{- printf "%s-servicemonitor" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Create the name of the NetworkPolicy to use
*/}}
{{- define "eks-cloudforge-app.networkPolicyName" -}}
{{- printf "%s-networkpolicy" (include "eks-cloudforge-app.fullname" .) }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "eks-cloudforge-app.annotations" -}}
{{- if .Values.global.annotations }}
{{- toYaml .Values.global.annotations }}
{{- end }}
{{- end }}

{{/*
Pod template labels
*/}}
{{- define "eks-cloudforge-app.podLabels" -}}
{{- if .Values.deployment.podLabels }}
{{- toYaml .Values.deployment.podLabels }}
{{- end }}
{{- end }}

{{/*
Pod template annotations
*/}}
{{- define "eks-cloudforge-app.podAnnotations" -}}
{{- if .Values.deployment.podAnnotations }}
{{- toYaml .Values.deployment.podAnnotations }}
{{- end }}
{{- end }}

{{/*
Service template labels
*/}}
{{- define "eks-cloudforge-app.serviceLabels" -}}
{{- if .Values.service.labels }}
{{- toYaml .Values.service.labels }}
{{- end }}
{{- end }}

{{/*
Service template annotations
*/}}
{{- define "eks-cloudforge-app.serviceAnnotations" -}}
{{- if .Values.service.annotations }}
{{- toYaml .Values.service.annotations }}
{{- end }}
{{- end }}

{{/*
Ingress template annotations
*/}}
{{- define "eks-cloudforge-app.ingressAnnotations" -}}
{{- if .Values.ingress.annotations }}
{{- toYaml .Values.ingress.annotations }}
{{- end }}
{{- end }}

{{/*
Resource limits and requests
*/}}
{{- define "eks-cloudforge-app.resources" -}}
{{- if .Values.resources }}
{{- toYaml .Values.resources }}
{{- else }}
requests:
  cpu: 200m
  memory: 256Mi
limits:
  cpu: 800m
  memory: 800Mi
{{- end }}
{{- end }}

{{/*
Environment variables
*/}}
{{- define "eks-cloudforge-app.env" -}}
{{- if .Values.container.env }}
{{- toYaml .Values.container.env }}
{{- else }}
- name: FLASK_ENV
  value: "production"
- name: PORT
  value: "5000"
- name: HOST
  value: "0.0.0.0"
- name: PYTHONUNBUFFERED
  value: "1"
{{- end }}
{{- end }}

{{/*
Liveness probe
*/}}
{{- define "eks-cloudforge-app.livenessProbe" -}}
{{- if .Values.livenessProbe }}
{{- toYaml .Values.livenessProbe }}
{{- else }}
httpGet:
  path: /health
  port: 5000
initialDelaySeconds: 30
periodSeconds: 30
timeoutSeconds: 10
failureThreshold: 3
successThreshold: 1
{{- end }}
{{- end }}

{{/*
Readiness probe
*/}}
{{- define "eks-cloudforge-app.readinessProbe" -}}
{{- if .Values.readinessProbe }}
{{- toYaml .Values.readinessProbe }}
{{- else }}
httpGet:
  path: /health
  port: 5000
initialDelaySeconds: 5
periodSeconds: 10
timeoutSeconds: 5
failureThreshold: 3
successThreshold: 1
{{- end }}
{{- end }}

{{/*
Startup probe
*/}}
{{- define "eks-cloudforge-app.startupProbe" -}}
{{- if .Values.startupProbe }}
{{- toYaml .Values.startupProbe }}
{{- else }}
httpGet:
  path: /health
  port: 5000
initialDelaySeconds: 10
periodSeconds: 10
timeoutSeconds: 5
failureThreshold: 30
successThreshold: 1
{{- end }}
{{- end }}

{{/*
Security context
*/}}
{{- define "eks-cloudforge-app.securityContext" -}}
{{- if .Values.security.securityContext }}
{{- toYaml .Values.security.securityContext }}
{{- else }}
runAsUser: 1000
runAsGroup: 1000
fsGroup: 1000
capabilities:
  drop:
    - ALL
{{- end }}
{{- end }}

{{/*
Container security context
*/}}
{{- define "eks-cloudforge-app.containerSecurityContext" -}}
{{- if .Values.security.containerSecurityContext }}
{{- toYaml .Values.security.containerSecurityContext }}
{{- else }}
runAsNonRoot: true
allowPrivilegeEscalation: false
readOnlyRootFilesystem: false
capabilities:
  drop:
    - ALL
{{- end }}
{{- end }}

{{/*
Image pull policy
*/}}
{{- define "eks-cloudforge-app.imagePullPolicy" -}}
{{- if .Values.image.pullPolicy }}
{{- .Values.image.pullPolicy }}
{{- else }}
IfNotPresent
{{- end }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "eks-cloudforge-app.imagePullSecrets" -}}
{{- if .Values.image.pullSecrets }}
{{- toYaml .Values.image.pullSecrets }}
{{- end }}
{{- end }}

{{/*
Update strategy
*/}}
{{- define "eks-cloudforge-app.updateStrategy" -}}
{{- if .Values.deployment.strategy }}
{{- toYaml .Values.deployment.strategy }}
{{- else }}
type: RollingUpdate
rollingUpdate:
  maxSurge: 1
  maxUnavailable: 0
{{- end }}
{{- end }}

{{/*
HPA behavior
*/}}
{{- define "eks-cloudforge-app.hpaBehavior" -}}
{{- if .Values.autoscaling.behavior }}
{{- toYaml .Values.autoscaling.behavior }}
{{- else }}
scaleDown:
  stabilizationWindowSeconds: 300
  policies:
    - type: Percent
      value: 10
      periodSeconds: 60
scaleUp:
  stabilizationWindowSeconds: 60
  policies:
    - type: Percent
      value: 100
      periodSeconds: 15
{{- end }}
{{- end }}

{{/*
Cost optimization labels
*/}}
{{- define "eks-cloudforge-app.costLabels" -}}
cost-optimized: "true"
instance-type: "t3-micro"
estimated-cost-per-month: "8.47"
auto-scaling: "true"
resource-limits: "true"
{{- end }}

{{/*
Monitoring labels
*/}}
{{- define "eks-cloudforge-app.monitoringLabels" -}}
prometheus.io/scrape: "true"
prometheus.io/port: "5000"
prometheus.io/path: "/prometheus"
{{- end }}

{{/*
TLS hosts
*/}}
{{- define "eks-cloudforge-app.tlsHosts" -}}
{{- range .Values.ingress.hosts }}
{{- range .paths }}
{{- printf "%s" .host }}
{{- end }}
{{- end }}
{{- end }}

{{/*
TLS secret names
*/}}
{{- define "eks-cloudforge-app.tlsSecretNames" -}}
{{- range .Values.ingress.tls }}
{{- printf "%s" .secretName }}
{{- end }}
{{- end }}

{{/*
Ingress hosts
*/}}
{{- define "eks-cloudforge-app.ingressHosts" -}}
{{- range .Values.ingress.hosts }}
{{- range .paths }}
{{- printf "%s" .host }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Ingress paths
*/}}
{{- define "eks-cloudforge-app.ingressPaths" -}}
{{- range .Values.ingress.hosts }}
{{- range .paths }}
{{- printf "%s" .path }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Network policy ingress rules
*/}}
{{- define "eks-cloudforge-app.networkPolicyIngress" -}}
{{- if .Values.networkPolicy.ingress }}
{{- toYaml .Values.networkPolicy.ingress }}
{{- else }}
- from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  ports:
    - protocol: TCP
      port: 5000
{{- end }}
{{- end }}

{{/*
ConfigMap data
*/}}
{{- define "eks-cloudforge-app.configMapData" -}}
{{- if .Values.configMap.data }}
{{- toYaml .Values.configMap.data }}
{{- end }}
{{- end }}

{{/*
Secret data
*/}}
{{- define "eks-cloudforge-app.secretData" -}}
{{- if .Values.secrets.data }}
{{- toYaml .Values.secrets.data }}
{{- end }}
{{- end }}

{{/*
Service account annotations
*/}}
{{- define "eks-cloudforge-app.serviceAccountAnnotations" -}}
{{- if .Values.serviceAccount.annotations }}
{{- toYaml .Values.serviceAccount.annotations }}
{{- end }}
{{- end }}

{{/*
Service account labels
*/}}
{{- define "eks-cloudforge-app.serviceAccountLabels" -}}
{{- if .Values.serviceAccount.labels }}
{{- toYaml .Values.serviceAccount.labels }}
{{- end }}
{{- end }}

{{/*
Pod disruption budget
*/}}
{{- define "eks-cloudforge-app.podDisruptionBudget" -}}
{{- if .Values.podDisruptionBudget.minAvailable }}
minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
{{- else if .Values.podDisruptionBudget.maxUnavailable }}
maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
{{- else }}
minAvailable: 1
{{- end }}
{{- end }}

{{/*
ServiceMonitor spec
*/}}
{{- define "eks-cloudforge-app.serviceMonitorSpec" -}}
{{- if .Values.monitoring.serviceMonitor }}
{{- toYaml .Values.monitoring.serviceMonitor }}
{{- else }}
interval: 30s
path: /metrics
port: 5000
{{- end }}
{{- end }} 