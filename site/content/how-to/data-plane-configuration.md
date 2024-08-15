---
title: "Data plane configuration"
weight: 400
toc: true
docs: "DOCS-000"
---

Learn how to dynamically update the NGINX Gateway Fabric global data plane configuration.

## Overview

NGINX Gateway Fabric can dynamically update the global data plane configuration without restarting. The data plane configuration is a global configuration for NGINX that has options that are not available using the standard Gateway API resources. This includes such things as setting an OpenTelemetry collector config, disabling http2, or changing the IP family.

The data plane configuration is stored in the NginxProxy custom resource, which is a cluster-scoped resource that is attached to the `nginx` GatewayClass.

By default, the NginxProxy resource is not created when installing NGINX Gateway Fabric. However, you can set configuration options in the `nginx.config` Helm values, and the resource will be created and attached when NGINX Gateway Fabric is installed using Helm. You can also [manually create and attach](#manually-creating-the-configuration) the resource after NGINX Gateway Fabric is already installed.

When installed using the Helm chart, the NginxProxy resource is named `<release-name>-proxy-config`.

**For a full list of configuration options that can be set, see the `NginxProxy spec` in the [API reference]({{< relref "reference/api.md" >}}).**

{{<note>}}Some global configuration also requires an [associated policy]({{< relref "overview/custom-policies.md" >}}) to fully enable a feature (such as [tracing]({{< relref "/how-to/monitoring/tracing.md" >}}), for example).{{</note>}}

## Viewing and Updating the Configuration

If the `NginxProxy` resource already exists, you can view and edit it.

{{< note >}} For the following examples, the name `ngf-proxy-config` should be updated to the name of the resource created for your installation.{{< /note >}}

To view the current configuration:

```shell
kubectl describe nginxproxies ngf-proxy-config
```

To update the configuration:

```shell
kubectl edit nginxproxies ngf-proxy-config
```

This will open the configuration in your default editor. You can then update and save the configuration, which is applied automatically to the data plane.

To view the status of the configuration, check the GatewayClass that it is attached to:

```shell
kubectl describe gatewayclasses nginx
```

```text
...
Status:
  Conditions:
     ...
    Message:               parametersRef resource is resolved
    Observed Generation:   1
    Reason:                ResolvedRefs
    Status:                True
    Type:                  ResolvedRefs
```

If everything is valid, the `ResolvedRefs` condition should be `True`. Otherwise, you will see an `InvalidParameters` condition in the status.

## Manually Creating the Configuration

If the `NginxProxy` resource doesn't exist, you can create it and attach it to the GatewayClass.

The following command creates a basic `NginxProxy` configuration that sets the IP family to `ipv4` instead of the default value of `dual`:

```yaml
kubectl apply -f - <<EOF
apiVersion: gateway.nginx.org/v1alpha1
kind: NginxProxy
metadata:
  name: ngf-proxy-config
spec:
  ipFamily: ipv4
EOF
```

Now we need to attach it to the GatewayClass:

```shell
kubectl edit gatewayclass nginx
```

This will open your default editor, allowing you to add the following to the `spec`:

```yaml
parametersRef:
    group: gateway.nginx.org
    kind: NginxProxy
    name: ngf-proxy-config
```

After updating, you can check the status of the GatewayClass to see if the configuration is valid:

```shell
kubectl describe gatewayclasses nginx
```

```text
...
Status:
  Conditions:
     ...
    Message:               parametersRef resource is resolved
    Observed Generation:   1
    Reason:                ResolvedRefs
    Status:                True
    Type:                  ResolvedRefs
```

If everything is valid, the `ResolvedRefs` condition should be `True`. Otherwise, you will see an `InvalidParameters` condition in the status.