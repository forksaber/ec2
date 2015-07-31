base_profile "centos"

template "app" do
  security_groups "ssh", "default"
end

template "postgres" do
  security_groups "ssh", "default"
  volume device: '/dev/xvdf', size: 150
end
