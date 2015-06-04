# Delivery Upgrade
The following steps describes the process to upgrade delivery using `delivery-cluster`

1. Login to the provisioning node that manage the delivery infrastructure.
2. Swtich to the `delivery-cluster` repository.
  ```
  # cd ~/repo/delivery-cluster
  ```

3. Pull the latest code from github.
  ```
  # git fetch origin master
  # git pull origin master
  ```

4. Set your delivery environment.
  ```
  # export CHEF_ENV=my_environment_name
  ```

5. Upgrade delivery.
  ```
  # chef exec rake maintenance:upgrade
  ```

6. Validate the version of delivery by accessing this URL:
  ```
  httpd://my-delivery.com/status/version
  ```

**If the version of Delivery is pinned in the environment file, this upgrade will have no effect.**

An example of a pinned environment for version `0.3.67` of delivery
```json
  "delivery": {
    "version": "0.3.67",
  }
```

For upgrades set the version to `latest` as follow
```json
  "delivery": {
    "version": "latest",
  }
```

*We highly recommend customers build two different environment files and clusters, one with pinned version of delivery and one with `latest`, in order to test upgrades.*

```text
Copyright:: 2015 Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
