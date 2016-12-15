vpc_id "vpc-myvpcid"

security_group "https.webserver" do
  description "https webserver"
  tcp 80, cidr_ip: "0.0.0.0/0"
  tcp 443, cidr_ip: "0.0.0.0/0"
end

security_group "internal.consul" do
  description "internal consul"
  tcp 8300, cidr_ip: "172.31.0.0/16"
  tcp 8400, cidr_ip: "172.31.0.0/16"
  tcp 8500, cidr_ip: "172.31.0.0/16"
  tcp 8600, cidr_ip: "172.31.0.0/16"
  tcp 8301, cidr_ip: "172.31.0.0/16"
  tcp 8302, cidr_ip: "172.31.0.0/16"
end
