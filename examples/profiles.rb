import "templates.rb"

base_subnet "dev"
availability_zones "lol5", "lol3"

use :app, :postgres

mprofile :postgres_small, template: "postgres"  do
  volume device: "/dev/xvdf", size: 100
end
