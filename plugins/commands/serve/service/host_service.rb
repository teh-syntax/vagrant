require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class HostService < Hashicorp::Vagrant::Sdk::HostService::Service

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").local_manager.host_capabilities
          default_args = {
            Vagrant::Environment => SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Project",
              name: "",
            ),
          }
          initialize_capability_platform!(caps, default_args)
        end

        def detect_spec(*_)
          SDK::FuncSpec.new(
            name: "detect_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.StateBag",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Platform.DetectResp",
              name: "",
            ]
          )
        end

        def detect(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            statebag = mapper.funcspec_map(req, expect: Client::StateBag)
            plugin = Vagrant.plugin("2").local_manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            host = plugin.new
            begin
              detected = host.detect?(statebag)
            rescue => err
              logger.debug("error encountered detecting host: #{err.class} - #{err}")
              detected = false
            end
            logger.debug("detected #{detected} for host #{plugin_name}")
            SDK::Platform::DetectResp.new(
              detected: detected,
            )
          end
        end

        def parent_spec(*_)
          SDK::FuncSpec.new(
            name: "parent_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Host.ParentResp",
              name: "",
            ]
          )
        end

        def parent(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            host_hash = Vagrant.plugin("2").local_manager.hosts[plugin_name.to_s.to_sym].to_a
            plugin = host_hash.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            SDK::Platform::ParentResp.new(
              parent: host_hash.last
            )
          end
        end
      end
    end
  end
end
