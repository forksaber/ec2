base_profile "centos"

template "app" do
  security_groups "ssh", "default"
end
