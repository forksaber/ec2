id "vpc-asdf"

subnet "name" do
  az "ap-southeast-1a"
  cidr "172.31.1.0/24"
end

def msubnet(number, name)
  subnet "#{name}-a" do
    az "ap-southeast-1a"
    cidr "172.31.#{number}.0/25"
  end

  subnet "#{name}-b" do
    az "ap-southeast-1b"
    cidr "172.31.#{number}.128/25"
  end
end

msubnet 10, "shared"
