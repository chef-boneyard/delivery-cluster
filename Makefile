.DEFAULT_GOAL = demo

NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

CHEF_ENV ?= test
CHEF_ENV_FILE = environments/$(CHEF_ENV).json

prerequisites:
	@echo "$(WARN_COLOR)\nInstall rubygem dependencies locally\n$(NO_COLOR)"
	bundle install

	@echo "$(WARN_COLOR)\nDownload and vendor the necessary cookbooks locally\n$(NO_COLOR)"
	bundle exec berks vendor cookbooks

	@echo "$(WARN_COLOR)Current chef environment => $(CHEF_ENV_FILE)$(NO_COLOR)"
ifeq ($(wildcard $(CHEF_ENV_FILE)),)
	@echo "$(ERROR_COLOR)You need to configure an Environment under 'environments/'. Check the README.md$(NO_COLOR)"
	@echo "If you just have a different chef environment name run: $(NO_COLOR)"
	@echo "  # export CHEF_ENV=$(WARN_COLOR)my_new_environment$(NO_COLOR)"
endif

cluster: prerequisites
	@echo "$(WARN_COLOR)\nSetup the Chef Delivery cluster\n$(NO_COLOR)"
	bundle exec chef-client -z -o delivery-cluster::setup -E $(CHEF_ENV)

chef_server:
	@echo "$(WARN_COLOR)\nCreate a Chef Server\n$(NO_COLOR)"
	bundle exec chef-client -z -o delivery-cluster::setup_chef_server -E $(CHEF_ENV)

delivery: chef_server
	@echo "$(WARN_COLOR)\nCreate Delivery Server & Build Nodes\n$(NO_COLOR)"
	bundle exec chef-client -z -o delivery-cluster::setup_delivery -E $(CHEF_ENV)

analytics: chef_server delivery
	@echo "$(WARN_COLOR)\nSetup Chef Analytics so we can see what is going on in our cluster\n$(NO_COLOR)"
	bundle exec chef-client -z -o delivery-cluster::setup_analytics -E $(CHEF_ENV)

splunk: analytics
	@echo "$(WARN_COLOR)\nSetup Splunk Server to show some Analytics Integrations\n$(NO_COLOR)"
	bundle exec chef-client -z -o delivery-cluster::setup_splunk -E $(CHEF_ENV)


upgrade: clean_cache update
	$(MAKE) cluster

update:
	@echo "$(WARN_COLOR)\nUpdating cookbooks locally\n$(NO_COLOR)"
	bundle exec berks update

destroy_all:
	bundle exec chef-client -z -o delivery-cluster::destroy_all -E $(CHEF_ENV)

destroy_analytics:
	bundle exec chef-client -z -o delivery-cluster::destroy_analytics -E $(CHEF_ENV)

destory_splunk:
	bundle exec chef-client -z -o delivery-cluster::destroy_splunk -E $(CHEF_ENV)

destory_builders:
	bundle exec chef-client -z -o delivery-cluster::destroy_builders -E $(CHEF_ENV)

destroy_delivery:
	bundle exec chef-client -z -o delivery-cluster::destroy_delivery -E $(CHEF_ENV)

destroy_chef_server:
	bundle exec chef-client -z -o delivery-cluster::destroy_chef_server -E $(CHEF_ENV)

clean: destroy_all

clean_cache:
	rm -rf .chef/local-mode-cache
	rm -rf cookbooks/

delivery_creds:
	cat .chef/delivery-cluster-data/*.creds

list_core_services:
	knife search node 'name:*server* OR name:build-node*' -a ipaddress
	grep chef_server_url .chef/delivery-cluster-data/knife.rb

help:
	@echo "$(OK_COLOR)\nDelivery Cluster Helper$(NO_COLOR)"
	@echo "\tmake $(WARN_COLOR)prerequisites $(NO_COLOR)....... Install all the prerequisites on you system"
	@echo "\tmake $(WARN_COLOR)chef_server $(NO_COLOR)......... Setup a Chef Server"
	@echo "\tmake $(WARN_COLOR)splunk $(NO_COLOR).............. Create a Splunk Server with Analytics Integration"
	@echo "\tmake $(WARN_COLOR)analytics $(NO_COLOR)........... Activate Analytics Server"
	@echo "\tmake $(WARN_COLOR)delivery $(NO_COLOR)............ Create a Delivery Server & Build Nodes"
	@echo "\tmake $(WARN_COLOR)upgrade $(NO_COLOR)............. Upgrade your infrastructure"
	@echo "\tmake $(WARN_COLOR)cluster $(NO_COLOR)............. Setup the Chef Delivery Cluster that includes"
	@echo "\t                           [ Chef Server | Delivery Server | Build Nodes ]"

	@echo "\tmake $(WARN_COLOR)destroy_all $(NO_COLOR)......... Destroy Everything"
	@echo "\tmake $(WARN_COLOR)destory_splunk $(NO_COLOR)...... Destroy Splunk Server"
	@echo "\tmake $(WARN_COLOR)destroy_analytics $(NO_COLOR)... Destroy Analytics Server"
	@echo "\tmake $(WARN_COLOR)destory_builders $(NO_COLOR).... Destroy Build Nodes"
	@echo "\tmake $(WARN_COLOR)destroy_delivery $(NO_COLOR).... Destroy Delivery Server"
	@echo "\tmake $(WARN_COLOR)destroy_chef_server $(NO_COLOR). Destroy Chef Server"
	@echo "\tmake $(WARN_COLOR)clean_cache $(NO_COLOR)......... Clean the cache"

	@echo "$(OK_COLOR)\nCluster Information$(NO_COLOR)"
	@echo "\tmake $(WARN_COLOR)delivery_creds $(NO_COLOR)...... Show Delivery admin credentials"
	@echo "\tmake $(WARN_COLOR)list_core_services $(NO_COLOR).. List all your core services"
	@echo "\nTo switch your environment run:"
	@echo "  # export CHEF_ENV=$(WARN_COLOR)my_new_environment$(NO_COLOR)\n"
