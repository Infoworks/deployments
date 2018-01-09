dns=$(curl -s http://169.254.169.254/latest/meta-data/hostname | cut -d '.' -f2-4)
instance_no=$(curl -s http://169.254.169.254/latest/meta-data/ami-launch-index)
ipv4=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
hostname=aws-$instance_no
hostnamectl set-hostname $hostname.$dns